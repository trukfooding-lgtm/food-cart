import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.config.dart';
import 'location_selection_screen.dart';

class MerchantSellingMap extends StatefulWidget {
  final dynamic merchantId;
  const MerchantSellingMap({super.key, required this.merchantId});
  @override
  State<MerchantSellingMap> createState() => _MerchantSellingMapState();
}

class _MerchantSellingMapState extends State<MerchantSellingMap> {
  bool _loading = true;
  bool _saving = false;
  CustomerLocation? _location;
  String? _error;
  Map<String, dynamic>? _savedSession;
  Map<String, dynamic>? _regularHours;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.merchantId == null) {
        throw Exception('ไม่พบรหัสร้านค้า กรุณาเข้าสู่ระบบร้านค้าใหม่');
      }
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/merchants/${widget.merchantId}/selling-location',
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        throw Exception(
          'เซิร์ฟเวอร์ยังไม่มี API จุดขาย กรุณาอัปเดต Backend บน Render',
        );
      }
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true)
        throw Exception('โหลดจุดขายไม่สำเร็จ');
      final data = body['data'];
      _savedSession = data == null ? null : Map<String, dynamic>.from(data);
      final hoursResponse = await http
          .get(Uri.parse(ApiConfig.merchantHours(widget.merchantId)))
          .timeout(const Duration(seconds: 15));
      if (hoursResponse.statusCode != 200)
        throw Exception('โหลดเวลาประจำไม่สำเร็จ กรุณาลองใหม่');
      final hoursBody = jsonDecode(hoursResponse.body);
      if (hoursBody['success'] != true)
        throw Exception('โหลดเวลาประจำไม่สำเร็จ กรุณาลองใหม่');
      _regularHours = hoursBody['hours'] == null
          ? null
          : Map<String, dynamic>.from(hoursBody['hours']);
      if (data != null &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        _location = CustomerLocation(
          latitude: double.parse(data['latitude'].toString()),
          longitude: double.parse(data['longitude'].toString()),
          address: data['location_name'] ?? 'จุดขาย',
        );
      }
    } on TimeoutException {
      _error = 'เซิร์ฟเวอร์ตอบช้า กรุณาแตะเพื่อลองใหม่';
    } catch (error) {
      _error = error is FormatException
          ? 'เซิร์ฟเวอร์ตอบข้อมูลจุดขายไม่ถูกต้อง กรุณาลองใหม่'
          : error.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<List<DateTime>?> _chooseSessionTimes() async {
    // Construct the chosen calendar date in Thailand, regardless of device timezone.
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    var date = DateTime(now.year, now.month, now.day);
    TimeOfDay start = TimeOfDay(hour: now.hour, minute: now.minute);
    TimeOfDay end = TimeOfDay(hour: (now.hour + 2) % 24, minute: now.minute);
    var fromSchedule = false;
    const days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    void applySchedule() {
      final day = days[date.weekday - 1];
      final h = _regularHours;
      dynamic slot;
      if (h?['weekly_hours'] is Map) {
        slot = h!['weekly_hours'][day];
      } else if (h != null &&
          (h['open_everyday'] == 1 ||
              h['open_everyday'] == true ||
              h['selected_days'].toString().split(',').contains(day))) {
        slot = h;
      }
      fromSchedule = slot != null;
      if (slot != null) {
        final a = slot['open_time'].toString().split(':');
        final b = slot['close_time'].toString().split(':');
        start = TimeOfDay(hour: int.parse(a[0]), minute: int.parse(a[1]));
        end = TimeOfDay(hour: int.parse(b[0]), minute: int.parse(b[1]));
      }
    }

    applySchedule();
    final savedEnd = DateTime.tryParse(
      _savedSession?['selling_ends_at']?.toString() ?? '',
    );
    final savedStart = DateTime.tryParse(
      _savedSession?['selling_started_at']?.toString() ?? '',
    );
    if (savedEnd != null &&
        savedStart != null &&
        savedEnd.isAfter(DateTime.now()) &&
        (_savedSession?['scheduled_open'] == true ||
            _savedSession?['status'] == 'เปิดร้าน' ||
            _savedSession?['status'] == 'กำลังย้าย')) {
      final a = savedStart.toUtc().add(const Duration(hours: 7));
      final b = savedEnd.toUtc().add(const Duration(hours: 7));
      date = DateTime(a.year, a.month, a.day);
      start = TimeOfDay(hour: a.hour, minute: a.minute);
      end = TimeOfDay(hour: b.hour, minute: b.minute);
    }
    String? error;
    return showDialog<List<DateTime>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('เวลาขายรอบนี้'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fromSchedule
                      ? 'เติมจากเวลาประจำแล้ว แก้ไขรอบนี้ได้'
                      : 'เลือกเวลาเริ่มขายและเวลาปิดของรอบนี้',
                ),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: c,
                      initialDate: date,
                      firstDate: DateTime(
                        now.year,
                        now.month,
                        now.day,
                      ).subtract(const Duration(days: 1)),
                      lastDate: DateTime(
                        now.year,
                        now.month,
                        now.day,
                      ).add(const Duration(days: 30)),
                    );
                    if (d != null && c.mounted)
                      update(() {
                        date = d;
                        applySchedule();
                      });
                  },
                  child: Text('วันที่ ${date.day}/${date.month}/${date.year}'),
                ),
                for (final isStart in [true, false])
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: c,
                        initialTime: isStart ? start : end,
                        builder: (ctx, w) => MediaQuery(
                          data: MediaQuery.of(
                            ctx,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: w!,
                        ),
                      );
                      if (t != null && c.mounted)
                        update(() {
                          if (isStart) {
                            start = t;
                          } else {
                            end = t;
                          }
                        });
                    },
                    child: Text(
                      '${isStart ? 'เริ่มขาย' : 'ปิดร้าน'} ${(isStart ? start : end).hour.toString().padLeft(2, '0')}:${(isStart ? start : end).minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                const Text(
                  'เวลาประเทศไทย • ถ้ายังไม่ถึงเวลาเริ่ม หมุดจะยังไม่แสดง\nเวลาปิดก่อนเวลาเริ่มหมายถึงปิดวันถัดไป',
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                if (start == end) {
                  update(() => error = 'เวลาเริ่มและเวลาปิดต้องไม่ตรงกัน');
                  return;
                }
                final a = DateTime.utc(
                  date.year,
                  date.month,
                  date.day,
                  start.hour,
                  start.minute,
                ).subtract(const Duration(hours: 7));
                var b = DateTime.utc(
                  date.year,
                  date.month,
                  date.day,
                  end.hour,
                  end.minute,
                ).subtract(const Duration(hours: 7));
                if (!b.isAfter(a)) b = b.add(const Duration(days: 1));
                if (!b.isAfter(DateTime.now())) {
                  update(() => error = 'เวลาปิดต้องอยู่หลังเวลาปัจจุบัน');
                  return;
                }
                Navigator.pop(c, [a, b]);
              },
              child: const Text(
                'ยืนยันเวลารอบนี้',
                style: TextStyle(color: Color(0xFF00C7E6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish(CustomerLocation location) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final times = await _chooseSessionTimes();
      if (times == null || !mounted) return;
      final response = await http
          .put(
            Uri.parse(ApiConfig.merchantStatus(widget.merchantId)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': 'เปิดร้าน',
              'latitude': location.latitude,
              'longitude': location.longitude,
              'location_name': location.address,
              'selling_started_at': times[0].toUtc().toIso8601String(),
              'selling_ends_at': times[1].toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true)
        throw Exception(body['message'] ?? 'บันทึกไม่สำเร็จ');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ปักหมุดสำเร็จ',
            style: TextStyle(color: Color(0xFF0B1A30)),
          ),
          content: Text(
            body['scheduled_open'] == true
                ? 'บันทึกจุดขายที่ ${location.address} แล้ว หมุดจะแสดงและแจ้งผู้ติดตามเมื่อถึงเวลาเริ่มขาย'
                : 'เปิดร้านที่ ${location.address} แล้ว',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Color(0xFF00C7E6)),
              ),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null)
      return Scaffold(
        appBar: AppBar(title: const Text('แผนที่จุดขาย')),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: Text(_error!),
                ),
        ),
      );
    return Stack(
      children: [
        MapPinSelectionScreen(
          initialLocation: _location,
          saveCustomerLocation: false,
          showStorePins: false,
          confirmLabel: 'ปักหมุดและเลือกเวลาขาย',
          onConfirmLocation: _publish,
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

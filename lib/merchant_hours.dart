import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// 🟢 หน้าแก้ไขเวลาทำการ (MerchantHours)
// =======================================================================
class MerchantHours extends StatefulWidget {
  final dynamic merchantId;

  const MerchantHours({super.key, required this.merchantId});

  @override
  State<MerchantHours> createState() => _MerchantHoursState();
}

class _MerchantHoursState extends State<MerchantHours> {
  bool _isOpenEveryday = true;
  bool _isSaving = false;

  // วันที่เลือก (ถ้าไม่เปิดทุกวัน)
  final List<String> _days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
  final List<String> _selectedDays = ['จ', 'อ', 'พ', 'พฤ', 'ศ'];

  // เวลาเปิด - ปิด
  int _openHour = 8;
  int _openMinute = 0;
  int _closeHour = 18;
  int _closeMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  Future<void> _loadHours() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantHours(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      final hours = body['hours'];
      if (response.statusCode != 200 || hours == null || !mounted) return;

      final openParts = hours['open_time'].toString().split(':');
      final closeParts = hours['close_time'].toString().split(':');
      setState(() {
        _isOpenEveryday =
            hours['open_everyday'] == 1 || hours['open_everyday'] == true;
        _selectedDays
          ..clear()
          ..addAll(
            hours['selected_days']
                .toString()
                .split(',')
                .where((day) => day.isNotEmpty),
          );
        _openHour = int.tryParse(openParts[0]) ?? 8;
        _openMinute = int.tryParse(openParts[1]) ?? 0;
        _closeHour = int.tryParse(closeParts[0]) ?? 18;
        _closeMinute = int.tryParse(closeParts[1]) ?? 0;
      });
    } catch (error) {
      debugPrint('Error loading merchant hours: $error');
    }
  }

  Future<void> _saveHours() async {
    if (widget.merchantId == null || _isSaving) return;
    setState(() => _isSaving = true);

    final openTime =
        '${_openHour.toString().padLeft(2, '0')}:${_openMinute.toString().padLeft(2, '0')}';
    final closeTime =
        '${_closeHour.toString().padLeft(2, '0')}:${_closeMinute.toString().padLeft(2, '0')}';
    final selectedDays = _isOpenEveryday ? _days : _selectedDays;

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantHours(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'open_everyday': _isOpenEveryday,
          'selected_days': selectedDays,
          'open_time': openTime,
          'close_time': closeTime,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'บันทึกไม่สำเร็จ');
      }

      if (!mounted) return;
      final daysText = _isOpenEveryday
          ? '(ทุกวัน)'
          : '(${_selectedDays.join(',')})';
      Navigator.pop(context, '$openTime - $closeTime $daysText');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกเวลาทำการไม่สำเร็จ')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'แก้ไขเวลาทำการ',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // เปิดให้บริการทุกวัน Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'เปิดให้บริการทุกวัน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'จันทร์ - อาทิตย์',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isOpenEveryday,
                  activeColor: const Color(0xFF00C7E6),
                  onChanged: (val) => setState(() => _isOpenEveryday = val),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // เลือกวันที่เปิดให้บริการ (แสดงต่อเมื่อไม่ได้เปิดทุกวัน, แต่จาก UI ภาพโชว์ตลอดก็แสดงไว้ได้)
            const Text(
              'เลือกวันที่ เปิดให้บริการ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _days.map((day) {
                bool isSelected =
                    _isOpenEveryday || _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    if (!_isOpenEveryday) {
                      setState(() {
                        if (_selectedDays.contains(day)) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C7E6)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C7E6)
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ข้อความแจ้งเตือน
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF1E293B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'เวลาเปิด–ปิดร้านตั้งค่าได้จากหน้าปักหมุดในแผนที่ ส่วนหน้านี้ใช้เลือกวันที่เปิดให้บริการ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7E6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveHours,
                child: Text(
                  _isSaving ? 'กำลังบันทึก...' : 'บันทึก',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

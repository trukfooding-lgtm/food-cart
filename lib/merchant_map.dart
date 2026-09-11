import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// =======================================================================
// หน้าแผนที่จุดขาย (MerchantMap)
// =======================================================================
class MerchantMap extends StatefulWidget {
  const MerchantMap({super.key});

  @override
  State<MerchantMap> createState() => _MerchantMapState();
}

class _MerchantMapState extends State<MerchantMap> {
  // 🟢 พิกัดตำแหน่งจุดขายปัจจุบัน (เริ่มต้นด้วยตัวอย่าง: ขามเรียง, มหาสารคาม)
  // ค่านี้จะถูกอัปเดตจริงเมื่อกดปุ่ม "อัปเดตตำแหน่งปัจจุบัน" โดยดึงจาก GPS ของเครื่อง
  double _latitude = 16.1845;
  double _longitude = 103.2998;
  String _locationLabel = 'ขามเรียง, มหาสารคาม';
  bool _isUpdatingLocation = false; // แสดงสถานะกำลังโหลดขณะดึงตำแหน่ง GPS

  // 🟢 ฟังก์ชันเปิดลิงก์ Google Maps ภายนอกแอป โดยใช้พิกัดตำแหน่งจุดขายล่าสุด
  Future<void> _openInGoogleMaps(BuildContext context) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
    );
    try {
      final bool launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่สามารถเปิด Google Maps ได้ กรุณาตรวจสอบว่าติดตั้งแอปหรือเบราว์เซอร์ไว้แล้ว',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเปิด Google Maps: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🟢 ฟังก์ชันหลัก: ขอสิทธิ์ + ดึงพิกัด GPS ปัจจุบันของเครื่อง แล้วแปลงเป็นชื่อสถานที่ (Reverse Geocoding)
  Future<void> _updateCurrentLocation() async {
    if (_isUpdatingLocation) return; // กันกดซ้ำระหว่างกำลังโหลด
    setState(() => _isUpdatingLocation = true);

    try {
      // ตรวจสอบว่าเครื่องเปิดใช้งาน Location Service (GPS) อยู่หรือไม่
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationMessage(
          'กรุณาเปิดใช้งาน Location Service (GPS) บนเครื่องก่อน',
          isError: true,
        );
        return;
      }

      // ตรวจสอบและขอสิทธิ์การเข้าถึงตำแหน่งจากผู้ใช้
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationMessage(
            'แอปไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง กรุณาอนุญาตเพื่ออัปเดตตำแหน่งร้านค้า',
            isError: true,
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'สิทธิ์เข้าถึงตำแหน่งถูกปฏิเสธถาวร กรุณาเปิดสิทธิ์ในการตั้งค่าเครื่อง',
          isError: true,
        );
        return;
      }

      // ดึงพิกัด GPS ปัจจุบันของเครื่อง
      // 🟢 แก้บั๊ก "กดแล้วค้าง": เดิมไม่ได้ตั้ง timeLimit ทำให้ถ้าหาสัญญาณ GPS ไม่เจอ (เช่น อยู่ในตึก/สัญญาณอ่อน)
      // Future นี้จะไม่มีวันเสร็จ ปุ่มเลยค้างที่สถานะ "กำลังโหลด" ตลอดไป จึงเพิ่ม .timeout() เพื่อยกเลิกและแจ้งเตือนแทน
      final Position position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('หาสัญญาณ GPS ไม่สำเร็จภายในเวลาที่กำหนด');
            },
          );

      // แปลงพิกัดเป็นชื่อสถานที่ที่อ่านง่าย (เช่น ตำบล, จังหวัด) ผ่าน Reverse Geocoding
      String label =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) label = parts.join(', ');
        }
      } catch (_) {
        // หาก reverse geocoding ล้มเหลว (เช่น ไม่มีอินเทอร์เน็ต) จะใช้พิกัดตัวเลขแสดงแทนชื่อสถานที่
      }

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLabel = label;
      });
      _showLocationMessage('อัปเดตตำแหน่งปัจจุบันสำเร็จ! 📍', isError: false);
    } on TimeoutException {
      // 🟢 กรณีค้นหาสัญญาณ GPS นานเกินไป แจ้งเตือนผู้ใช้แทนการปล่อยให้ปุ่มค้าง
      _showLocationMessage(
        'ค้นหาตำแหน่งไม่สำเร็จ ใช้เวลานานเกินไป กรุณาตรวจสอบสัญญาณ GPS แล้วลองใหม่อีกครั้ง',
        isError: true,
      );
    } catch (e) {
      _showLocationMessage('เกิดข้อผิดพลาดในการดึงตำแหน่ง: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingLocation = false);
    }
  }

  void _showLocationMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // 🟢 เปิด dialog ให้ผู้ใช้กรอกพิกัด (ละติจูด/ลองจิจูด) และชื่อสถานที่เอง แล้วบันทึกเป็นตำแหน่งจุดขายใหม่
  Future<void> _showEditCoordinatesDialog(BuildContext context) async {
    final labelController = TextEditingController(text: _locationLabel);
    final latController = TextEditingController(
      text: _latitude.toStringAsFixed(6),
    );
    final lngController = TextEditingController(
      text: _longitude.toStringAsFixed(6),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'เปลี่ยนพิกัดจุดขาย',
            style: TextStyle(
              color: Color(0xFF0B1A30),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสถานที่ (เช่น ตำบล, จังหวัด)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อสถานที่';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'ละติจูด (Latitude)',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < -90 || parsed > 90) {
                        return 'กรุณากรอกละติจูดที่ถูกต้อง (-90 ถึง 90)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'ลองจิจูด (Longitude)',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < -180 || parsed > 180) {
                        return 'กรุณากรอกลองจิจูดที่ถูกต้อง (-180 ถึง 180)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final newLat = double.parse(latController.text.trim());
                final newLng = double.parse(lngController.text.trim());
                final newLabel = labelController.text.trim();

                setState(() {
                  _latitude = newLat;
                  _longitude = newLng;
                  _locationLabel = newLabel;
                });

                Navigator.of(dialogContext).pop();
                _showLocationMessage(
                  'บันทึกพิกัดใหม่เรียบร้อยแล้ว! 📍',
                  isError: false,
                );
              },
              child: const Text(
                'บันทึก',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    labelController.dispose();
    latController.dispose();
    lngController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0B1A30),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แผนที่จุดขาย',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ตำแหน่งร้านค้าปัจจุบัน',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1A30),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'อัปเดตตำแหน่งเพื่อให้ลูกค้าค้นหาคุณได้ง่ายขึ้น',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isUpdatingLocation
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00C7E6)),
                          SizedBox(height: 16),
                          Text(
                            'กำลังค้นหาตำแหน่งปัจจุบัน...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0B1A30),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 60,
                            color: Color(0xFF00C7E6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'จำลองมุมมองแผนที่ Google Maps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0B1A30),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'พิกัด: $_locationLabel',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C7E6).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF00C7E6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0B1A30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'พบลูกค้า 15 คน ในรัศมี 3 กม.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditCoordinatesDialog(context),
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color(0xFF00C7E6),
                    ),
                    label: const Text(
                      'เปลี่ยนพิกัด',
                      style: TextStyle(
                        color: Color(0xFF00C7E6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🟢 ปุ่มเปิดตำแหน่งจุดขายใน Google Maps ภายนอกแอป
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00C7E6), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => _openInGoogleMaps(context),
                icon: const Icon(Icons.map_outlined, color: Color(0xFF00C7E6)),
                label: const Text(
                  'เปิดใน Google Maps',
                  style: TextStyle(
                    color: Color(0xFF00C7E6),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🟢 ปุ่มอัปเดตตำแหน่งปัจจุบันจาก GPS จริงของเครื่อง — ปิดปุ่มและแสดง Spinner ระหว่างกำลังค้นหาตำแหน่ง
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7E6),
                  disabledBackgroundColor: const Color(
                    0xFF00C7E6,
                  ).withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                onPressed: _isUpdatingLocation ? null : _updateCurrentLocation,
                child: _isUpdatingLocation
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'อัปเดตตำแหน่งปัจจุบัน',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

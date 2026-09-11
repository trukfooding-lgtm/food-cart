import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// 🟢 หน้าตั้งค่าสถานะร้านค้า (MerchantStatus)
// เข้าถึงจากหน้า "การตั้งค่าระบบร้านค้า" > แถว "สถานะร้าน"
// เลือกสถานะได้ก่อน (ยังไม่มีผลทันที) แล้วต้องกด "บันทึก" ซึ่งจะถามยืนยันก่อนเสมอ
// เมื่อยืนยันแล้วจะย้อนกลับไปหน้าตั้งค่า พร้อมค่าสถานะใหม่
// =======================================================================
class MerchantStatus extends StatefulWidget {
  final dynamic merchantId;
  final String initialStatus;
  const MerchantStatus({
    super.key,
    required this.merchantId,
    required this.initialStatus,
  });

  @override
  State<MerchantStatus> createState() => _MerchantStatusState();
}

class _MerchantStatusState extends State<MerchantStatus> {
  late String _selectedStatus;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'title': 'เปิดร้าน',
      'description': 'ส่งแจ้งเตือนอัตโนมัติไปให้ลูกค้าที่ติดตาม',
      'icon': Icons.storefront_outlined,
      'activeColor': const Color(0xFF10B981),
      'bgColor': const Color(0xFFE6F4EA),
      'sendNotification': true,
    },
    {
      'title': 'กำลังย้าย',
      'description': 'ส่งแจ้งเตือนอัตโนมัติไปให้ลูกค้าที่ติดตาม',
      'icon': Icons.moped_outlined,
      'activeColor': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFEF3C7),
      'sendNotification': true,
    },
    {
      'title': 'ปิดร้าน',
      'description': 'ไม่ส่งแจ้งเตือน',
      'icon': Icons.do_not_disturb_on_outlined,
      'activeColor': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFEE2E2),
      'sendNotification': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantStatus(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true && mounted) {
        setState(() => _selectedStatus = body['status'].toString());
      }
    } catch (error) {
      debugPrint('Error loading merchant status: $error');
    }
  }

  // 🟢 กด "บันทึก" แล้วต้องยืนยันก่อนเสมอว่าจะบันทึกจริงไหม
  Future<void> _confirmAndSave() async {
    final Map<String, dynamic> selectedOption = _statusOptions.firstWhere(
      (o) => o['title'] == _selectedStatus,
    );
    final Color activeColor = selectedOption['activeColor'] as Color;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ยืนยันการเปลี่ยนสถานะร้าน',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            'คุณต้องการบันทึกสถานะร้านเป็น "${selectedOption['title']}" ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'ยืนยัน',
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

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        final response = await http.put(
          Uri.parse(ApiConfig.merchantStatus(widget.merchantId)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': _selectedStatus}),
        );
        final body = jsonDecode(response.body);
        if (response.statusCode != 200 || body['success'] != true) {
          throw Exception(body['message'] ?? 'บันทึกไม่สำเร็จ');
        }
      } catch (error) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกสถานะร้านไม่สำเร็จ')),
        );
        return;
      }

      if (!mounted) return;
      final bool sendNotification = selectedOption['sendNotification'] as bool;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendNotification
                ? 'อัปเดตสถานะเป็น "${selectedOption['title']}" และส่งแจ้งเตือนไปยังลูกค้าที่ติดตามแล้ว 🔔'
                : 'อัปเดตสถานะเป็น "${selectedOption['title']}" แล้ว (ไม่ส่งแจ้งเตือน)',
          ),
          backgroundColor: sendNotification
              ? activeColor
              : const Color(0xFF64748B),
        ),
      );
      Navigator.pop(
        context,
        _selectedStatus,
      ); // 🟢 ย้อนกลับไปหน้าตั้งค่า พร้อมส่งสถานะใหม่กลับไป
    }
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
          'สถานะร้านค้า',
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
              'เลือกสถานะเพื่อแจ้งให้ลูกค้าทราบ',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _statusOptions.map((option) {
                  final bool isSelected = _selectedStatus == option['title'];
                  final Color activeColor = option['activeColor'] as Color;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedStatus = option['title']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor.withOpacity(0.12)
                                  : option['bgColor'] as Color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              option['icon'] as IconData,
                              color: activeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? activeColor
                                        : const Color(0xFF0B1A30),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option['description'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: activeColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
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
                onPressed: _isSaving ? null : _confirmAndSave,
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

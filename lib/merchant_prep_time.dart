import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// 🟢 หน้าตั้งค่าเวลาเตรียมสินค้า (MerchantPrepTime)
// =======================================================================
class MerchantPrepTime extends StatefulWidget {
  final dynamic merchantId;

  const MerchantPrepTime({super.key, required this.merchantId});

  @override
  State<MerchantPrepTime> createState() => _MerchantPrepTimeState();
}

class _MerchantPrepTimeState extends State<MerchantPrepTime> {
  int _selectedHour = 0;
  int _selectedMinute = 15;
  bool _isSaving = false;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
    _loadPrepTime();
  }

  Future<void> _loadPrepTime() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantPrepTime(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }

      final totalMinutes = int.tryParse(body['prepMinutes'].toString()) ?? 15;
      setState(() {
        _selectedHour = totalMinutes ~/ 60;
        _selectedMinute = totalMinutes % 60;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hourController.hasClients) {
          _hourController.jumpToItem(_selectedHour);
        }
        if (_minuteController.hasClients) {
          _minuteController.jumpToItem(_selectedMinute);
        }
      });
    } catch (error) {
      debugPrint('Error loading merchant prep time: $error');
    }
  }

  Future<void> _savePrepTime() async {
    if (widget.merchantId == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantPrepTime(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prep_minutes': (_selectedHour * 60) + _selectedMinute,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'บันทึกไม่สำเร็จ');
      }

      if (!mounted) return;
      final result = _selectedHour > 0
          ? '$_selectedHour ชม. $_selectedMinute นาที'
          : '$_selectedMinute นาที';
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกเวลาเตรียมอาหารไม่สำเร็จ')),
      );
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
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
          'เวลาเตรียมสินค้า',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(flex: 1),
            const Text(
              'กำหนดเวลาเตรียมอาหาร',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เลือกเวลาที่คาดว่าจะใช้ในการเตรียมสินค้า',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // วงล้อเลือกเวลา (Wheel Picker)
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // แถบคาดตรงกลาง
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // วงล้อชั่วโมง
                      SizedBox(
                        width: 60,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(),
                          controller: _hourController,
                          onSelectedItemChanged: (index) =>
                              setState(() => _selectedHour = index),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 23) return null;
                              return Center(
                                child: Text(
                                  index.toString(),
                                  style: TextStyle(
                                    fontSize: _selectedHour == index ? 22 : 18,
                                    fontWeight: _selectedHour == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedHour == index
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                            childCount: 24,
                          ),
                        ),
                      ),
                      const Text(
                        'ชม.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(width: 20),
                      // วงล้อนาที
                      SizedBox(
                        width: 60,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(),
                          controller: _minuteController,
                          onSelectedItemChanged: (index) =>
                              setState(() => _selectedMinute = index),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 59) return null;
                              return Center(
                                child: Text(
                                  index.toString(),
                                  style: TextStyle(
                                    fontSize: _selectedMinute == index
                                        ? 22
                                        : 18,
                                    fontWeight: _selectedMinute == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedMinute == index
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                            childCount: 60,
                          ),
                        ),
                      ),
                      const Text(
                        'นาที',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // กล่องแสดงเวลาที่เลือก
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เวลาที่เลือก',
                    style: TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    _selectedHour > 0
                        ? '$_selectedHour ชม. $_selectedMinute นาที'
                        : '$_selectedMinute นาที',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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
                onPressed: _isSaving ? null : _savePrepTime,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

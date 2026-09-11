import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// หน้าจัดการแต้มสะสม (MerchantLoyalty) — เหลือเฉพาะ "ตั้งค่าเงื่อนไข"
// 🟢 เอาแท็บ "ข้อมูลลูกค้า" และรายชื่อ/แต้มลูกค้าออกตามที่ร้านค้าขอ
// =======================================================================
class MerchantLoyalty extends StatefulWidget {
  final dynamic merchantId;

  const MerchantLoyalty({super.key, required this.merchantId});

  @override
  State<MerchantLoyalty> createState() => _MerchantLoyaltyState();
}

class _MerchantLoyaltyState extends State<MerchantLoyalty> {
  // สถานะเปิด/ปิด ระบบแต้ม
  bool _isLoyaltyEnabled = true;
  bool _isSaving = false;

  // Controller สำหรับกรอกข้อมูลเงื่อนไข
  final TextEditingController _bahtPerPointController = TextEditingController(
    text: '50',
  );
  final TextEditingController _pointsForDiscountController =
      TextEditingController(text: '100');
  final TextEditingController _discountAmountController = TextEditingController(
    text: '10',
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantLoyaltySettings(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      final settings = body['settings'];
      if (response.statusCode != 200 || settings == null || !mounted) return;
      setState(() {
        _isLoyaltyEnabled =
            settings['is_enabled'] == 1 || settings['is_enabled'] == true;
        _bahtPerPointController.text = settings['baht_per_point'].toString();
        _pointsForDiscountController.text = settings['points_for_discount']
            .toString();
        _discountAmountController.text = settings['discount_amount'].toString();
      });
    } catch (error) {
      debugPrint('Error loading loyalty settings: $error');
    }
  }

  Future<void> _saveSettings() async {
    final baht = int.tryParse(_bahtPerPointController.text.trim());
    final points = int.tryParse(_pointsForDiscountController.text.trim());
    final discount = double.tryParse(_discountAmountController.text.trim());
    if (baht == null ||
        baht <= 0 ||
        points == null ||
        points <= 0 ||
        discount == null ||
        discount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกตัวเลขที่มากกว่า 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantLoyaltySettings(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'is_enabled': _isLoyaltyEnabled,
          'baht_per_point': baht,
          'points_for_discount': points,
          'discount_amount': discount,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'บันทึกไม่สำเร็จ');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกเงื่อนไขแต้มสะสมเรียบร้อยแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกเงื่อนไขแต้มไม่สำเร็จ')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _bahtPerPointController.dispose();
    _pointsForDiscountController.dispose();
    _discountAmountController.dispose();
    super.dispose();
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
          'ระบบแต้มสะสม',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      // 🟢 ตัดโครง DefaultTabController / TabBar / TabBarView ออก เหลือแค่เนื้อหาตั้งค่าเงื่อนไขอย่างเดียว
      body: _buildSettingsTab(),
    );
  }

  // UI สำหรับ "ตั้งค่าเงื่อนไข" (คงไว้เหมือนเดิมทุกอย่าง)
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // กล่อง เปิด-ปิด ระบบแต้ม
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isLoyaltyEnabled
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isLoyaltyEnabled ? Icons.check_circle : Icons.cancel,
                        color: _isLoyaltyEnabled ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ระบบแต้มสะสม',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          _isLoyaltyEnabled ? 'เปิดใช้งานอยู่' : 'ปิดใช้งาน',
                          style: TextStyle(
                            color: _isLoyaltyEnabled
                                ? Colors.green
                                : Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isLoyaltyEnabled,
                  activeColor: const Color(0xFF00C7E6),
                  onChanged: (val) {
                    setState(() {
                      _isLoyaltyEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'เงื่อนไขการให้คะแนน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // กล่องตั้งค่าคะแนน
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'ทุกยอดสั่งซื้อ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _bahtPerPointController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: _isLoyaltyEnabled,
                        decoration: _buildInputDecoration(),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '  บาท = 1 แต้ม',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'เงื่อนไขการแลกส่วนลด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // กล่องตั้งค่าส่วนลด
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'ใช้คะแนน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _pointsForDiscountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: _isLoyaltyEnabled,
                        decoration: _buildInputDecoration(),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '  แต้ม',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'แลกส่วนลด',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _discountAmountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: _isLoyaltyEnabled,
                        decoration: _buildInputDecoration(),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '  บาท',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
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
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              onPressed: _isSaving ? null : _saveSettings,
              child: Text(
                _isSaving ? 'กำลังบันทึก...' : 'บันทึกการตั้งค่า',
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
    );
  }

  // รูปแบบ TextField ภายในกล่องตั้งค่า
  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00C7E6), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
    );
  }
}

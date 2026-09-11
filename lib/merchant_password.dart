import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// 🟢 หน้าเปลี่ยนรหัสผ่าน (MerchantPassword)
// ดีไซน์ตามภาพตัวอย่างที่ส่งมา: หัวข้อใหญ่ + คำอธิบายเงื่อนไขรหัสผ่าน + ช่องกรอก 3 ช่อง
// + ลิงก์ "ลืมรหัสผ่านของคุณใช่ไหม" + ปุ่มเปลี่ยนรหัสผ่านด้านล่าง
// (ไม่มีกล่องติ๊ก "ออกจากระบบอุปกรณ์อื่นๆ" และไม่มีชื่อบัญชีด้านบนตามที่ระบุ)
// =======================================================================
class MerchantPassword extends StatefulWidget {
  final dynamic merchantId;

  const MerchantPassword({super.key, required this.merchantId});

  @override
  State<MerchantPassword> createState() => _MerchantPasswordState();
}

class _MerchantPasswordState extends State<MerchantPassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // 🟢 วันที่อัปเดตรหัสผ่านล่าสุด แสดงไว้ในช่อง "รหัสผ่านปัจจุบัน" เหมือนภาพตัวอย่าง
  final String _lastPasswordUpdateDate = '7/4/2026';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.merchantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบ ID ร้านค้า กรุณาเข้าสู่ระบบใหม่'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantPassword(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เปลี่ยนรหัสผ่านสำเร็จ'),
            backgroundColor: const Color(0xFF00C7E6),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ไม่สามารถเปลี่ยนรหัสผ่านได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _passwordFieldDecoration({
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: Colors.grey,
        ),
        onPressed: onToggleObscure,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00C7E6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF0B1A30),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'เปลี่ยนรหัสผ่าน',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1A30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'รหัสผ่านของคุณต้องมีความยาวอย่างน้อย 6 อักขระและประกอบด้วยตัวเลข ตัวอักษร และอักขระพิเศษ (!\$@%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        decoration: _passwordFieldDecoration(
                          hintText:
                              'รหัสผ่านปัจจุบัน (อัพเดตในวันที่ $_lastPasswordUpdateDate)',
                          obscure: _obscureCurrent,
                          onToggleObscure: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'กรุณากรอกรหัสผ่านปัจจุบัน'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: _passwordFieldDecoration(
                          hintText: 'รหัสผ่านใหม่',
                          obscure: _obscureNew,
                          onToggleObscure: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณากรอกรหัสผ่านใหม่';
                          if (value.length < 6)
                            return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: _passwordFieldDecoration(
                          hintText: 'พิมพ์รหัสผ่านใหม่อีกครั้ง',
                          obscure: _obscureConfirm,
                          onToggleObscure: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณายืนยันรหัสผ่านใหม่';
                          if (value != _newPasswordController.text)
                            return 'รหัสผ่านไม่ตรงกัน';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'หากลืมรหัสผ่าน กรุณาติดต่อฝ่ายสนับสนุน',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'ลืมรหัสผ่านของคุณใช่ไหม',
                          style: TextStyle(
                            color: Color(0xFF00C7E6),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
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
                  onPressed: _isLoading ? null : _submitChangePassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'เปลี่ยนรหัสผ่าน',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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

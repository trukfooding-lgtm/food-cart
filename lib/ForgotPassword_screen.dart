import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.config.dart';
import 'otp_verification_screen.dart'; 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกที่อยู่อีเมลของคุณ', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // แสดงแจ้งเตือนกำลังส่งข้อมูล
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังส่งข้อมูลขอรับรหัส OTP กรุณารอสักครู่...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // 🌐 ยิง API ส่งอีเมล OTP โดยดึงลิงก์จาก ApiConfig.sendOtp
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ส่งรหัส OTP ไปยังอีเมล $email แล้ว'),
            backgroundColor: const Color(0xFF32C6E8),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ไม่พบข้อมูลอีเมลนี้ในระบบ'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ข้อผิดพลาดเครือข่าย: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]), child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context))),
                    const Center(child: Text('ลืมรหัสผ่าน', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                  ],
                ),
                const SizedBox(height: 36),
                const Text('ระบุอีเมล Gmail ของคุณเพื่อรับรหัสยืนยัน', style: TextStyle(fontSize: 16, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ที่อยู่อีเมล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'example@gmail.com', hintStyle: const TextStyle(color: Color(0xFF94A3B8)), prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16))),
                      const SizedBox(height: 32),
                      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _sendOtp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF32C6E8), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ส่งรหัส OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
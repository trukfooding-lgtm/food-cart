import 'package:flutter/material.dart';
import 'buyer_home_screen.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.config.dart';

class RegisterBuyerScreen extends StatefulWidget {
  const RegisterBuyerScreen({super.key});

  @override
  State<RegisterBuyerScreen> createState() => _RegisterBuyerScreenState();
}

class _RegisterBuyerScreenState extends State<RegisterBuyerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _registerBuyer() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim().toLowerCase();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'), backgroundColor: Colors.redAccent));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/customers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone
        }),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // สำเร็จมักจะเป็น 200 หรือ 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final customerData = resData['customer'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จเรียบร้อย! 🎉'), backgroundColor: Color(0xFF10B981)),
        );

        // นำผู้ใช้เข้าสู่หน้าหลักทันที พร้อมส่งข้อมูลบัญชีที่เพิ่งสมัครไปด้วย
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerHomeScreen(userData: customerData),
          ),
          (route) => false,
        );
      } else {
        final resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์'), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0B1A30)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shadowColor: Colors.black12,
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('สมัครสมาชิกผู้ซื้อ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              const SizedBox(height: 6),
              const Text('ค้นหาและติดตามรถขายของใกล้คุณได้ง่ายๆ', style: TextStyle(fontSize: 13, color: Colors.black45)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ชื่อ-นามสกุล', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: _inputDeco('กรอกชื่อและนามสกุล', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    const Text('อีเมล', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDeco('example@mail.com', Icons.mail_outline),
                    ),
                    const SizedBox(height: 16),
                    const Text('รหัสผ่าน', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDeco('••••••••', Icons.lock_outline),
                    ),
                    const SizedBox(height: 16),
                    const Text('เบอร์โทร', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDeco('08x-xxx-xxxx', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerBuyer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C7E6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'การสมัครสมาชิกหมายความว่าคุณยอมรับ\nข้อตกลงและเงื่อนไข ของเรา',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black38),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('มีบัญชีอยู่แล้ว? ', style: TextStyle(color: Colors.black45)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('เข้าสู่ระบบ', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F4F4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }
}
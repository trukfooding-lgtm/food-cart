import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.config.dart';
import 'buyer_home_screen.dart'; 
import 'role_selection_screen.dart'; 
import 'merchant_login_screen.dart'; 
import 'ForgotPassword_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true; 
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

   Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🌐 ยิง API เข้าสู่ระบบจริง โดยเรียกใช้ลิงก์จาก ApiConfig
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('📡 [Login] URL: ${ApiConfig.login}');
      debugPrint('📡 [Login] Status: ${response.statusCode}');
      debugPrint('📡 [Login] Body: ${response.body}');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        final preview = response.body.length > 70 ? response.body.substring(0, 70).replaceAll('\n', ' ') : response.body;
        throw 'เซิร์ฟเวอร์ตอบกลับไม่ใช่ JSON (Code ${response.statusCode}: $preview) โปรดตรวจเช็กว่า IP/Port ใน api.config.dart ชี้ไปที่ Backend Node.js ถูกต้อง';
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เข้าสู่ระบบสำเร็จ!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // ไปยังหน้าระบบหลัก และส่งข้อมูลลูกค้าไปด้วย! 
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerHomeScreen(userData: data['customer']),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ หรือรหัสผ่านผิด'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F7), 
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping, size: 35, color: Color(0xFF0B1A30)),
                  ),
                  const SizedBox(height: 20),
                  const Text('แอปพลิเคชั่นค้นหารถขายของ\nเคลื่อนที่', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30), height: 1.3)),
                  const SizedBox(height: 10),
                  const Text('ค้นพบและลิ้มลองความอร่อยจากรถขายของใกล้คุณ', style: TextStyle(fontSize: 13, color: Colors.black45)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เข้าสู่ระบบผู้ซื้อ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MerchantLoginScreen()));
                        },
                        child: const Text('สลับเป็นผู้ค้า >', style: TextStyle(color: Color(0xFF00C7E6), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('อีเมล', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  const SizedBox(height: 8),
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'example@email.com', filled: true, fillColor: const Color(0xFFF4F5F7), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  const Text('รหัสผ่าน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  const SizedBox(height: 8),
                  TextField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(hintText: '• • • • • • • •', filled: true, fillColor: const Color(0xFFF4F5F7), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
                  
                  // 📍 ซ่อมปุ่มลืมรหัสผ่านที่พังให้แล้ว
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () { 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())); 
                      }, 
                      child: const Text('ลืมรหัสผ่าน?', style: TextStyle(color: Colors.black, fontSize: 12))
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C7E6), elevation: 2, shadowColor: const Color(0xFF00C7E6).withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      onPressed: _isLoading ? null : _login, 
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ยังไม่มีบัญชี? ', style: TextStyle(color: Colors.black45, fontSize: 13)),
                      GestureDetector(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const RoleSelectionScreen())); }, child: const Text('สมัครสมาชิก', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
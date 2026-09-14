import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart'; // Import หน้าล็อกอิน
import 'api.config.dart';
import 'merchant_add_bank_account.dart';

class RegisterMerchantScreen extends StatefulWidget {
  const RegisterMerchantScreen({super.key});

  @override
  State<RegisterMerchantScreen> createState() => _RegisterMerchantScreenState();
}

class _RegisterMerchantScreenState extends State<RegisterMerchantScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedType = 'ร้านอาหารสตรีทฟู้ด';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันยิง API สมัครสมาชิกผู้ค้า
  Future<void> _registerMerchant() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // *หมายเหตุ: หากทดสอบบน Android Emulator ให้เปลี่ยน localhost เป็น 10.0.2.2
    var url = Uri.parse(
      '${ApiConfig.baseUrl}/api/merchants/register',
    );

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "phone": phone,
          "type": _selectedType
        }),
      );
      
      var data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;

        final merchantId = data['merchant_id'];
        if (merchantId == null) throw Exception('เซิร์ฟเวอร์ไม่ส่งรหัสร้านค้า');
        final bankSaved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => MerchantAddBankAccount(merchantId: merchantId)),
        );
        if (bankSaved != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเพิ่มบัญชีรับเงินอย่างน้อย 1 บัญชีก่อนเข้าใช้งาน')));
            setState(() => _isLoading = false);
          }
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกผู้ค้าสำเร็จเรียบร้อย!'), 
            backgroundColor: Colors.green,
          ),
        );
        
        // 🟢 สมัครสำเร็จ -> กลับไปหน้าเข้าสู่ระบบ (LoginScreen)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เกิดข้อผิดพลาด'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'), 
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
              const Text('สมัครสมาชิกผู้ค้า', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              const SizedBox(height: 6),
              const Text('ร่วมเป็นส่วนหนึ่งกับเราและขยายธุรกิจของคุณ', style: TextStyle(fontSize: 13, color: Colors.black45)),
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
                    const Text('ชื่อร้านค้า', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(controller: _nameController, decoration: _inputDeco('กรอกชื่อร้านค้า', Icons.person_outline)),
                    const SizedBox(height: 16),
                    
                    const Text('อีเมล', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _inputDeco('example@mail.com', Icons.mail_outline)),
                    const SizedBox(height: 16),
                    
                    const Text('รหัสผ่าน', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(controller: _passwordController, obscureText: true, decoration: _inputDeco('••••••••', Icons.lock_outline)),
                    const SizedBox(height: 16),

                    const Text('เบอร์โทร', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDeco('08x-xxx-xxxx', Icons.phone_outlined)),
                    const SizedBox(height: 16),
                    
                    const Text('เลือกประเภทร้าน', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(color: Color(0xFFF4F4F4), borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(border: InputBorder.none),
                        items: ['ร้านอาหารสตรีทฟู้ด', 'ร้านเครื่องดื่ม / คาเฟ่', 'ร้านของทานเล่น'].map((String item) {
                          return DropdownMenuItem<String>(value: item, child: Text(item));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerMerchant,
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

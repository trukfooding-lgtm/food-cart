import 'package:flutter/material.dart';
import 'register_buyer_screen.dart';
import 'register_merchant_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String selectedRole = 'buyer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'คุณต้องการสมัครสมาชิก\nประเภทใด?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3425),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRole = 'buyer';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selectedRole == 'buyer' ? const Color(0xFF00C7E6) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: selectedRole == 'buyer' ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF4F4F4),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: selectedRole == 'buyer' ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผู้ซื้อ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: selectedRole == 'buyer' ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ค้นหาและติดตามรถขายของใกล้คุณ',
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedRole == 'buyer' ? Colors.white70 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRole = 'merchant';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selectedRole == 'merchant' ? const Color(0xFF00C7E6) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: selectedRole == 'merchant' ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF4F4F4),
                        child: Icon(
                          Icons.storefront_outlined,
                          color: selectedRole == 'merchant' ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผู้ค้า',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: selectedRole == 'merchant' ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'เพิ่มรถขายของของคุณและจัดการร้านค้า',
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedRole == 'merchant' ? Colors.white70 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedRole == 'buyer') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterBuyerScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterMerchantScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'ถัดไป',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('มีบัญชีอยู่แล้ว? ', style: TextStyle(color: Colors.black45, fontSize: 14)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
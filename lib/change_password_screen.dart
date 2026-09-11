import 'package:flutter/material.dart';

// ============================================================
// CHANGE PASSWORD SCREEN (หน้าเปลี่ยนรหัสผ่าน)
// ============================================================
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── หัวข้อ
            const Text(
              'เปลี่ยนรหัสผ่าน',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
            ),
            const SizedBox(height: 12),

            // ── คำอธิบาย
            const Text(
              'รหัสผ่านของคุณต้องมีความยาวอย่างน้อย 6 อักขระและประกอบด้วยตัวเลข ตัวอักษร และอักขระพิเศษ (!\$@%)',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 28),

            // ── ช่อง 1: รหัสผ่านปัจจุบัน
            _buildPasswordField(
              controller: _currentPasswordCtrl,
              hintText: 'รหัสผ่านปัจจุบัน (อัพเดตในวันที่ 7/4/2026)',
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 16),

            // ── ช่อง 2: รหัสผ่านใหม่
            _buildPasswordField(
              controller: _newPasswordCtrl,
              hintText: 'รหัสผ่านใหม่',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),

            // ── ช่อง 3: พิมพ์รหัสผ่านใหม่อีกครั้ง
            _buildPasswordField(
              controller: _confirmPasswordCtrl,
              hintText: 'พิมพ์รหัสผ่านใหม่อีกครั้ง',
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 18),

            // ── ลิงก์ลืมรหัสผ่าน
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ระบบลืมรหัสผ่าน (รอเชื่อมต่อ)'), backgroundColor: Color(0xFF00C7E6)),
                );
              },
              child: const Text(
                'ลืมรหัสผ่านของคุณใช่ไหม',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF00C7E6)),
              ),
            ),

            const Spacer(),

            // ── ปุ่มเปลี่ยนรหัสผ่าน
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7E6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Validate
                      if (_currentPasswordCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'), backgroundColor: Color(0xFFE53935)),
                        );
                        return;
                      }
                      if (_newPasswordCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร'), backgroundColor: Color(0xFFE53935)),
                        );
                        return;
                      }
                      if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('รหัสผ่านใหม่ไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง'), backgroundColor: Color(0xFFE53935)),
                        );
                        return;
                      }

                      // สำเร็จ
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE0F7FA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_outline, size: 34, color: Color(0xFF00C7E6)),
                                ),
                                const SizedBox(height: 18),
                                const Text('เปลี่ยนรหัสผ่านสำเร็จ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                                const SizedBox(height: 10),
                                const Text('รหัสผ่านของคุณถูกอัปเดตเรียบร้อยแล้ว', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00C7E6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('ตกลง', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: Color(0xFF0B1A30)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C7E6), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF94A3B8),
            size: 22,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

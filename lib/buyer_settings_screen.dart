import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.config.dart';
import 'login_screen.dart';

class BuyerSettingsScreen extends StatefulWidget {
  final String customerId;
  const BuyerSettingsScreen({super.key, this.customerId = '1'});

  @override
  State<BuyerSettingsScreen> createState() => _BuyerSettingsScreenState();
}

class _BuyerSettingsScreenState extends State<BuyerSettingsScreen> {
  // ตัวแปรสำหรับเปิด-ปิดการแจ้งเตือน
  bool _storeNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // สีพื้นหลังเดียวกับหน้าโปรไฟล์
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('ตั้งค่า', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          
          // ── หมวดการแจ้งเตือน ──
          _buildSectionTitle('การแจ้งเตือน'),
          _buildCleanMenuTile(
            icon: Icons.storefront_outlined,
            title: 'แจ้งเตือนจากร้านที่ติดตาม',
            trailing: Switch(
              value: _storeNotifications,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF00C7E6), // สีฟ้าแอป
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
              onChanged: (val) => setState(() => _storeNotifications = val),
            ),
          ),
          
          // เส้นคั่นบางๆ เหมือนหน้าโปรไฟล์
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider(height: 1, color: Colors.grey[200])),
          
          // ── หมวดความปลอดภัย ──
          _buildSectionTitle('ความปลอดภัย'),
          _buildCleanMenuTile(
            icon: Icons.lock_outline,
            title: 'เปลี่ยนรหัสผ่าน',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('หน้าเปลี่ยนรหัสผ่าน (รอกำหนด UI)'))),
          ),

          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider(height: 1, color: Colors.grey[200])),
          
          // ── หมวดจัดการบัญชี ──
          _buildSectionTitle('จัดการบัญชี'),
          _buildCleanMenuTile(
            icon: Icons.delete_outline,
            title: 'ลบบัญชีผู้ใช้',
            isDestructive: true, // ทำให้ตัวอักษรและไอคอนเป็นสีแดง
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  // ตัวช่วยสร้างหัวข้อ
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 24, top: 16),
      child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
    );
  }

  // 🔴 ฟังก์ชันสร้างเมนูแบบ "คลีน" (ก็อปมาจากหน้า Profile เป๊ะๆ)
  Widget _buildCleanMenuTile({
    required IconData icon, 
    required String title, 
    bool isDestructive = false, 
    Widget? trailing,
    VoidCallback? onTap
  }) {
    // กำหนดสี ถ้าเป็นปุ่มอันตราย (ลบบัญชี) ให้ใช้สีแดง ถ้าปกติใช้สีกรมท่า
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0B1A30);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 18),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color))),
            
            // ถ้ามีการส่ง Widget (เช่น Switch) มา ให้แสดง Widget นั้น ถ้าไม่มีให้แสดงลูกศร >
            if (trailing != null) 
              trailing
            else 
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // แจ้งเตือนยืนยันการลบ
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ยืนยันการลบบัญชี', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
        content: const Text('ข้อมูลทั้งหมดของคุณ จะถูกลบอย่างถาวรและไม่สามารถกู้คืนได้ คุณแน่ใจหรือไม่?', style: TextStyle(color: Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () => _deleteAccount(dialogCtx),
            child: const Text('ลบบัญชีถาวร', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันลบบัญชีจากฐานข้อมูลจริง
  Future<void> _deleteAccount(BuildContext dialogCtx) async {
    Navigator.pop(dialogCtx); // ปิด dialog
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/customers/${widget.customerId}');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบบัญชีผู้ใช้สำเร็จแล้ว ✅'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        // เด้งออกจากแอปกลับไปหน้า Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถลบบัญชีได้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
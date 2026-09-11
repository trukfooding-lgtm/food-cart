import 'package:flutter/material.dart';
import 'faq_detail_screen.dart';

// ============================================================
// HELP CENTER SCREEN (หน้าติดต่อช่วยเหลือ / ศูนย์ช่วยเหลือ)
// ============================================================
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // รายการคำถามที่พบบ่อย
    final List<String> faqList = [
      'ทำไมฉันจึงสั่งร้านที่กำลังย้ายไม่ได้ ?',
      'เปลี่ยนตำแหน่งปัจจุบันได้อย่างไร ?',
      'จะดูรีวิวร้านได้ที่ไหน ?',
      'กดติดตามร้านได้อย่างไร ?',
      'จะดูร้านที่ใกล้ฉันได้อย่างไร ?',
      'คำสั่งซื้อที่ถูกร้านปฏิเสธได้ที่ไหน ?',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ติดต่อช่วยเหลือ', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. ส่วนติดต่อฝ่ายสนับสนุน
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ติดต่อฝ่ายสนับสนุน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  const SizedBox(height: 4),
                  const Text('ทีมงานพร้อมช่วยเหลือคุณทุกวัน 10:00 - 18:00 น.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 18),

                  // การ์ดอีเมล
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เปิดอีเมล trukfo.support@example.com'), backgroundColor: Color(0xFF00C7E6)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          // ไอคอนอีเมล
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.email_outlined, color: Color(0xFF00C7E6), size: 24),
                          ),
                          const SizedBox(width: 14),
                          // ข้อความ
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('อีเมลถึงฝ่ายสนับสนุน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B1A30))),
                                SizedBox(height: 2),
                                Text('trukfo.support@example.com', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 2. ส่วนคำถามที่พบบ่อย
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('คำถามที่พบบ่อย', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  const SizedBox(height: 14),

                  // รายการคำถาม
                  ...faqList.map((question) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                       onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => FaqDetailScreen(question: question)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(question, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

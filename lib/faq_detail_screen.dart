import 'package:flutter/material.dart';

// ============================================================
// FAQ DETAIL SCREEN (หน้าแสดงรายละเอียดคำถามที่พบบ่อย)
// ============================================================
class FaqDetailScreen extends StatefulWidget {
  final String question;

  const FaqDetailScreen({super.key, required this.question});

  @override
  State<FaqDetailScreen> createState() => _FaqDetailScreenState();
}

class _FaqDetailScreenState extends State<FaqDetailScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // เตรียมข้อมูลคำตอบตามคำถาม
    final faqContent = _getFaqContent(widget.question);

    return Scaffold(
      backgroundColor: Colors.white,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── หัวข้อคำถาม
            Text(
              faqContent['title'] as String,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30), height: 1.3),
            ),
            const SizedBox(height: 12),

            // ── คำอธิบายสั้นๆ
            Text(
              faqContent['subtitle'] as String,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 28),

            // ── ขั้นตอนที่ 1
            _buildStepHeader('1', faqContent['step1_title'] as String),
            const SizedBox(height: 8),
            Text(
              faqContent['step1_desc'] as String,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
            ),
            const SizedBox(height: 18),

            // ── กล่องขยาย (Expandable)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF00C7E6),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        faqContent['expand_title'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF00C7E6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── เนื้อหาในกล่องขยาย
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ขั้นตอนย่อย
                    ...(faqContent['expand_steps'] as List<Map<String, String>>).asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // เลขลำดับ
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C7E6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$idx', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    step['text']!,
                                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                            // รูปภาพประกอบ (ถ้ามี)
                            if (step['img'] != null && step['img']!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  step['img']!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 40)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── ขั้นตอนที่ 2
            _buildStepHeader('2', faqContent['step2_title'] as String),
            const SizedBox(height: 8),
            Text(
              faqContent['step2_desc'] as String,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
            ),

            // ── รูปภาพประกอบขั้นตอนที่ 2 (ถ้ามี)
            if ((faqContent['step2_img'] as String).isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  faqContent['step2_img'] as String,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 40)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getFaqContent(String question) {
    // เนื้อหาสำหรับแต่ละคำถาม
    final Map<String, Map<String, dynamic>> contents = {
      'ทำไมฉันจึงสั่งร้านที่กำลังย้ายไม่ได้ ?': {
        'title': 'ทำไมฉันจึงสั่งร้านที่กำลังย้ายไม่ได้ ?',
        'subtitle': 'ร้านที่แสดงสถานะ "กำลังย้าย" หมายความว่าร้านกำลังเปลี่ยนตำแหน่งจอดรถ จึงยังไม่พร้อมรับออเดอร์ชั่วคราว',
        'step1_title': 'สถานะร้านค้ามีอะไรบ้าง',
        'step1_desc': 'ร้านค้าในแอป Food Cart มี 3 สถานะ ได้แก่ "เปิดให้บริการ" (สั่งได้ปกติ), "กำลังย้าย" (ไม่สามารถสั่งได้ชั่วคราว) และ "ปิดให้บริการ" (หยุดขาย)',
        'expand_title': 'วิธีตรวจสอบสถานะร้านค้า',
        'expand_steps': [
          {'text': 'เปิดแอป Food Cart แล้วดูที่หน้าหลัก จะเห็นป้ายสถานะอยู่มุมบนซ้ายของการ์ดร้านค้า', 'img': ''},
          {'text': 'ร้านที่ขึ้นป้าย "กำลังย้าย" สีส้ม จะไม่สามารถกดสั่งซื้อได้ ต้องรอจนกว่าร้านจะเปลี่ยนสถานะเป็น "เปิดให้บริการ"', 'img': ''},
        ],
        'step2_title': 'ทำอย่างไรเมื่อร้านกำลังย้าย',
        'step2_desc': 'คุณสามารถกดติดตามร้านค้าไว้ได้ เมื่อร้านกลับมาเปิดให้บริการอีกครั้ง คุณจะได้รับการแจ้งเตือนทันที',
        'step2_img': '',
      },
      'เปลี่ยนตำแหน่งปัจจุบันได้อย่างไร ?': {
        'title': 'เปลี่ยนตำแหน่งปัจจุบันได้อย่างไร ?',
        'subtitle': 'คุณสามารถเปลี่ยนตำแหน่งปัจจุบันได้ง่ายๆ เพื่อค้นหาร้านค้าใกล้บ้านคุณ',
        'step1_title': 'กดที่ตำแหน่งปัจจุบัน',
        'step1_desc': 'ที่หน้าหลักด้านบนสุด คุณจะเห็นแถบแสดงที่อยู่ปัจจุบัน ให้กดที่แถบนั้นเพื่อเปลี่ยนตำแหน่ง',
        'expand_title': 'วิธีเปลี่ยนตำแหน่งบน Food Cart',
        'expand_steps': [
          {'text': 'กดที่แถบแสดงตำแหน่งด้านบนของหน้าหลัก', 'img': ''},
          {'text': 'พิมพ์ที่อยู่หรือค้นหาสถานที่ที่ต้องการ', 'img': ''},
          {'text': 'เลือกตำแหน่งที่ต้องการแล้วกดยืนยัน', 'img': ''},
        ],
        'step2_title': 'ตรวจสอบร้านค้าใกล้เคียง',
        'step2_desc': 'หลังจากเปลี่ยนตำแหน่งแล้ว ระบบจะแสดงร้านค้าที่อยู่ใกล้ตำแหน่งใหม่ของคุณโดยอัตโนมัติ',
        'step2_img': '',
      },
      'จะดูรีวิวร้านได้ที่ไหน ?': {
        'title': 'จะดูรีวิวร้านได้ที่ไหน ?',
        'subtitle': 'คุณสามารถอ่านรีวิวจากผู้ใช้คนอื่นเพื่อช่วยตัดสินใจเลือกร้าน',
        'step1_title': 'เข้าหน้ารายละเอียดร้านค้า',
        'step1_desc': 'กดที่การ์ดร้านค้าที่หน้าหลัก เพื่อเข้าสู่หน้ารายละเอียดร้าน จากนั้นเลื่อนลงมาจะเห็นส่วนรีวิวและคะแนน',
        'expand_title': 'วิธีดูรีวิวร้านค้าบน Food Cart',
        'expand_steps': [
          {'text': 'กดที่การ์ดร้านค้าเพื่อเข้าหน้ารายละเอียดร้าน', 'img': ''},
          {'text': 'เลื่อนลงมาจะเห็นส่วน "รีวิวจากลูกค้า" พร้อมคะแนนดาวและความคิดเห็น', 'img': ''},
        ],
        'step2_title': 'เขียนรีวิวของคุณเอง',
        'step2_desc': 'หลังจากสั่งซื้อและรับอาหารสำเร็จ คุณสามารถเขียนรีวิวและให้คะแนนร้านค้าได้ที่หน้าคำสั่งซื้อของฉัน',
        'step2_img': '',
      },
      'กดติดตามร้านได้อย่างไร ?': {
        'title': 'กดติดตามร้านได้อย่างไร ?',
        'subtitle': 'ติดตามร้านโปรดเพื่อไม่พลาดเมนูใหม่ๆ และโปรโมชั่นพิเศษ',
        'step1_title': 'เข้าหน้ารายละเอียดร้านค้า',
        'step1_desc': 'กดที่การ์ดร้านค้าที่หน้าหลัก เพื่อเข้าสู่หน้ารายละเอียดร้าน จากนั้นกดปุ่ม "ติดตาม" ที่ด้านบนของหน้า',
        'expand_title': 'วิธีติดตามร้านค้าบน Food Cart',
        'expand_steps': [
          {'text': 'กดที่การ์ดร้านค้าเพื่อเข้าหน้ารายละเอียดร้าน', 'img': ''},
          {'text': 'กดปุ่มรูปหัวใจหรือปุ่ม "ติดตาม" ที่ด้านบนของหน้า', 'img': ''},
        ],
        'step2_title': 'ดูร้านที่ติดตามทั้งหมด',
        'step2_desc': 'ไปที่หน้าโปรไฟล์ แล้วกด "ร้านค้าที่ติดตาม" เพื่อดูรายการร้านค้าที่คุณกดติดตามไว้ทั้งหมด',
        'step2_img': '',
      },
      'จะดูร้านที่ใกล้ฉันได้อย่างไร ?': {
        'title': 'จะดูร้านที่ใกล้ฉันได้อย่างไร ?',
        'subtitle': 'แอป Food Cart จะแสดงร้านค้าเรียงตามระยะทางจากตำแหน่งปัจจุบันของคุณ',
        'step1_title': 'ตั้งค่าตำแหน่งปัจจุบัน',
        'step1_desc': 'ตรวจสอบให้แน่ใจว่าตำแหน่งปัจจุบันของคุณถูกต้อง โดยดูที่แถบด้านบนของหน้าหลัก',
        'expand_title': 'วิธีดูร้านที่ใกล้ที่สุด',
        'expand_steps': [
          {'text': 'ที่หน้าหลัก กดปุ่มเรียงลำดับเพื่อเลือก "ใกล้ที่สุด"', 'img': ''},
          {'text': 'ระบบจะจัดเรียงร้านค้าจากใกล้ไปไกลตามตำแหน่งของคุณ', 'img': ''},
        ],
        'step2_title': 'ดูระยะทาง',
        'step2_desc': 'ที่การ์ดร้านค้าแต่ละร้านจะแสดงระยะทางโดยประมาณ เพื่อให้คุณเลือกร้านที่สะดวกที่สุด',
        'step2_img': '',
      },
      'คำสั่งซื้อที่ถูกร้านปฏิเสธได้ที่ไหน ?': {
        'title': 'คำสั่งซื้อที่ถูกร้านปฏิเสธได้ที่ไหน ?',
        'subtitle': 'คุณสามารถตรวจสอบคำสั่งซื้อที่ถูกยกเลิกและขอคืนเงินได้ง่ายๆ',
        'step1_title': 'เข้าหน้าคำสั่งซื้อของฉัน',
        'step1_desc': 'กดที่แท็บ "คำสั่งซื้อ" ที่แถบด้านล่าง แล้วกดเลือกสถานะ "คืนเงิน" เพื่อดูรายการคำสั่งซื้อที่ถูกยกเลิก',
        'expand_title': 'วิธีดูคำสั่งซื้อที่ถูกยกเลิก',
        'expand_steps': [
          {'text': 'กดแท็บ "คำสั่งซื้อ" ที่แถบด้านล่าง', 'img': ''},
          {'text': 'กดที่ตัวกรองสถานะ แล้วเลือก "คืนเงิน"', 'img': ''},
          {'text': 'จะแสดงรายการคำสั่งซื้อที่ถูกยกเลิก พร้อมสถานะการคืนเงิน', 'img': ''},
        ],
        'step2_title': 'ดูรายละเอียดการคืนเงิน',
        'step2_desc': 'กดที่รายการคำสั่งซื้อเพื่อดูรายละเอียดการคืนเงิน รวมถึงเหตุผลการยกเลิกและสถานะการคืนเงิน',
        'step2_img': '',
      },
    };

    // ถ้าไม่มีข้อมูลให้ใช้ค่าเริ่มต้น
    return contents[question] ?? {
      'title': question,
      'subtitle': 'การใช้งานในแอป Food Cart ง่ายกว่าที่คุณคิด ทำตามขั้นตอนต่อไปนี้เลย',
      'step1_title': 'ขั้นตอนแรก',
      'step1_desc': 'รายละเอียดขั้นตอนแรกของคำถามนี้',
      'expand_title': 'วิธีทำบน Food Cart',
      'expand_steps': <Map<String, String>>[
        {'text': 'เปิดแอป Food Cart', 'img': ''},
        {'text': 'ทำตามขั้นตอนที่ระบุ', 'img': ''},
      ],
      'step2_title': 'ขั้นตอนถัดไป',
      'step2_desc': 'รายละเอียดขั้นตอนถัดไปของคำถามนี้',
      'step2_img': '',
    };
  }
}

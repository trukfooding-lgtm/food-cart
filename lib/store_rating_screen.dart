import 'package:flutter/material.dart';
import 'buyer_home_screen.dart';

class StoreRatingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> truck;

  const StoreRatingScreen({super.key, required this.order, required this.truck});

  @override
  State<StoreRatingScreen> createState() => _StoreRatingScreenState();
}
class _StoreRatingScreenState extends State<StoreRatingScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeTitle = widget.order['storeTitle'] ?? 'ชื่อร้านค้า';
    final storeImage = (widget.truck['image'] as String?) ?? 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&q=80&w=300';
    const Color activeColor = Color(0xFF00C7E6); // สีทีมแอป

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // สีพื้นหลังเทาอ่อน
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFEF4444)), // กากบาทสีแดง
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ให้คะแนนร้าน', style: TextStyle(color: Color(0xFF0B1A30), fontSize: 17, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. รูปและชื่อร้าน (ข้อมูลจริง)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              storeImage,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 54, height: 54, color: const Color(0xFFE2E8F0), child: const Icon(Icons.storefront, color: Color(0xFF94A3B8))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              storeTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B1A30)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 20),

                      // 2. ให้ดาว
                      const Text('ให้คะแนนร้าน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: index < _rating ? activeColor : const Color(0xFFCBD5E1),
                                size: 42,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // 3. เพิ่มภาพ (ทำกรอบจำลอง Dotted ให้ดูพรีเมียมคล้ายภาพ)
                      const Text('เพิ่มภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined, color: Color(0xFF64748B), size: 26),
                            SizedBox(height: 6),
                            Text('เพิ่มภาพ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. ช่องแชร์รีวิว พร้อมนับตัวอักษร
                      const Text('แชร์รีวิวของคุณ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _reviewController,
                          maxLines: 5,
                          maxLength: 500,
                          onChanged: (text) => setState(() {}),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                          decoration: InputDecoration(
                            hintText: 'แชร์รีวิวของคุณที่นี่...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            counterText: '${_reviewController.text.length}ตัวอักษร',
                            counterStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. ปุ่มส่งด้านล่างสุด (จะกดได้ก็ต่อเมื่อให้ดาวอย่างน้อย 1 ดวง)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rating > 0 ? activeColor : const Color(0xFFF1F5F9), // สีปุ่มเปิด/ปิด
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _rating > 0 ? () {
                    // ส่งรีวิวเสร็จแล้วเด้งกลับหน้าโฮม
                    Navigator.pop(context);
                  } : null,
                  child: Text(
                    'ส่ง',
                    style: TextStyle(
                      color: _rating > 0 ? Colors.white : const Color(0xFF94A3B8), // สีข้อความปุ่มเปิด/ปิด
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
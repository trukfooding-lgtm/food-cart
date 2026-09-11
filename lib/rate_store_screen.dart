import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // สำคัญมาก เพราะหน้านี้มีการเรียกใช้ตัวเลือกรูปภาพ
import 'buyer_home_screen.dart';
// ============================================================
// ⭐ RATE STORE SCREEN (หน้าเลือกรีวิวให้คะแนนร้านค้า - ข้อ 1)
// ============================================================
class RateStoreScreen extends StatefulWidget {
  final Map<String, dynamic> truck;
  final Future<void> Function(int stars, String comment, List<String> images) onSubmitted;

  const RateStoreScreen({super.key, required this.truck, required this.onSubmitted});

  @override
  State<RateStoreScreen> createState() => _RateStoreScreenState();
}

class _RateStoreScreenState extends State<RateStoreScreen> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  final List<String> _uploadedImages = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

    Future<bool> _onWillPop() async {
    final bool? res = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ไอคอนเครื่องหมายคำถามตรงกลาง
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white, // พื้นหลังสีแดงอ่อน
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline, size: 34, color: Color(0xFFE53935)), 
              ),
              const SizedBox(height: 18),
              // หัวข้อ
              const Text(
                'คุณต้องการปิดหน้าต่างรีวิวร้านค้าใช่หรือไม่?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
              ),
              const SizedBox(height: 12),
              // ข้อความอธิบาย
              const Text(
                'คุณสามารถกลับมาให้รีวิวร้านนี้ใหม่ได้ทุกเมื่อที่"คำสั่งซื้อของฉัน"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 28),
              // ปุ่มปิด (ปุ่มสีแดงใหญ่)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('ให้คะแนนภายหลัง', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              // ปุ่มอยู่ต่อ (ปุ่มข้อความสีฟ้า)
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text('เขียนรีวิว', style: TextStyle(color: Color(0xFF00C7E6), fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF0B1A30)),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('ให้คะแนนและรีวิวร้านค้า', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Store info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(widget.truck['img'] ?? '', width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: const Color(0xFFF4F5F7), child: const Icon(Icons.storefront, color: Color(0xFF94A3B8))))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.truck['title'] ?? 'ชื่อร้าน', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B1A30))),
                          const SizedBox(height: 4),
                          Text(widget.truck['shopType'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          const Text('สั่งซื้อและรับสินค้าเสร็จเรียบร้อยแล้ว ✔', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Star Selection Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    const Text('คุณภาพอาหารและการบริการเป็นอย่างไรบ้าง?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              index < _selectedRating ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFFB300),
                              size: 44,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedRating == 0 ? 'โปรดระบุระดับคะแนน' : (_selectedRating == 5 ? 'ยอดเยี่ยมที่สุด ⭐⭐⭐⭐⭐' : (_selectedRating >= 4 ? 'ดีมาก ⭐⭐⭐⭐' : (_selectedRating == 3 ? 'พอใช้ ⭐⭐⭐' : 'ควรปรับปรุง ⭐'))),
                      style: TextStyle(
                        fontSize: 14, 
                        color: _selectedRating == 0 ? const Color(0xFF94A3B8) : const Color(0xFF00C7E6), 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Comment Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('แสดงความคิดเห็นเพิ่มเติม (ถ้ามี):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1A30))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'เล่าประสบการณ์ความประทับใจเกี่ยวกับรสชาติอาหาร บริการ หรือความสะอาด...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF4F7FA),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('อัปโหลดรูปภาพอาหารหรือหน้าร้าน:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1A30))),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._uploadedImages.map((img) => Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 76, height: 76,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), image: DecorationImage(image: img.startsWith('http') ? NetworkImage(img) as ImageProvider : FileImage(File(img)), fit: BoxFit.cover)),
                          )),
                          GestureDetector(
                            onTap: () async {
                              if (_uploadedImages.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปโหลดรูปได้สูงสุด 3 รูปเท่านั้น 📸')));
                                return;
                              }
                              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  _uploadedImages.add(image.path);
                                });
                              }
                            },
                            child: Container(
                              width: 76, height: 76,
                              decoration: BoxDecoration(color: const Color(0xFFF4F7FA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5, style: BorderStyle.solid)),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B), size: 26), SizedBox(height: 2), Text('เพิ่มรูป', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold))]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // ── Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // เปลี่ยนสีปุ่มเป็นสีเทาถ้ายังไม่กดดาว
                    backgroundColor: _selectedRating > 0 ? const Color(0xFF00C7E6) : const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  // ล็อกปุ่ม (ใส่ null) ถ้ายังไม่กดดาว
                  onPressed: (_selectedRating > 0 && !_isSubmitting) ? () async {
                    setState(() => _isSubmitting = true);
                    await widget.onSubmitted(_selectedRating, _commentController.text.trim(), List<String>.from(_uploadedImages));
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                      Navigator.of(context).pop();
                    }
                  } : null,
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text('ส่งคะแนนรีวิวร้านค้า', style: TextStyle(
                        color: _selectedRating > 0 ? Colors.white : const Color(0xFF94A3B8), 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      )),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
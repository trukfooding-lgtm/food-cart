import 'package:flutter/material.dart';

class ReviewModel {
  final String user;
  final String avatar;
  final int rating;
  final String comment;
  final List<String> tags;
  final List<String> images;
  final String date;

  ReviewModel({
    required this.user,
    required this.avatar,
    required this.rating,
    required this.comment,
    this.tags = const [],
    this.images = const [],
    required this.date,
  });
}
// ============================================================
// REVIEWS PAGE (Full screen matching UI guidelines)
// ============================================================
class ReviewsPage extends StatefulWidget {
  final Map<String, dynamic> truck;
  final bool isGuestMode;
  final bool canWriteReview;
  final VoidCallback? onReviewSubmitted;

  const ReviewsPage({super.key, required this.truck, required this.isGuestMode, this.canWriteReview = false, this.onReviewSubmitted});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  String _filterTab = 'ทั้งหมด';
  int _selectedStarFilter = 0; // 0 = all, 1..5

  late List<ReviewModel> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = List<ReviewModel>.from(widget.truck['reviews'] ?? []);
  }

  List<ReviewModel> get _filtered {
    List<ReviewModel> r = _reviews;
    if (_selectedStarFilter > 0) {
      r = r.where((rv) => rv.rating == _selectedStarFilter).toList();
    }
    if (_filterTab == 'ที่มีคอมเมนต์') {
      // แสดงเฉพาะรีวิวที่มีแต่ข้อความ (ไม่มีรูปภาพ)
      r = r.where((rv) => rv.comment.trim().isNotEmpty && rv.images.isEmpty).toList();
    } else if (_filterTab == 'มีรูปภาพ') {
      r = r.where((rv) => rv.images.isNotEmpty).toList();
    }
    return r;
  }

  double get _avgRating => _reviews.isEmpty ? 0 : _reviews.fold(0.0, (sum, r) => sum + r.rating) / _reviews.length;

  void _showAddReviewDialog() {
    // ตรวจสิทธิ์การเขียนรีวิว (ต้องสั่งซื้อก่อน)
    if (!widget.canWriteReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คุณยังไม่มีสิทธิ์เขียนรีวิว สั่งซื้ออาหารจากร้านนี้ก่อนถึงจะเขียนรีวิวได้ 🚫'),
          backgroundColor: Color(0xFF64748B),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final commentCtrl = TextEditingController();
    int selectedRating = 5;
    final List<String> mockUploadedImages = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheet) {
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('เขียนรีวิวร้าน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  IconButton(icon: const Icon(Icons.close, color: Color(0xFF94A3B8)), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 14),
                const Text('ให้คะแนน:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B1A30))),
                const SizedBox(height: 8),
                Row(children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheet(() => selectedRating = i + 1),
                  child: Icon(i < selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                ))),
                const SizedBox(height: 16),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'เขียนรีวิวของคุณที่นี่...',
                    filled: true, fillColor: const Color(0xFFF4F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('อัปโหลดรูปภาพ:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B1A30))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    ...mockUploadedImages.map((img) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 72, height: 72,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)),
                    )),
                    GestureDetector(
                      onTap: () {
                        setSheet(() {
                          mockUploadedImages.add('https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?auto=format&fit=crop&w=200&q=80');
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('จำลองการอัปโหลดรูปภาพแล้ว 📸'), backgroundColor: Colors.green));
                      },
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF94A3B8), size: 28), SizedBox(height: 2), Text('อัปโหลด', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C7E6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                    onPressed: () {
                      if (commentCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _reviews.insert(0, ReviewModel(
                            user: 'คุณ',
                            avatar: 'ฉ',
                            rating: selectedRating,
                            comment: commentCtrl.text.trim(),
                            tags: ['รสชาติดี', 'บริการเยี่ยม'],
                            images: List<String>.from(mockUploadedImages),
                            date: 'วันนี้ 12:30',
                          ));
                        });
                        Navigator.pop(ctx);
                        widget.onReviewSubmitted?.call();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ขอบคุณสำหรับรีวิวของคุณ! 🌟'), backgroundColor: Colors.green));
                      }
                    },
                    child: const Text('ส่งรีวิว', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalCommentCount = _reviews.where((r) => r.comment.trim().isNotEmpty && r.images.isEmpty).length;
    final totalImageCount = _reviews.where((r) => r.images.isNotEmpty).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('คะแนน', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                          const Text(' / 5', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 10),
                          Row(children: List.generate(5, (i) => Icon(i < _avgRating.floor() ? Icons.star : Icons.star_border, color: Colors.amber, size: 18))),
                        ],
                      ),
                      Text('${_reviews.length} รีวิว', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Chip 1: ทั้งหมด
                        _buildFilterBox(
                          title: 'ทั้งหมด',
                          sub: '(${_reviews.length})',
                          isSelected: _filterTab == 'ทั้งหมด' && _selectedStarFilter == 0,
                          onTap: () => setState(() { _filterTab = 'ทั้งหมด'; _selectedStarFilter = 0; }),
                        ),
                        // Chip 2: ดาว ⭐️ Dropdown
                        _buildStarDropdownChip(),
                        // Chip 3: ที่มีคอมเมนต์
                        _buildFilterBox(
                          title: 'ที่มีคอมเมนต์',
                          sub: '($totalCommentCount)',
                          isSelected: _filterTab == 'ที่มีคอมเมนต์',
                          onTap: () => setState(() { _filterTab = 'ที่มีคอมเมนต์'; _selectedStarFilter = 0; }),
                        ),
                        // Chip 4: มีรูปภาพ
                        _buildFilterBox(
                          title: 'มีรูปภาพ',
                          sub: '($totalImageCount)',
                          isSelected: _filterTab == 'มีรูปภาพ',
                          onTap: () => setState(() { _filterTab = 'มีรูปภาพ'; _selectedStarFilter = 0; }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Reviews List
            filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('ยังไม่มีรีวิวในหมวดนี้', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15))),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildReviewCardItem(filtered[i]),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBox({required String title, required String sub, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5EEF5) : const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF00C7E6) : Colors.transparent, width: 1.2),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF00C7E6) : const Color(0xFF0B1A30))),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF00C7E6) : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildStarDropdownChip() {
    final isSelected = _selectedStarFilter > 0;
    return PopupMenuButton<int>(
      onSelected: (val) {
        setState(() {
          _selectedStarFilter = val;
          _filterTab = 'ดาว';
        });
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 0, child: Text('ดาวทั้งหมด')),
        const PopupMenuItem(value: 5, child: Text('5 ดาว ⭐️⭐️⭐️⭐️⭐️')),
        const PopupMenuItem(value: 4, child: Text('4 ดาว ⭐️⭐️⭐️⭐️')),
        const PopupMenuItem(value: 3, child: Text('3 ดาว ⭐️⭐️⭐️')),
        const PopupMenuItem(value: 2, child: Text('2 ดาว ⭐️⭐️')),
        const PopupMenuItem(value: 1, child: Text('1 ดาว ⭐️')),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5EEF5) : const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF00C7E6) : Colors.transparent, width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(_selectedStarFilter == 0 ? 'ดาว ⭐️' : 'ดาว ($_selectedStarFilter⭐️)',
                  style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF00C7E6) : const Color(0xFF0B1A30)),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 2),
            Text(_selectedStarFilter == 0 ? '(ทั้งหมด)' : '($_selectedStarFilter ดาว)',
              style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF00C7E6) : const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCardItem(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5EEF5),
                child: Text(review.avatar, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00C7E6), fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0B1A30))),
                    const SizedBox(height: 2),
                    Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 13))),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 10),

          // Comment
          if (review.comment.isNotEmpty) ...[
            Text(review.comment, style: const TextStyle(fontSize: 13, color: Color(0xFF0B1A30), height: 1.5)),
            const SizedBox(height: 10),
          ],

          // Tags
          if (review.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: review.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF4F7FA), borderRadius: BorderRadius.circular(12)),
                child: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              )).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Images
          if (review.images.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length > 3 ? 3 : review.images.length,
                itemBuilder: (_, i) {
                  final isLastAndMore = i == 2 && review.images.length > 3;
                  final extraCount = review.images.length - 3;

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.network(review.images[i], width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: const Color(0xFFF4F5F7)),
                          ),
                          if (isLastAndMore)
                            Container(
                              width: 100, height: 100,
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Text('+$extraCount', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Date
          Text(review.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
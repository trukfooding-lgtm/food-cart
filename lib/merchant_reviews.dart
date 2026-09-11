import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// 🟢 หน้าดูคะแนนรีวิวจากลูกค้า (MerchantReviews)
// =======================================================================
class MerchantReviews extends StatefulWidget {
  final dynamic merchantId;

  const MerchantReviews({super.key, required this.merchantId});

  @override
  State<MerchantReviews> createState() => _MerchantReviewsState();
}

class _MerchantReviewsState extends State<MerchantReviews> {
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantReviews(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception('โหลดรีวิวไม่สำเร็จ');
      }

      final reviews = List<Map<String, dynamic>>.from(
        (body['data'] as List).map((item) {
          final review = Map<String, dynamic>.from(item);
          review['name'] = review['customer_name'] ?? 'ไม่ระบุชื่อ';
          review['date'] =
              review['reviewed_at']?.toString().split('T').first ?? '-';
          final rawImages = review['images'];
          review['images'] = rawImages is String && rawImages.isNotEmpty
              ? List<String>.from(jsonDecode(rawImages))
              : <String>[];
          return review;
        }),
      );
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _averageRating = double.tryParse(body['averageRating'].toString()) ?? 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading merchant reviews: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0B1A30),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'คะแนนและรีวิว',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'คะแนนเฉลี่ยร้านค้า',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              '/ 5.0',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'จากทั้งหมด ${_reviews.length} รีวิว',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7E6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reviews,
                    size: 40,
                    color: Color(0xFF00C7E6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? const Center(child: Text('ยังไม่มีรีวิว'))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // 🟢 รูปโปรไฟล์ลูกค้า (อวตารตัวอักษรย่อ ไม่ใช่รูปคนจริง)
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: _avatarColorFor(index),
                                      child: Text(
                                        _avatarInitial(
                                          review['name'] as String,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      review['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  review['date'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                5,
                                (starIndex) => Icon(
                                  starIndex < review['rating']
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              review['comment']?.toString() ?? '',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 14,
                              ),
                            ),
                            // 🟢 แท็กรีวิว เช่น "รสชาติดี", "หอมมาก" (ถ้ามี)
                            if (review['tags'] != null &&
                                (review['tags'] as List).isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (review['tags'] as List<String>).map((
                                  tag,
                                ) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            // 🟢 แสดงรูปภาพที่ลูกค้าแนบมากับรีวิว (ถ้ามี)
                            if (review['images'] != null &&
                                (review['images'] as List).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 72,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (review['images'] as List).length,
                                  separatorBuilder: (context, i) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, imgIndex) {
                                    final String imageUrl =
                                        (review['images'] as List)[imgIndex];
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.all(
                                              20,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                width: 72,
                                                height: 72,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🟢 ดึงตัวอักษรย่อของชื่อลูกค้ามาใช้เป็นอวตาร (ตัดคำว่า "คุณ" ออกก่อน ถ้ามี)
  String _avatarInitial(String name) {
    final String cleanName = name.replaceFirst('คุณ', '').trim();
    if (cleanName.isEmpty) return '?';
    return cleanName.substring(0, 1).toUpperCase();
  }

  // 🟢 สุ่มสีพื้นหลังอวตารจากชุดสีที่เข้ากับธีมแอป โดยไล่ตามลำดับรีวิว ให้แต่ละคนมีสีต่างกัน
  Color _avatarColorFor(int index) {
    const List<Color> palette = [
      Color(0xFF00C7E6), // ฟ้า (สีธีมหลัก)
      Color(0xFFF59E0B), // ส้ม
      Color(0xFF10B981), // เขียว
      Color(0xFFEC4899), // ชมพู
      Color(0xFF8B5CF6), // ม่วง
    ];
    return palette[index % palette.length];
  }
}

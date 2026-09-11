import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api.config.dart';

class FollowedShopsScreen extends StatefulWidget {
  final String customerId;
  final List<Map<String, dynamic>> allShops;
  final Function(Map<String, dynamic>) onShopTap;

  const FollowedShopsScreen({
    super.key, 
    this.customerId = '1',
    required this.allShops,
    required this.onShopTap,
  });

  @override
  State<FollowedShopsScreen> createState() => _FollowedShopsScreenState();
}

class _FollowedShopsScreenState extends State<FollowedShopsScreen> {
  List<Map<String, dynamic>> _followedShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowedShops(); // 🟢 ดึงข้อมูลจากฐานข้อมูลตอนเปิดหน้า
  }

  Future<void> _fetchFollowedShops() async {
    try {
      final customerId = widget.customerId;
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/customers/$customerId/followed'));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          final List<dynamic> followedIds = resData['data'];
          
          if (mounted) {
            setState(() {
              // 🟢 กรองเอาร้านเฉพาะที่เซิร์ฟเวอร์บอกว่าติดตามไว้
              _followedShops = widget.allShops.where((shop) {
                final int shopId = int.tryParse(shop['id']?.toString() ?? shop['merchant_id']?.toString() ?? '0') ?? 0;
                return followedIds.contains(shopId);
              }).map((shop) => {
                'original_data': shop,
                'title': shop['name'] ?? shop['title'] ?? 'ร้านไม่มีชื่อ',
                'img': shop['image_url'] ?? shop['img'] ?? 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200',
                'status': shop['status'] == 'เปิด' ? 'เปิดขายแล้ว (จากฐานข้อมูล)' : 'ปิดร้านชั่วคราว',
                'isFollowing': true,
                'merchant_id': shop['id'] ?? shop['merchant_id'],
              }).toList();
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print('Error fetching followed shops: $e');
    }
    
    // ถ้าพัง โชว์ลิสต์ว่างไปก่อน
    if (mounted) {
      setState(() {
        _followedShops = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('ร้านที่ติดตาม', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6)))
        : _followedShops.isEmpty
          ? const Center(child: Text('ยังไม่มีร้านค้าที่ติดตาม', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)))
          : ListView.separated(
              itemCount: _followedShops.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final shop = _followedShops[index];
                final bool isFollowing = shop['isFollowing'] ?? true;
                
                return Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () {
                      if (shop['original_data'] != null) {
                        widget.onShopTap(shop['original_data']);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[200]!),
                              image: DecorationImage(image: NetworkImage(shop['img']), fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop['title'], 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B1A30)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  shop['status'], 
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isFollowing ? const Color(0xFF00C7E6) : Colors.white,
                                backgroundColor: isFollowing ? Colors.transparent : const Color(0xFF00C7E6),
                                side: const BorderSide(color: Color(0xFF00C7E6), width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () async {
                                final bool wasFollowing = isFollowing;
                                
                                // สลับ UI ล่วงหน้า
                                setState(() { shop['isFollowing'] = !wasFollowing; });

                                 // 🟢 ยิง API อัปเดตฐานข้อมูลด้วย
                                try {
                                  final int mId = int.tryParse(shop['merchant_id']?.toString() ?? '1') ?? 1;
                                  
                                   final int cId = int.tryParse(widget.customerId) ?? 1;
                                   final response = await http.post(
                                     Uri.parse('${ApiConfig.baseUrl}/api/customers/follow'),
                                     headers: {'Content-Type': 'application/json'},
                                     body: jsonEncode({
                                       'customer_id': cId,
                                       'customerId': cId,
                                       'merchant_id': mId,
                                       'merchantId': mId
                                     }),
                                   );
                                  
                                  if (response.statusCode != 200) throw Exception('API fail');
                                } catch (e) {
                                  // สลับกลับถ้าพัง
                                  setState(() { shop['isFollowing'] = wasFollowing; });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์')));
                                }
                              },
                              child: Text(isFollowing ? 'กำลังติดตาม' : 'ติดตาม', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
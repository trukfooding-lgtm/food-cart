import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'api.config.dart';
import 'buyer_home_screen.dart'; // ใช้ StoreDetailPage, ReviewsPage, AllStoresScreen, ReviewModel
import 'location_selection_screen.dart'; // ระบบเลือกที่อยู่และการเข้าถึงตำแหน่ง (ตามข้อกำหนดที่ 3)
import 'reviews_page.dart';
import 'all_stores_screen.dart';
import 'store_detail_page.dart';

// ============================================================
// HOME SCREEN (Guest / ผู้ใช้ทั่วไป — ไม่มีแถบเมนูล่าง)
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = ApiConfig.baseUrl;

  String _selectedCategory = 'ทั้งหมด';
  String _currentLocation = '763R+7FQ ตำบล ขามเรียง มหาสารคาม';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = false;

  List<String> get _categories {
    final cats = <String>{'ทั้งหมด'};
    for (final t in _allFoodTrucks) {
      final c = (t['category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    return cats.toList();
  }

  List<Map<String, dynamic>> _allFoodTrucks = [];
  bool _isLoadingTrucks = true;

  @override
  void initState() {
    super.initState();
    _fetchFoodTrucks();
  }

  Future<void> _fetchFoodTrucks() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getFoodTrucks));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _allFoodTrucks = List<Map<String, dynamic>>.from(data['data'].map((item) {
              return {
                'id': item['id'].toString(),
                'title': item['name'],
                'category': item['type'] ?? 'สตรีทฟู้ด',
                'rating': item['rating']?.toString() ?? '5.0',
                'img': item['image_url'] ?? item['img'] ?? 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=200&auto=format&fit=crop',
                'isOpen': item['isOpen'] ?? (item['status'] != 'closed'),
                'status': item['status'] ?? 'เปิด',
                'distance': item['distance'] != null ? '${item['distance']} km' : '1.5 km',
                'distanceVal': double.tryParse(item['distance']?.toString() ?? '') ?? 1.5,
                'info': item['distance'] != null ? '${item['distance']} km' : '1.5 km',
                'openTime': item['open_time'] ?? item['openTime'] ?? '09:00 - 20:00',
                'shopType': item['type'] ?? 'สตรีทฟู้ด',
                'menus': item['items'] != null ? List<Map<String, dynamic>>.from(item['items'].map((m) => {
                  'name': m['name'],
                  'price': m['price'].toString(),
                  'img': m['image_url'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=200&auto=format&fit=crop',
                  'category': m['category'] ?? 'เมนูหลัก',
                  'optionGroups': [
                    {'title': 'ตัวเลือก (เลือก 1)', 'required': false, 'maxSelect': 1,
                     'options': [{'name': 'มาตรฐาน', 'price': 0}, {'name': 'พิเศษ', 'price': 10}]}
                  ],
                  'description': m['description'] ?? 'อร่อย สดใหม่'
                })) : [],
              };
            }));
            _isLoadingTrucks = false;
          });
          _syncStoreReviews();
          return;
        }
      }
    } catch (e) {
      print("Error fetching trucks in home_screen: $e");
    }
    setState(() => _isLoadingTrucks = false);
  }

  void _syncStoreReviews() {
    for (var truck in _allFoodTrucks) {
      final reviews = (truck['reviews'] as List<dynamic>?) ?? [];
      truck['reviewCount'] = reviews.length;
      if (reviews.isNotEmpty) {
        final avg = reviews.fold<double>(0.0, (sum, r) => sum + (double.tryParse(r['rating']?.toString() ?? '5') ?? 5.0)) / reviews.length;
        truck['rating'] = avg.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // 🔒 LOGIN CONFIRM (Safe exit popup)
  // ─────────────────────────────────────────
  void _showLoginConfirm({String title = 'สำหรับผู้เข้าสู่ระบบเท่านั้น'}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // ทำให้ pop up ขึ้นมาทับเมนูแถบล่าง (ตามข้อกำหนดที่ 1)
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(radius: 28, backgroundColor: Color(0xFFE5EEF5), child: Icon(Icons.person_add_outlined, size: 30, color: Color(0xFF00C7E6))),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('เข้าสู่ระบบเพื่อสั่งอาหารล่วงหน้า และเปิด Google Maps เดินไปรับที่หน้าร้านได้ทันที', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5)),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C7E6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
            onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
            child: const Text('เข้าสู่ระบบ / สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ไม่เป็นไร ขอดูร้านก่อน', style: TextStyle(color: Color(0xFF94A3B8)))),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🗺️ EXTERNAL MAPS
  // ─────────────────────────────────────────
  void _openExternalMaps(String storeName, String distance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.map_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('เปิด Google Maps: "$storeName" (ห่าง $distance)', style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: const Color(0xFF0B1A30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 📍 LOCATION PICKER (ตามข้อกำหนด 3)
  // ─────────────────────────────────────────
  void _showLocationPicker() {
    LocationService.openAddressSelector(context, (selectedAddr) {
      setState(() {
        _currentLocation = selectedAddr.replaceAll('\n', ' ').split(' - ').last;
        _allFoodTrucks.sort((a, b) => (a['distanceVal'] as double).compareTo(b['distanceVal'] as double));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตตำแหน่งแล้ว 📍'), backgroundColor: Color(0xFF10B981)));
    });
  }

  // ─────────────────────────────────────────
  // STORE DETAILS (guest mode)
  // ─────────────────────────────────────────
  void _showStoreDetails(Map<String, dynamic> truck) {
    final dummy = <String, int>{};
    final dummyP = <String, String>{};
    final dummyI = <String, String>{};

    Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailPage(
      truck: truck,
      isGuestMode: true,
      onNavigate: _openExternalMaps,
      cartQuantities: dummy,
      cartPrices: dummyP,
      cartImages: dummyI,
      onUpdateQuantity: (_, __, ___, ____, {StateSetter? modalSetter, String? storeTitle, String? optionsNote}) {},
      onViewReviews: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsPage(truck: truck, isGuestMode: true, canWriteReview: false))),
    )));
  }

  // ─────────────────────────────────────────
  // NAVIGATE TO ALL STORES
  // ─────────────────────────────────────────
  void _navigateToAllStores() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AllStoresScreen(
      allFoodTrucks: _allFoodTrucks,
      onStoreTap: _showStoreDetails,
      onNavigate: _openExternalMaps,
    )));
  }

  // ─────────────────────────────────────────
  // SORT: closed stores last
  // ─────────────────────────────────────────
  int _statusWeight(String status) {
    if (status == 'open') return 0;
    if (status == 'moving') return 1;
    return 2;
  }

  int _compareByStatus(Map a, Map b) {
    final sA = (a['status'] ?? 'open') as String;
    final sB = (b['status'] ?? 'open') as String;
    return _statusWeight(sA).compareTo(_statusWeight(sB));
  }

  // ─────────────────────────────────────────
  // ⚕️ STATUS BADGE
  // ─────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'closed':
        bg = const Color(0xFFEF4444);
        label = 'ปิด';
        break;
      case 'moving':
        bg = const Color(0xFFEAB308);
        label = 'กำลังย้าย';
        break;
      default:
        bg = const Color(0xFF10B981);
        label = 'เปิด';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentCat = _categories.contains(_selectedCategory) ? _selectedCategory : 'ทั้งหมด';
    final filtered = _allFoodTrucks.where((t) {
      final matchCat = currentCat == 'ทั้งหมด' || t['category'] == currentCat;
      final matchSearch = _searchQuery.isEmpty || (t['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList()
      ..sort(_compareByStatus);

    final topRated = List<Map<String, dynamic>>.from(_allFoodTrucks)
      ..sort((a, b) {
        final rA = double.tryParse(a['rating']?.toString() ?? '') ?? 0.0;
        final rB = double.tryParse(b['rating']?.toString() ?? '') ?? 0.0;
        return _sortAscending ? rA.compareTo(rB) : rB.compareTo(rA);
      })
      ..sort(_compareByStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _fetchFoodTrucks,
              child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 210),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header
                  Row(children: [
                    GestureDetector(
                      onTap: () => _showLoginConfirm(title: 'กรุณาเข้าสู่ระบบ\nเพื่อดูข้อมูลโปรไฟล์ของท่าน'),
                      child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE5EEF5), shape: BoxShape.circle), child: const Icon(Icons.person, color: Color(0xFF0B1A30), size: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showLocationPicker,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('ตำแหน่งปัจจุบัน (พื้นที่ค้นหาร้าน)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          Row(children: [
                            Flexible(child: Text(_currentLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)), overflow: TextOverflow.ellipsis, maxLines: 1)),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF0B1A30)),
                          ]),
                        ]),
                      ),
                    ),
                    _buildIconBtn(Icons.shopping_cart_outlined, onTap: () => _showLoginConfirm(title: 'เข้าสู่ระบบเพื่อใช้ตะกร้าสั่งล่วงหน้า')),
                    const SizedBox(width: 8),
                    _buildIconBtn(Icons.notifications_none_outlined, onTap: () => _showLoginConfirm(title: 'รับการแจ้งเตือนเมื่ออาหารพร้อม')),
                  ]),
                  const SizedBox(height: 20),

                  // ── Search
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อร้านในพื้นที่ของคุณ...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 17), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _categories.map((cat) {
                      final sel = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF00C7E6) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Text(cat, style: TextStyle(color: sel ? Colors.white : const Color(0xFF0B1A30), fontWeight: sel ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                        ),
                      );
                    }).toList()),
                  ),
                  const SizedBox(height: 22),

                  // ── Nearby stores
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('ร้านรถเข็นใกล้คุณ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                    GestureDetector(onTap: _navigateToAllStores, child: const Text('ดูทั้งหมด', style: TextStyle(fontSize: 12, color: Color(0xFF00C7E6), fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 195,
                    child: filtered.isEmpty
                        ? const Center(child: Text('ไม่พบร้านในหมวดนี้', style: TextStyle(color: Color(0xFF94A3B8))))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _buildNearbyCard(filtered[i]),
                          ),
                  ),
                  const SizedBox(height: 22),

                  // ── Top rated
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('⭐ ร้านยอดฮิต', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                    GestureDetector(
                      onTap: () => setState(() => _sortAscending = !_sortAscending),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFE5EEF5), shape: BoxShape.circle), child: Icon(_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 17, color: const Color(0xFF00C7E6))),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ...topRated.map((shop) => _buildTopRatedCard(shop)),
                ],
              ),
            ),
            ),

            // ── Banner ล่าง (เชิญสมัครสมาชิก)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('สมัครสมาชิก หรือ เข้าสู่ระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  const SizedBox(height: 6),
                  const Text('เพื่อสั่งอาหารออนไลน์ล่วงหน้า ไม่ต้องรอคิว\nรับแจ้งเตือนเมื่อเดินไปรับได้เลย!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C7E6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('สมัครสมาชิก / เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nearby card (องค์ประกอบตรงตามหน้า ร้านรถเข็นทั้งหมด)
  Widget _buildNearbyCard(Map<String, dynamic> truck) {
    final bool isClosed = truck['status'] == 'closed';
    final bool isMoving = truck['status'] == 'moving';
       return GestureDetector(
      onTap: isClosed
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ร้านนี้ปิดให้บริการอยู่ 🔒'), backgroundColor: Color(0xFF64748B)))
          // ลบเงื่อนไขเช็ก isMoving ออก เพื่อยอมให้กดเข้าไปดูรายละเอียดร้านได้
          : () => _showStoreDetails(truck),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(children: [
                Opacity(
                  opacity: isClosed ? 0.4 : 1.0,
                  child: Image.network(truck['img'], height: 95, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 95, color: const Color(0xFFF4F5F7), child: const Icon(Icons.storefront_outlined, size: 30, color: Color(0xFF94A3B8)))),
                ),
                Positioned(top: 6, left: 6, child: _buildStatusBadge(truck['status'] ?? 'open')),
                Positioned(top: 28, left: 6, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Color(0xFFFFB300), size: 10), const SizedBox(width: 2), Text('${truck['rating']} (${((truck['reviews'] as List?)?.length ?? truck['reviewCount'] ?? 0)})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)))]),
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(truck['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF0B1A30)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(truck['shopType'] ?? 'ร้านอาหารสตรีทฟู้ด', style: TextStyle(fontSize: 10.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 11, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF00C7E6)),
                    const SizedBox(width: 3),
                    Text('ห่าง ${truck['info']}', style: TextStyle(fontSize: 10.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 12, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(truck['openTime'], style: TextStyle(fontSize: 11, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF334155), fontWeight: isClosed ? FontWeight.normal : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top rated card (ดีไซน์เดียวกับหน้าหลักลูกค้า ตามข้อกำหนดที่ 2)
  Widget _buildTopRatedCard(Map<String, dynamic> shop) {
    final bool isClosed = shop['status'] == 'closed';
    final bool isMoving = shop['status'] == 'moving';
    String opTime = (shop['openTime'] ?? '09:00-18:00').toString().replaceAll('เริ่มขาย ', '').replaceAll(' น.', '');
    String revCount = (shop['reviewCount'] ?? '0').toString();
       return GestureDetector(
      onTap: isClosed
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ร้านนี้ปิดให้บริการอยู่ 🔒')))
          // ลบเงื่อนไขเช็ก isMoving ออก เพื่อยอมให้กดเข้าไปดูรายละเอียดร้านได้
          : () => _showStoreDetails(shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Opacity(
                    opacity: isClosed ? 0.4 : 1.0,
                    child: Image.network(shop['img'], width: 78, height: 78, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 78, height: 78, color: const Color(0xFFF4F5F7), child: const Icon(Icons.storefront, color: Color(0xFF94A3B8)))),
                  ),
                ),
                Positioned(top: 6, left: 6, child: _buildStatusBadge(shop['status'] ?? 'open')),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(shop['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF0B1A30)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(shop['shopType'] ?? 'ร้านอาหารสตรีทฟู้ด', style: TextStyle(fontSize: 11.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFFFFB300), size: 17),
                      const SizedBox(width: 3),
                      Text(shop['rating'], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF0B1A30))),
                      Text(' ($revCount)', style: TextStyle(fontSize: 11.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                      ),
                      Icon(Icons.location_on_rounded, size: 13, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF00C7E6)),
                      const SizedBox(width: 2),
                      Text(shop['info'], style: TextStyle(fontSize: 11.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                      ),
                      Icon(Icons.access_time_rounded, size: 13, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(opTime, style: TextStyle(fontSize: 11.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]), child: Icon(icon, color: const Color(0xFF0B1A30), size: 19)),
    );
  }
}
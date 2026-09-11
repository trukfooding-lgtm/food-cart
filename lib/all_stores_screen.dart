import 'package:flutter/material.dart';
// ============================================================
// ALL STORES SCREEN (2-column grid like 7-Eleven reference)
// ============================================================
class AllStoresScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allFoodTrucks;
  final Function(Map<String, dynamic>) onStoreTap;
  final Function(String, String) onNavigate;

  const AllStoresScreen({super.key, required this.allFoodTrucks, required this.onStoreTap, required this.onNavigate});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  String _selectedCategory = 'ทั้งหมด';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> get _categories {
    final cats = <String>{'ทั้งหมด'};
    for (final t in widget.allFoodTrucks) {
      final c = (t['category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    return cats.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = _categories.contains(_selectedCategory) ? _selectedCategory : 'ทั้งหมด';
    final filtered = widget.allFoodTrucks.where((t) {
      final matchCat = currentCat == 'ทั้งหมด' || t['category'] == currentCat;
      final matchSearch = _searchQuery.isEmpty || (t['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList()
      ..sort(_compareByStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('ร้านรถเข็นทั้งหมด', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // ── Search + Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อร้านในพื้นที่...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                  filled: true, fillColor: const Color(0xFFF4F7FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _categories.map((cat) {
                  final sel = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF00C7E6) : const Color(0xFFF4F7FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat, style: TextStyle(color: sel ? Colors.white : const Color(0xFF0B1A30), fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                    ),
                  );
                }).toList()),
              ),
            ]),
          ),

          // ── Grid list
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('ไม่พบร้านค้าที่ตรงกับการกรอง', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildStoreGridCard(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGridCard(Map<String, dynamic> shop) {
    final bool isClosed = shop['status'] == 'closed';
    final bool isMoving = shop['status'] == 'moving';
    return GestureDetector(
      onTap: isClosed
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ร้านนี้ปิดให้บริการอยู่ 🔒'), backgroundColor: Color(0xFF64748B)))
          // ลบเงื่อนไขเช็ก isMoving ออก เพื่อยอมให้กดเข้าไปดูรายละเอียดร้านได้
          : () => widget.onStoreTap(shop),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(children: [
                Opacity(
                  opacity: isClosed ? 0.4 : 1.0,
                  child: Image.network(shop['img'], height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 130, color: const Color(0xFFF4F5F7), child: const Icon(Icons.storefront, size: 40, color: Color(0xFF94A3B8)))),
                ),
                // ── แถบสถานะร้านและคะแนนต้องอยู่ทางด้านซ้าย ตามข้อกำหนด 4
                Positioned(top: 8, left: 8, child: _buildStatusBadge(shop['status'] ?? 'open')),
                Positioned(top: 36, left: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 12), const SizedBox(width: 2), Text('${shop['rating']} (${((shop['reviews'] as List?)?.length ?? shop['reviewCount'] ?? 0)})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)))]),
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF0B1A30)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(shop['shopType'], style: TextStyle(fontSize: 11, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 12, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF00C7E6)),
                    const SizedBox(width: 3),
                    Text('ห่าง ${shop['info']}', style: TextStyle(fontSize: 11, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 12, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(shop['openTime'], style: TextStyle(fontSize: 11, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF334155), fontWeight: isClosed ? FontWeight.normal : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

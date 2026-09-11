import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'buyer_home_screen.dart'; 
import 'refund_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api.config.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> allFoodTrucks;
  final Function(String, String)? onNavigate;
  final VoidCallback? onConfirmReceive;

  const OrderDetailScreen({super.key, required this.order, required this.allFoodTrucks, this.onNavigate, this.onConfirmReceive});

  @override //copy
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();

}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Timer? _timer;
  String _orderStatus = 'กำลังทำ'; 
  bool _hasShownCancelPopup = false;

  int get _currentStageIndex {
    final status = _orderStatus.trim();
    if (status == 'รับอาหารสำเร็จแล้ว' || status == 'สำเร็จ' || status == 'รับอาหารแล้ว' || widget.order['isCompleted'] == true) return 3;
    if (status == 'พร้อมรับ' || status == 'อาหารเสร็จแล้ว') return 2;
    if (status == 'รอร้านค้าตอบรับ' || status == 'รอชำระเงิน' || status == 'รอรับออเดอร์' || status == 'รอร้านรับคำสั่งซื้อ') return 0;
    if (status == 'กำลังทำ' ||
        status == 'กำลังปรุงอาหาร' ||
        status == 'กำลังจัดเตรียม' ||
        status == 'กำลังจัดเตรียมอาหาร' ||
        status == 'รับคำสั่งซื้อ' ||
        status == 'ร้านรับออเดอร์' ||
        status == 'รับออเดอร์แล้ว' ||
        status == 'รับออเดอร์' ||
        status == 'ร้านค้ารับคำสั่งซื้อแล้ว' ||
        status == 'ร้านค้ารับออเดอร์แล้ว') return 1;
    return 0;
  }

  Future<void> _fetchLatestOrderStatus() async {
    final rawOrderId = widget.order['order_id'] ?? widget.order['id'];
    if (rawOrderId == null) return;
    final String orderId = rawOrderId.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (orderId.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId'));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final String newStatus = resData['data']['status']?.toString().trim() ?? '';
          if (newStatus.isNotEmpty && mounted) {
            setState(() {
              _orderStatus = newStatus;
              widget.order['status'] = newStatus;
              if (newStatus == 'รับอาหารสำเร็จแล้ว') {
                widget.order['isCompleted'] = true;
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error polling order: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _orderStatus = widget.order['status']?.toString().trim() ?? 'กำลังทำ';
    _fetchLatestOrderStatus();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchLatestOrderStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // 1. จำลองเวลาสั่งซื้อและเวลาชำระเงินเป็นปัจจุบันเป๊ะๆ
    // 🔴 เพิ่ม 4 บรรทัดนี้เข้าไป เพื่อดึงค่าจากตัวแปรเดิมมาใช้งาน
    final order = widget.order;
    final allFoodTrucks = widget.allFoodTrucks;
    final onNavigate = widget.onNavigate;
    final onConfirmReceive = widget.onConfirmReceive;
    final now = DateTime.now();
    final months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final String realDateStr = '${now.day} ${months[now.month - 1]} ${now.year + 543} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // 2. จำลองเวลาเตรียมอาหาร (นับจากปัจจุบันไปอีก 15 นาที)
    final prepEnd = now.add(const Duration(minutes: 15));
    final String prepTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}-${prepEnd.hour.toString().padLeft(2, '0')}:${prepEnd.minute.toString().padLeft(2, '0')}';

    final pickupCode = (order['id'] as String?) ?? '#GF-4374';
    final fullOrderId = (order['fullOrderId'] as String?) ?? 'ORD-20260806-${pickupCode.replaceAll(RegExp(r'[^0-9]'), '')}';
    final storeTitle = (order['storeTitle'] as String?) ?? 'ร้านค้าของฉัน';
    
    // ใช้เวลาปัจจุบัน ถ้ามันเป็นออเดอร์ใหม่
    final dateStr = (order['date'] == null || order['date'] == '27 ก.ค. 2026 22:37') ? realDateStr : order['date'];
    
    // เช็กสถานะว่ารับอาหารสำเร็จหรือยัง
    final bool isCompleted = order['isCompleted'] == true;

    final truck = allFoodTrucks.firstWhere((t) => t['title'] == storeTitle, orElse: () => allFoodTrucks.isNotEmpty ? allFoodTrucks.first : {'info': '1.0 km', 'menu': []});
    final distance = (truck['info'] as String?) ?? '0.8 km';
    final storeMenu = (truck['menu'] as List?) ?? [];

    final List items = ((order['items'] as List?)?.isNotEmpty == true)
        ? (order['items'] as List)
        : (storeMenu.isNotEmpty)
            ? [
                {
                  'name': storeMenu.first['name'] ?? 'อเมริกาโน่เย็น',
                  'qty': 1,
                  'price': storeMenu.first['price'] ?? '65',
                  'img': storeMenu.first['img'] ?? 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&q=80&w=300',
                  'note': 'ขนาด M (16 oz) • หวานปกติ (100%)',
                }
              ]
            : [
                {
                  'name': 'อเมริกาโน่เย็น',
                  'qty': 1,
                  'price': '65',
                  'img': 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&q=80&w=300',
                  'note': 'ขนาด M (16 oz) • หวานปกติ (100%)',
                }
              ];

    // คำนวณยอดชำระทั้งหมดตามจริงจากราคาและจำนวนของแต่ละรายการ
    double calculatedTotal = 0;
    for (final item in items) {
      final int qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      // แก้ไขบัคราคารวมเพี้ยน: อนุญาตให้มีจุดทศนิยม (.) ได้
      final String priceStr = (item['price']?.toString() ?? '0').replaceAll(RegExp(r'[^0-9.]'), '');
      final double unitPrice = double.tryParse(priceStr) ?? 0.0;
      calculatedTotal += (unitPrice * qty);
    }
    
    // แปลงให้เป็นรูปแบบมีลูกน้ำ (comma) ขั้นหลักพัน และมีทศนิยม 2 ตำแหน่ง
    String formattedTotal = calculatedTotal.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    
    final String totalPrice = (calculatedTotal > 0) ? '฿$formattedTotal' : ((order['totalPrice'] as String?) ?? '฿65.00');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0B1A30)),
                      ),
                    ),
                  ),
                  const Text('รายละเอียดคำสั่งซื้อ', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.w800, fontSize: 21)),
                ],
              ),
            ),

            // ── Main Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00C7E6),
                onRefresh: _fetchLatestOrderStatus,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // ── Card 1: Order Status & 4-Stage Tracker
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: const Color(0xFF0D1B2A).withAlpha(12), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('รหัสรับอาหาร:', style: TextStyle(color: Color(0xFF475569), fontSize: 14.5, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                                  child: Text(pickupCode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0284C7))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentStageIndex >= 3
                                  ? 'รับอาหารสำเร็จเรียบร้อย 🎉'
                                  : (_currentStageIndex == 2
                                      ? 'อาหารของคุณพร้อมรับแล้ว!'
                                      : (_currentStageIndex == 1
                                          ? 'ร้านค้ากำลังจัดเตรียมอาหารให้คุณ 👨‍🍳'
                                          : 'ร้านค้ารับคำสั่งซื้อแล้ว 📋')),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18.5, color: Color(0xFF00C7E6)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(isCompleted ? 'เวลารับอาหาร: ' : 'อาหารพร้อมรับใน: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14.5)),
                                Text(isCompleted ? dateStr : prepTime, style: const TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.w800, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildFourStageTracker(),
                            const SizedBox(height: 22),
                            Center(
                              child: Text(
                                _currentStageIndex >= 3
                                    ? 'ขอบคุณที่ใช้บริการ\nหวังว่าคุณจะเพลิดเพลินกับมื้ออาหารมื้อนี้'
                                    : (_currentStageIndex == 2
                                        ? 'อาหารของคุณปรุงเสร็จแล้ว กรุณาไปรับที่หน้าร้าน\nและกด "ยืนยันการรับอาหาร" ด้านล่าง'
                                        : 'เราจะแจ้งให้คุณทราบเมื่ออาหารของคุณ\nพร้อมรับ'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14.5, height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Card 2: Store, Summary & Total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: const Color(0xFF0D1B2A).withAlpha(12), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Header
                          // Store Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.storefront, color: Color(0xFF00C7E6), size: 26),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🟢 บรรทัดบน: ชื่อร้าน และ ปุ่มแผนที่
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(storeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B1A30)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            if (onNavigate != null) onNavigate!(storeTitle, distance);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(18)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.location_on, size: 14, color: Colors.white),
                                                SizedBox(width: 2),
                                                Text('แผนที่', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // 🟢 บรรทัดล่าง: ปุ่ม โทร, เฟส, ไลน์ (ใช้ Wrap เพื่อให้ปุ่มเรียงกันสวยๆ ด้านล่างชื่อร้าน)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final uri = Uri.parse('tel:0812345678');
                                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: const Color(0xFFE5EEF5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00C7E6).withAlpha(100))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.phone, color: Color(0xFF00C7E6), size: 14),
                                                SizedBox(width: 4),
                                                Text('โทร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final uri = Uri.parse('https://m.facebook.com/wongnai');
                                            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF0088CC).withAlpha(100))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.facebook, color: Color(0xFF0088CC), size: 14),
                                                SizedBox(width: 4),
                                                Text('เฟส', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0088CC))),
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final uri = Uri.parse('https://line.me/ti/p/~@wongnai');
                                            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: const Color(0xFFE6F8F3), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF10B981).withAlpha(100))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.chat_bubble, color: Color(0xFF10B981), size: 14),
                                                SizedBox(width: 4),
                                                Text('ไลน์', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('สรุปคำสั่งซื้อ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Color(0xFF0B1A30))),
                          const SizedBox(height: 16),

                          // ── Items List (แสดง ภาพ, ชื่อ, รายการย่อย, ราคา)
                          ...items.map((item) {
                            final name = (item['name']?.toString() ?? 'อเมริกาโน่เย็น');
                            final qty = (item['qty'] != null) ? item['qty'].toString() : '1';
                            final int intQty = int.tryParse(qty) ?? 1;
                            final priceRaw = (item['price']?.toString() ?? '65');
                            final double unitPriceVal = double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                            final double lineTotalVal = unitPriceVal * intQty;
                            final String formattedLineTotal = lineTotalVal.toStringAsFixed(lineTotalVal.truncateToDouble() == lineTotalVal ? 0 : 2);
                            final rawNote = (item['note']?.toString() ?? item['subItems']?.toString() ?? item['options']?.toString() ?? '').trim();
                            final subItemText = rawNote.isNotEmpty ? rawNote : 'ขนาด M (16 oz) • หวานปกติ (100%)';

                            String img = (item['img']?.toString() ?? '');
                            if (img.isEmpty || !img.startsWith('http')) {
                              final matched = storeMenu.firstWhere((m) => m['name'] == name, orElse: () => storeMenu.isNotEmpty ? storeMenu.first : null);
                              if (matched != null && matched['img'] != null && matched['img'].toString().startsWith('http')) {
                                img = matched['img'].toString();
                              } else {
                                img = 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&q=80&w=300';
                              }
                            }

                          // ── โค้ดที่ปรับขนาดให้เล็กลงแล้ว ──
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(10), // ลดระยะขอบด้านใน
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. ภาพสินค้า (ลดขนาดลงเหลือ 60x60)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.5),
                                      child: Image.network(
                                        img,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: const Icon(Icons.fastfood, color: Color(0xFF94A3B8), size: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // ข้อมูลสินค้า (ชื่อ, รายการย่อย, ราคา, จำนวน)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 2. ชื่อสินค้า (Name) & จำนวน
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0B1A30)), // ลดฟอนต์ชื่อ
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text('x$qty', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // 3. รายการย่อย (Sub-items / Options)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                ' $subItemText',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600, height: 1.35), // ลดฟอนต์ตัวเลือกย่อย
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // 4. ราคา (Price)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '฿$formattedLineTotal',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF00C7E6)), // ลดฟอนต์ราคา
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),
                          
                          // ── รายละเอียดเพิ่มเติมของคำสั่งซื้อ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('รหัสคำสั่งซื้อ', style: TextStyle(color: Color(0xFF475569), fontSize: 14.5)),
                              Text(fullOrderId, style: const TextStyle(color: Color(0xFF334155), fontSize: 14.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('เวลาคำสั่งซื้อ', style: TextStyle(color: Color(0xFF475569), fontSize: 14.5)),
                              Text(dateStr, style: const TextStyle(color: Color(0xFF334155), fontSize: 14.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('เวลาการชำระเงิน', style: TextStyle(color: Color(0xFF475569), fontSize: 14.5)),
                              Text(dateStr, style: const TextStyle(color: Color(0xFF334155), fontSize: 14.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('การชำระเงิน', style: TextStyle(color: Color(0xFF475569), fontSize: 14.5)),
                              Text('QR Code (พร้อมเพย์)', style: TextStyle(color: Color(0xFF334155), fontSize: 14.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('การตั้งค่าสำหรับสินค้าที่หมด', style: TextStyle(color: Color(0xFF475569), fontSize: 14.5)),
                              Expanded(
                                child: Text(
                                  (order['outOfStockOption'] as String?) ?? 'ติดต่อฉัน',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Color(0xFF334155), fontSize: 14.5, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 20),

                          // ── ยอดชำระทั้งหมด
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดชำระทั้งหมด', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0B1A30))),
                              Text(totalPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFF00C7E6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          if (!isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: _currentStageIndex == 2
                          ? [BoxShadow(color: const Color(0xFF00C7E6).withAlpha(120), blurRadius: 18, offset: const Offset(0, 6))]
                          : [],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStageIndex == 2 ? const Color(0xFF00C7E6) : const Color(0xFFCBD5E1),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      onPressed: _currentStageIndex == 2 ? () async { 
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6))),
                        );

                        try {
                          final String idStr = order['id'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                          final int realOrderId = int.tryParse(idStr) ?? 0;

                          final url = Uri.parse('${ApiConfig.baseUrl}/api/orders/$realOrderId/complete');
                          final response = await http.put(url);

                          if (!mounted) return;
                          Navigator.pop(context);

                          if (response.statusCode == 200) {
                            setState(() {
                              _orderStatus = 'รับอาหารสำเร็จแล้ว';
                              order['isCompleted'] = true;
                              order['status'] = 'รับอาหารสำเร็จแล้ว';
                            });

                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            buyerHomeKey.currentState?.switchTab(1);
                            widget.onConfirmReceive?.call();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: ${response.body}')));
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                          }
                        }
                      } : null,
                      child: Text(
                        _currentStageIndex >= 3
                            ? 'รับอาหารสำเร็จแล้ว'
                            : (_currentStageIndex == 2
                                ? 'ยืนยันการรับอาหาร'
                                : 'รอร้านค้าเตรียมอาหาร...'),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ), 
                  ),
                ),
              ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  label: const Text('กลับสู่หน้ารายการคำสั่งซื้อ', style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    buyerHomeKey.currentState?.switchTab(1);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFourStageTracker() {
    const Color activeColor = Color(0xFF00C7E6); 
    const Color inactiveColor = Color(0xFFE2E8F0);
    const Color inactiveIconColor = Color(0xFF94A3B8);
    final stage = _currentStageIndex;

    return Stack(
      children: [
        Positioned(
          top: 17, 
          left: 0,
          right: 0,
          child: Row(
            children: [
              const Spacer(flex: 1),
              Expanded(
                flex: 2, 
                child: Container(height: 4, color: stage >= 1 ? activeColor : inactiveColor),
              ),
              Expanded(
                flex: 2, 
                child: stage >= 2
                    ? Container(height: 4, color: activeColor)
                    : (stage == 1
                        ? SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(activeColor),
                              backgroundColor: inactiveColor,
                            ),
                          )
                        : Container(height: 4, color: inactiveColor)),
              ),
              Expanded(
                flex: 2, 
                child: Container(height: 4, color: stage >= 3 ? activeColor : inactiveColor),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStageColumn(Icons.assignment_turned_in, 'รับคำสั่งซื้อ', activeColor, Colors.white, false, stage == 0)),
            Expanded(child: _buildStageColumn(Icons.soup_kitchen_rounded, 'กำลังทำ', stage >= 1 ? activeColor : Colors.white, stage >= 1 ? Colors.white : inactiveIconColor, stage < 1, stage == 1)),
            Expanded(child: _buildStageColumn(Icons.moped_rounded, 'พร้อมรับ', stage >= 2 ? activeColor : Colors.white, stage >= 2 ? Colors.white : inactiveIconColor, stage < 2, stage == 2)),
            Expanded(child: _buildStageColumn(Icons.takeout_dining, 'รับอาหารสำเร็จ', stage >= 3 ? activeColor : Colors.white, stage >= 3 ? Colors.white : inactiveIconColor, stage < 3, stage >= 3)),
          ],
        ),
      ],
    );
  }

  // วิดเจ็ตแพ็กเกจ ไอคอน+ข้อความ (รับประกันว่าข้อความจะอยู่ใต้ไอคอนตรงเป๊ะเสมอ)
  Widget _buildStageColumn(IconData icon, String text, Color bgColor, Color iconColor, bool hasBorder, bool isActiveText) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: hasBorder ? Border.all(color: const Color(0xFFCBD5E1), width: 1.5) : null,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isActiveText ? const Color(0xFF0B1A30) : (bgColor == Colors.white ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            fontWeight: isActiveText ? FontWeight.w800 : (bgColor == Colors.white ? FontWeight.w500 : FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // วิดเจ็ตสร้างเส้นเชื่อมปกติ
  Widget _buildTrackerLine(Color color) {
    return Expanded(
      child: Container(
        height: 4,
        color: color,
      ),
    );
  }

  // วิดเจ็ตสร้างเส้นเชื่อมแบบ Loading (แถบวิ่ง)
  Widget _buildAnimatedTrackerLine(Color activeColor, Color bgColor) {
    return Expanded(
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          backgroundColor: bgColor,
        ),
      ),
    );
  }
  Widget _buildContactIcon(IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }


}
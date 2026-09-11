import 'package:flutter/material.dart';
import 'buyer_home_screen.dart'; // เพื่อเรียกใช้คลาส CheckoutScreen ในเวลาที่กดปุ่มชำระเงิน
import 'reviews_page.dart';
import 'checkout_screen.dart';
import 'store_detail_page.dart';
// ============================================================
// MY CART SCREEN (รถเข็นของฉัน — แยกระหว่างร้านเด็ดขาด ตามข้อกำหนดที่ 6)
// ============================================================
class MyCartScreen extends StatefulWidget {
  final Map<String, int> cartQuantities;
  final Map<String, String> cartPrices;
  final Map<String, String> cartImages;
  final Map<String, String> cartStores;
  final Map<String, String> cartOptions;
  final List<Map<String, dynamic>> allFoodTrucks;
  final Function(String, String, String, int, {StateSetter? modalSetter, String? storeTitle, String? optionsNote}) onUpdateQuantity;
  final Function(String storeTitle) onClearStoreCart;

  const MyCartScreen({
    super.key,
    required this.cartQuantities,
    required this.cartPrices,
    required this.cartImages,
    required this.cartStores,
    required this.cartOptions,
    required this.allFoodTrucks,
    required this.onUpdateQuantity,
    required this.onClearStoreCart,
  });

  @override
  State<MyCartScreen> createState() => _MyCartScreenState();
}

class _MyCartScreenState extends State<MyCartScreen> {
  String? _editingStoreTitle;

  void _showEditItemModal(String name, String price, String img, int qty, String currentNote, String storeTitle) {
    final noteController = TextEditingController(text: currentNote);
    int tempQty = qty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('อัปเดตรายการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                  IconButton(icon: const Icon(Icons.close, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(img, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: const Color(0xFFF4F5F7), child: const Icon(Icons.fastfood_outlined, color: Color(0xFF94A3B8)))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                        const SizedBox(height: 8),
                        Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () { if (tempQty > 1) setModal(() => tempQty--); },
                              child: Container(width: 34, height: 34, decoration: BoxDecoration(color: tempQty > 1 ? const Color(0xFF00C7E6) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.remove, color: tempQty > 1 ? Colors.white : const Color(0xFF94A3B8), size: 18)),
                            ),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$tempQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)))),
                            GestureDetector(
                              onTap: () => setModal(() => tempQty++),
                              child: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, color: Colors.white, size: 18)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('ปรับปรุงตัวเลือกเดิมของคุณ:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'ตัวเลือกเพิ่มเติม / หมายเหตุอาหาร',
                  hintText: 'เช่น เผ็ดน้อย ไม่ใส่ชูรส',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true, fillColor: const Color(0xFFF4F7FA),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C7E6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  onPressed: () {
                    setState(() {
                      widget.cartOptions[name] = noteController.text;
                      widget.onUpdateQuantity(name, price, img, tempQty, storeTitle: storeTitle, optionsNote: noteController.text);
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกการแก้ไขเรียบร้อยแล้ว ✅'), backgroundColor: Color(0xFF10B981), duration: Duration(seconds: 2)));
                  },
                  child: const Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> storeGroups = {};
    for (var menuName in widget.cartQuantities.keys) {
      final storeTitle = widget.cartStores[menuName] ?? (widget.allFoodTrucks.isNotEmpty ? widget.allFoodTrucks.first['title'] as String : 'ร้านสตรีทฟู้ด');
      storeGroups.putIfAbsent(storeTitle, () => []).add(menuName);
    }

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
        title: const Text('รถเข็นของฉัน', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      body: widget.cartQuantities.isEmpty
          ? const Center(child: Text('ไม่มีสินค้าในตะกร้า 🛒\nเลือกชมร้านรถเข็นใกล้คุณเพื่อสั่งอาหารได้เลย!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, height: 1.5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: storeGroups.entries.map((entry) {
                  final storeTitle = entry.key;
                  final itemNames = entry.value;
                  int storeTotal = 0;
                  for (final name in itemNames) {
                    final priceVal = (double.tryParse((widget.cartPrices[name] ?? '0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0).toInt();
                    storeTotal += priceVal * (widget.cartQuantities[name] ?? 0);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Builder(builder: (context) {
                      final truck = widget.allFoodTrucks.firstWhere(
                        (t) => t['title'] == storeTitle,
                        orElse: () => widget.allFoodTrucks.isNotEmpty ? widget.allFoodTrucks.first : <String, dynamic>{},
                      );
                      final String storeImg = truck.isNotEmpty && truck['img'] != null ? truck['img'] : 'https://cdn-icons-png.flaticon.com/128/1046/1046784.png';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront, color: Color(0xFF00C7E6), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (truck.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StoreDetailPage(
                                            truck: truck,
                                            isGuestMode: false,
                                            onNavigate: (title, dist) {},
                                            allFoodTrucks: widget.allFoodTrucks,
                                            cartQuantities: widget.cartQuantities,
                                            cartPrices: widget.cartPrices,
                                            cartImages: widget.cartImages,
                                            cartStores: widget.cartStores,
                                            cartOptions: widget.cartOptions,
                                            onUpdateQuantity: widget.onUpdateQuantity,
                                            onViewReviews: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ReviewsPage(
                                                    truck: truck,
                                                    isGuestMode: false,
                                                  ),
                                                ),
                                              );
                                            },
                                            onClearCart: (s) => widget.onClearStoreCart(s),
                                          ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          storeTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Color(0xFF0B1A30), decoration: TextDecoration.none),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_editingStoreTitle == storeTitle) {
                                      _editingStoreTitle = null;
                                    } else {
                                      _editingStoreTitle = storeTitle;
                                    }
                                  });
                                },
                                child: Text(_editingStoreTitle == storeTitle ? 'เสร็จสิ้น' : 'แก้ไข', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                              ),
                            ],
                          ),
                        const SizedBox(height: 14),
                        ...itemNames.map((name) {
                          final qty = widget.cartQuantities[name] ?? 1;
                          final price = widget.cartPrices[name] ?? '฿0';
                          final img = widget.cartImages[name] ?? '';
                          final opt = widget.cartOptions[name] ?? 'รสชาติมาตรฐาน';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    img, width: 56, height: 56, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: const Color(0xFFF4F5F7), child: const Icon(Icons.fastfood, color: Color(0xFF94A3B8), size: 20)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1A30)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(opt, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('x$qty', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                                    ],
                                  ),
                                ),
                                if (_editingStoreTitle == storeTitle) ...[
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        widget.onUpdateQuantity(name, price, img, 0, storeTitle: storeTitle, optionsNote: opt);
                                      });
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 56,
                                      decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(10)),
                                      alignment: Alignment.center,
                                      child: const Text('ลบ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text('ราคารวม ', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                Text('฿$storeTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C7E6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      cartQuantities: widget.cartQuantities,
                                      cartPrices: widget.cartPrices,
                                      cartImages: widget.cartImages,
                                      cartStores: widget.cartStores,
                                      cartOptions: widget.cartOptions,
                                      allFoodTrucks: widget.allFoodTrucks,
                                      storeTitle: storeTitle,
                                      onUpdateQuantity: widget.onUpdateQuantity,
                                      onClearCart: () => widget.onClearStoreCart(storeTitle),
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              child: const Text('สั่งอาหาร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5)),
                            ),
                          ],
                        ),
                      ],
                    );
                    }),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
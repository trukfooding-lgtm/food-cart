import 'package:flutter/material.dart';
import 'buyer_home_screen.dart';
import 'reviews_page.dart';
import 'order_detail_screen.dart';
import 'store_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.config.dart';
import 'waiting_order_screen.dart'; // อิมพอร์ตหน้าจอใหม่
// ============================================================
// CHECKOUT SCREEN (หน้ายืนยันคำสั่งซื้อรายร้าน — สไตล์ Shopee Food / Lineman)
// ============================================================
class CheckoutScreen extends StatefulWidget {
  final Map<String, int> cartQuantities;
  final Map<String, String> cartPrices;
  final Map<String, String> cartImages;
  final Map<String, String>? cartStores;
  final Map<String, String>? cartOptions;
  final List<Map<String, dynamic>>? allFoodTrucks;
  final String storeTitle;
  final Function(String, String, String, int, {StateSetter? modalSetter, String? storeTitle, String? optionsNote}) onUpdateQuantity;
  final VoidCallback onClearCart;

  const CheckoutScreen({
    super.key,
    required this.cartQuantities,
    required this.cartPrices,
    required this.cartImages,
    this.cartStores,
    this.cartOptions,
    this.allFoodTrucks,
    required this.storeTitle,
    required this.onUpdateQuantity,
    required this.onClearCart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  String _outOfStockOption = 'ติดต่อฉัน';
  String _selectedPaymentMethod = 'ชำระด้วยเงินสด';

  void _showPaymentMethodModal() {
    String tempSelected = _selectedPaymentMethod;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final options = [
            {
              'title': 'ชำระด้วยเงินสด',
              'desc': 'เตรียมเงินสดชำระกับร้านค้า ณ จุดรับสินค้า',
              'icon': Icons.payments_outlined,
            },
            {
              'title': 'สแกน QR PromptPay',
              'desc': 'โอนง่าย รวดเร็ว ไม่ต้องทอนเงิน',
              'icon': Icons.qr_code_scanner,
            },
            {
              'title': 'ตัดผ่านบัตรเครดิต/เดบิต',
              'desc': 'สะดวก รวดเร็ว ปลายทางพร้อมเสิร์ฟ',
              'icon': Icons.credit_card_outlined,
            },
          ];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('วิธีการชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                    IconButton(icon: const Icon(Icons.close, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('เลือกช่องทางชำระเงินที่คุณต้องการ ณ จุดรับอาหาร:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final sel = tempSelected == opt['title'];
                  return GestureDetector(
                    onTap: () => setModal(() => tempSelected = opt['title'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFE5EEF5) : const Color(0xFFFAFCFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sel ? const Color(0xFF00C7E6) : const Color(0xFFE2E8F0), width: sel ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(opt['icon'] as IconData, color: sel ? const Color(0xFF00C7E6) : const Color(0xFF64748B), size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt['title'] as String, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.w600, fontSize: 15, color: const Color(0xFF0B1A30))),
                                const SizedBox(height: 3),
                                Text(opt['desc'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? const Color(0xFF00C7E6) : const Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7E6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() => _selectedPaymentMethod = tempSelected);
                      Navigator.pop(ctx);
                    },
                    child: const Text('เลือก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> get _storeItems {
    return widget.cartQuantities.keys.where((k) {
      final s = widget.cartStores?[k] ?? widget.storeTitle;
      return s == widget.storeTitle;
    }).toList();
  }

  int get _totalItems {
    int sum = 0;
    for (var k in _storeItems) {
      sum += (widget.cartQuantities[k] ?? 0);
    }
    return sum;
  }

  int get _totalPrice {
    int total = 0;
    for (var k in _storeItems) {
      final count = widget.cartQuantities[k] ?? 0;
      final pStr = widget.cartPrices[k]?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
      total += ((double.tryParse(pStr) ?? 0).toInt()) * count;
    }
    return total;
  }

  void _showOutOfStockModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final opts = ['ติดต่อฉัน', 'ยกเลิกคำสั่งซื้อ'];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('การตั้งค่ากรณีสินค้าบางรายการหมด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              const SizedBox(height: 6),
              const Text('โปรดเลือกวิธีที่คุณต้องการให้ร้านดำเนินการหากวัตถุดิบบางรายการหมด:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ...opts.map((opt) {
                final sel = _outOfStockOption == opt;
                return ListTile(
                  onTap: () {
                    setState(() => _outOfStockOption = opt);
                    Navigator.pop(context);
                  },
                  leading: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? const Color(0xFF00C7E6) : const Color(0xFF94A3B8)),
                  title: Text(opt, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF0B1A30))),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showEditItemModal(String name, String price, String img, int qty, String currentNote) {
    int tempQty = qty;
    final int basePrice = (double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0).toInt();

    List<Map<String, dynamic>> optionGroups = [];
    String soldCount = '';
    if (widget.allFoodTrucks != null && widget.allFoodTrucks!.isNotEmpty) {
      final truck = widget.allFoodTrucks!.firstWhere((t) => t['title'] == widget.storeTitle, orElse: () => <String, dynamic>{});
      if (truck.isNotEmpty) {
        final List menus = truck['menus'] ?? [];
        Map<String, dynamic>? menu;
        for (var m in menus) {
          if (m['name'] == name) {
            menu = m;
            break;
          }
        }
        if (menu != null) {
          optionGroups = List<Map<String, dynamic>>.from(menu['optionGroups'] ?? []);
          soldCount = (menu['soldCount'] as String?) ?? '';
        }
      }
    }

    final List<String> currentOpts = currentNote.split(', ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final Map<int, Set<int>> selectedOpts = {};
    for (int i = 0; i < optionGroups.length; i++) {
      selectedOpts[i] = {};
      final grp = optionGroups[i];
      final opts = List<Map<String, dynamic>>.from(grp['options'] as List);
      for (int oi = 0; oi < opts.length; oi++) {
        if (currentOpts.contains(opts[oi]['name'])) {
          selectedOpts[i]!.add(oi);
          currentOpts.remove(opts[oi]['name']);
        }
      }
    }
    final noteController = TextEditingController(text: currentOpts.join(', '));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setModal) {
        
        int extraPrice = 0;
        selectedOpts.forEach((gi, optSet) {
          for (final oi in optSet) {
            extraPrice += (optionGroups[gi]['options'] as List)[oi]['price'] as int;
          }
        });
        final int totalPrice = (basePrice + extraPrice) * tempQty;

        bool allRequiredSelected = true;
        for (int i = 0; i < optionGroups.length; i++) {
          final grp = optionGroups[i];
          if (grp['required'] == true && (selectedOpts[i]?.isEmpty ?? true)) {
            allRequiredSelected = false;
            break;
          }
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                // ── Title bar
                Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Text('อัปเดตรายการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 1),

                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(0),
                    children: [
                      // ── Item header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(img, width: 90, height: 90, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: const Color(0xFFF4F5F7),
                                      child: const Icon(Icons.fastfood_outlined, color: Color(0xFF94A3B8)))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                                  if (soldCount.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(soldCount, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                  ],
                                  const SizedBox(height: 8),
                                  Text('฿${basePrice + extraPrice}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
                                  const SizedBox(height: 10),
                                  // ── Qty stepper
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setModal(() { if (tempQty > 1) tempQty--; }),
                                        child: Container(
                                          width: 34, height: 34,
                                          decoration: BoxDecoration(
                                            color: tempQty > 1 ? const Color(0xFF00C7E6) : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.remove, color: tempQty > 1 ? Colors.white : const Color(0xFF94A3B8), size: 18),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text('$tempQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                                      ),
                                      GestureDetector(
                                        onTap: () => setModal(() => tempQty++),
                                        child: Container(
                                          width: 34, height: 34,
                                          decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (optionGroups.isNotEmpty) ...List.generate(optionGroups.length, (gi) {
                        final grp = optionGroups[gi];
                        final title = grp['title'] as String;
                        final maxSelect = grp['maxSelect'] as int;
                        final required = grp['required'] == true;
                        final opts = List<Map<String, dynamic>>.from(grp['options'] as List);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              color: const Color(0xFFF4F7FA),
                              child: Text(
                                '$title${required ? ' (ต้องระบุ)' : ''}', 
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))
                              ),
                            ),
                            ...List.generate(opts.length, (oi) {
                              final opt = opts[oi];
                              final optName = opt['name'] as String;
                              final optPrice = opt['price'] as int;
                              final isSelected = selectedOpts[gi]?.contains(oi) ?? false;

                              return GestureDetector(
                                onTap: () {
                                  setModal(() {
                                    final set = selectedOpts[gi]!;
                                    if (isSelected) {
                                      set.remove(oi);
                                    } else {
                                      if (maxSelect == 1) {
                                        set.clear();
                                        set.add(oi);
                                      } else if (set.length < maxSelect) {
                                        set.add(oi);
                                      }
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0).withAlpha(128)))),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(optName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFF0B1A30) : const Color(0xFF374151))),
                                            const SizedBox(height: 2),
                                            Text('฿$optPrice', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF00C7E6) : Colors.white,
                                          borderRadius: BorderRadius.circular(maxSelect == 1 ? 11 : 4),
                                          border: Border.all(color: isSelected ? const Color(0xFF00C7E6) : const Color(0xFFD1D5DB), width: 1.5),
                                        ),
                                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: const Color(0xFFF4F7FA),
                        child: const Text('โน้ตถึงร้านค้า (ไม่บังคับ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, color: Color(0xFF94A3B8), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: noteController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'เพิ่มรายละเอียดเพิ่มเติม...',
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // ── Bottom update button
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allRequiredSelected ? const Color(0xFF00C7E6) : const Color(0xFFCBD5E1), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), 
                        elevation: 0
                      ),
                      onPressed: allRequiredSelected ? () {
                        final List<String> optNames = [];
                        selectedOpts.forEach((gi, optSet) {
                          for (final oi in optSet) {
                            optNames.add((optionGroups[gi]['options'] as List)[oi]['name'] as String);
                          }
                        });
                        if (noteController.text.trim().isNotEmpty) {
                          optNames.add(noteController.text.trim());
                        }
                        final finalNote = optNames.join(', ');

                        final int singleUnitPrice = basePrice + extraPrice;
                        setState(() {
                          if (widget.cartOptions != null) widget.cartOptions![name] = finalNote;
                          widget.onUpdateQuantity(name, '฿$singleUnitPrice', img, tempQty, storeTitle: widget.storeTitle, optionsNote: finalNote);
                        });
                        Navigator.pop(ctx);
                      } : null,
                      child: Text('อัปเดตตะกร้า - ฿$totalPrice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('ยืนยันคำสั่งซื้อ', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _storeItems.isEmpty
          ? const Center(child: Text('ไม่มีสินค้าของร้านนี้ในตะกร้า', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── 🏪 Store & Items Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.storefront, color: Color(0xFF00C7E6), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  widget.storeTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Color(0xFF0B1A30), decoration: TextDecoration.none),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                if (widget.allFoodTrucks != null && widget.allFoodTrucks!.isNotEmpty) {
                                  final truck = widget.allFoodTrucks!.firstWhere(
                                    (t) => t['title'] == widget.storeTitle,
                                    orElse: () => widget.allFoodTrucks!.first,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreDetailPage(
                                        truck: truck,
                                        isGuestMode: false,
                                        onNavigate: (title, dist) {},
                                        allFoodTrucks: widget.allFoodTrucks!,
                                        cartQuantities: widget.cartQuantities,
                                        cartPrices: widget.cartPrices,
                                        cartImages: widget.cartImages,
                                        cartStores: widget.cartStores ?? {},
                                        cartOptions: widget.cartOptions ?? {},
                                        onUpdateQuantity: widget.onUpdateQuantity,
                                        onViewReviews: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsPage(truck: truck, isGuestMode: false)));
                                        },
                                        onClearCart: (s) => widget.onClearCart(),
                                      ),
                                    ),
                                  ).then((_) => setState(() {}));
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: const Text('เพิ่มรายการ', style: TextStyle(color: Color(0xFF00C7E6), fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Item List
                        ..._storeItems.map((name) {
                          final price = widget.cartPrices[name] ?? '฿0';
                          final img = widget.cartImages[name] ?? '';
                          final qty = widget.cartQuantities[name] ?? 1;
                          final note = widget.cartOptions?[name] ?? 'รสชาติมาตรฐาน';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    img, width: 72, height: 72, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: const Color(0xFFF4F5F7), child: const Icon(Icons.fastfood, color: Color(0xFF94A3B8))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1A30)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ),
                                          GestureDetector(
                                            onTap: () => _showEditItemModal(name, price, img, qty, note),
                                            child: const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text('แก้ไข', style: TextStyle(color: Color(0xFF00C7E6), fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (note.isNotEmpty && note != 'รสชาติมาตรฐาน') ...[
                                        const SizedBox(height: 4),
                                        Text(note, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00C7E6))),
                                          Row(
                                            children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      widget.onUpdateQuantity(name, price, img, qty - 1, storeTitle: widget.storeTitle, optionsNote: note);
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 24, height: 24,
                                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF00C7E6), width: 1.2)),
                                                    child: const Icon(Icons.remove, size: 16, color: Color(0xFF00C7E6)),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Text('$qty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      widget.onUpdateQuantity(name, price, img, qty + 1, storeTitle: widget.storeTitle, optionsNote: note);
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 24, height: 24,
                                                    decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(4)),
                                                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── ⚙️ Options & Summary Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: const [
                              Icon(Icons.qr_code_2, size: 20, color: Color(0xFF0B1A30)),
                              SizedBox(width: 8),
                              Text('ชำระเงิน', style: TextStyle(fontSize: 14, color: Color(0xFF0B1A30), fontWeight: FontWeight.bold)),
                            ]),
                            const Text('QR Code (พร้อมเพย์)', style: TextStyle(fontSize: 13.5, color: Color(0xFF0B1A30), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        GestureDetector(
                          onTap: _showOutOfStockModal,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('การตั้งค่าสำหรับสินค้าที่หมด', style: TextStyle(fontSize: 13, color: Color(0xFF0B1A30), fontWeight: FontWeight.w600)),
                              Row(children: [
                                Text(_outOfStockOption, style: const TextStyle(fontSize: 13, color: Color(0xFF0B1A30), fontWeight: FontWeight.bold)),
                                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF64748B)),
                              ]),
                            ],
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ทั้งหมด $_totalItems รายการ:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                            Text('฿$_totalPrice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      // ── Sticky Checkout Bar
      bottomNavigationBar: _storeItems.isEmpty ? null : Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('รวมทั้งหมด ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                Text('฿$_totalPrice', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7E6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                elevation: 0,
              ),
             onPressed: () async {
                // 1. แสดง Loading หมุนๆ ระหว่างรอ API
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6))),
                );

                try {
                  // --- ส่วนที่เชื่อมต่อ API เพื่อสร้างคำสั่งซื้อของจริง ---
                  
                  // ดึงรหัสร้าน (merchantId) จากข้อมูลร้านทั้งหมดเพื่อส่งให้ Backend
                  int merchantId = 1;
                  if (widget.allFoodTrucks != null) {
                    try {
                      final truck = widget.allFoodTrucks!.firstWhere((t) => t['title'] == widget.storeTitle);
                      merchantId = int.tryParse(truck['id'].toString()) ?? 1;
                    } catch (e) {}
                  }

                  // เตรียมรายการอาหาร (Items) เพื่อส่งให้เซิร์ฟเวอร์
                  final orderItems = _storeItems.map((name) {
                    final qty = widget.cartQuantities[name] ?? 1;
                    // ลบตัวอักษร ฿ ออกให้เหลือแต่ตัวเลขล้วนๆ
                    final priceStr = widget.cartPrices[name]?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
                    final price = int.tryParse(priceStr) ?? 0;
                    final note = widget.cartOptions?[name] ?? '';
                    return {
                      'name': name,
                      'qty': qty,
                      'price': price,
                      'note': note
                    };
                  }).toList();

                  // จัดโครงสร้าง JSON ส่งให้ Backend ตามที่ Backend ต้องการเป๊ะๆ
                  final requestBody = {
                    'customer_id': int.tryParse(buyerHomeKey.currentState?.widget.userData?['customer_id']?.toString() ?? '1') ?? 1,
                    'merchant_id': merchantId,
                    'total_price': _totalPrice,
                    'status': 'รอชำระเงิน',
                    'items': orderItems
                  };

                  // ยิง HTTP POST ไปที่ API createOrder
                  final url = Uri.parse(ApiConfig.createOrder);
                  final response = await http.post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(requestBody),
                  );

                  if (!mounted) return;
                  Navigator.pop(context); // ปิด Loading หมุนๆ

                  // ตรวจสอบว่า Backend สร้างออเดอร์สำเร็จไหม (สถานะ 201 Created)
                  if (response.statusCode == 201) {
                    final resData = jsonDecode(response.body);
                    final newOrderId = resData['orderId'].toString();

                    // เตรียมข้อมูลสำหรับส่งไปโชว์ในหน้าบิลออเดอร์ (OrderDetailScreen)
                    final newItemsForScreen = _storeItems.map((name) {
                      return {
                        'name': name,
                        'qty': widget.cartQuantities[name] ?? 1,
                        'price': widget.cartPrices[name] ?? '฿0',
                        'img': widget.cartImages[name] ?? '',
                        'note': widget.cartOptions?[name] ?? '',
                      };
                    }).toList(); 

                    final now = DateTime.now();
                    final actualTime = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                    final newOrder = {
                      'id': 'ORD-$newOrderId', // ได้ ID จริงมาจาก Backend แล้ว!
                      'storeTitle': widget.storeTitle,
                      'status': 'รอชำระเงิน', 
                      'isCompleted': false,
                      'date': actualTime, 
                      'totalPrice': '฿$_totalPrice.00',
                      'itemsCount': _totalItems, 
                      'items': newItemsForScreen,
                      'merchantId': merchantId,
                    }; 

                    // 2. เคลียร์ตะกร้าทิ้งหลังจากสั่งเสร็จแล้ว
                    widget.onClearCart();
                    
                    // 3. ปิดหน้า Checkout ส่งไปหน้ารอรับคำสั่งซื้อ (ใหม่!)
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WaitingOrderScreen(
                          order: newOrder,
                          allFoodTrucks: widget.allFoodTrucks ?? [],
                        ),
                      ),
                    );
                  } else {
                    // ถ้า Backend มี Error จะโชว์แจ้งเตือน
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สร้างออเดอร์ไม่สำเร็จ: ${response.body}')));
                  }
                } catch (e) {
                  Navigator.pop(context); // ปิด Loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                }
              },
              child: const Text('สั่งซื้อ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
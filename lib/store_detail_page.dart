import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // สำหรับปุ่มแชร์ร้านค้า
import 'buyer_home_screen.dart'; // สำหรับดึง State ตะกร้าสินค้า
import 'login_screen.dart'; // สำหรับโหมด Guest สมัครสมาชิก
import 'checkout_screen.dart'; // สำหรับกดสั่งซื้อ
import 'my_cart_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; // 🟢 เพิ่มบรรทัดนี้
import 'dart:convert'; // 🟢 เพิ่มบรรทัดนี้
import 'api.config.dart'; // 🟢 เพิ่มบรรทัดนี้
// ============================================================
// STORE DETAIL PAGE (Full screen, style like reference image)
// ============================================================
class StoreDetailPage extends StatefulWidget {
  final Map<String, dynamic> truck;
  final bool isGuestMode;
  final Function(String, String) onNavigate;
  final Map<String, int> cartQuantities;
  final Map<String, String> cartPrices;
  final Map<String, String> cartImages;
  final Map<String, String> cartStores;
  final Map<String, String> cartOptions;
  final List<Map<String, dynamic>> allFoodTrucks;
  final Function(String, String, String, int, {StateSetter? modalSetter, String? storeTitle, String? optionsNote}) onUpdateQuantity;
  final VoidCallback onViewReviews;
  final Function(String storeTitle)? onClearCart;
  final Function(int)? onSwitchTab;
  final String customerId;

  const StoreDetailPage({
    super.key,
    required this.truck,
    required this.isGuestMode,
    required this.onNavigate,
    required this.cartQuantities,
    required this.cartPrices,
    required this.cartImages,
    this.cartStores = const {},
    this.cartOptions = const {},
    this.allFoodTrucks = const [],
    required this.onUpdateQuantity,
    required this.onViewReviews,
    this.onClearCart,
    this.onSwitchTab,
    this.customerId = '1',
  });

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  String _selectedMenuCat = 'ทั้งหมด';
  late List<Map<String, dynamic>> _menus;
  late List<String> _menuCategories;

  bool _isFollowing = false;
  int _followerCount = 0; // 🟢 เริ่มต้นที่ 0 รอโหลดจากเซิร์ฟเวอร์

  @override
  void initState() {
    super.initState();
    _menus = List<Map<String, dynamic>>.from(widget.truck['menus'] ?? []);
    final seen = <String>{};
    final cats = <String>[];
    for (final m in _menus) {
      final cat = (m['category'] ?? 'เมนูหลัก').toString();
      if (seen.add(cat)) cats.add(cat);
    }

    if (cats.length > 1) {
      _menuCategories = ['ทั้งหมด', ...cats];
      _selectedMenuCat = 'ทั้งหมด';
    } else if (cats.isNotEmpty) {
      _menuCategories = cats;
      _selectedMenuCat = cats.first;
    } else {
      _menuCategories = ['ทั้งหมด'];
      _selectedMenuCat = 'ทั้งหมด';
    }
   
    // ดึงข้อมูลสถานะติดตามและยอดผู้ติดตามสดๆ จาก API
    _fetchStoreData();
  }

  // 🟢 ฟังก์ชันดึงสถานะการติดตามและยอด Followers จากฐานข้อมูลจริง
  Future<void> _fetchStoreData() async {
    final int merchantId = int.tryParse(widget.truck['id']?.toString() ?? widget.truck['merchant_id']?.toString() ?? '1') ?? 1;
   
    // --- 1. ดึงยอด Followers ---
    try {
      final resFollowers = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/merchants/$merchantId/followers'));
     
      if (resFollowers.statusCode == 200) {
        final data = jsonDecode(resFollowers.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _followerCount = int.tryParse(data['count']?.toString() ?? '0') ?? 0;
            });
          }
        }
      }
    } catch (e) {
      print('🚀 Error loading follower count: $e');
    }

    // --- 2. เช็กสถานะการกดติดตามของลูกค้า ---
    if (widget.isGuestMode) return;
    try {
      final customerId = widget.customerId;
      final resStatus = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/customers/$customerId/followed'));
     
      if (resStatus.statusCode == 200) {
        final resData = jsonDecode(resStatus.body);
        if (resData['success'] == true) {
          final List<dynamic> followedIds = resData['data'];
          if (mounted) {
            setState(() {
              _isFollowing = followedIds.map((id) => id.toString()).contains(merchantId.toString());
             
              // 🟢 การป้องกันขั้นเด็ดขาด (Fallback):
              // ถ้า API ฝั่ง Backend ดึงยอดรวมมาได้ 0 หรือหาไม่เจอ แต่ลูกค้าคนนี้ "ติดตามอยู่"
              // อย่างน้อยยอดรวมต้องเท่ากับ 1 เสมอ (คือตัวลูกค้าเอง)!
              if (_isFollowing && _followerCount == 0) {
                _followerCount = 1;
              }
            });
          }
        }
      }
    } catch (e) {
      print('🚀 Error loading follow status: $e');
    }
  }

  void _showContactModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.contact_support_outlined, color: Color(0xFF00C7E6), size: 26),
            const SizedBox(width: 8),
            const Text('ติดต่อร้านค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B1A30))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactRow(Icons.phone, 'เบอร์โทรศัพท์', widget.truck['phone'] ?? '081-234-5678', () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('กำลังเชื่อมต่อโทรศัพท์ไปที่ ${widget.truck['phone'] ?? '081-234-5678'} 📞'), backgroundColor: const Color(0xFF10B981)));
            }),
            const SizedBox(height: 12),
            _buildContactRow(Icons.facebook, 'Facebook Official', widget.truck['facebook'] ?? 'official.truck', () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เปิด Facebook: ${widget.truck['facebook']} 🌐'), backgroundColor: const Color(0xFF00C7E6)));
            }),
            const SizedBox(height: 12),
            _buildContactRow(Icons.chat_bubble_outline, 'Line Official', widget.truck['line'] ?? '@truck_official', () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เพิ่มเพื่อน Line: ${widget.truck['line']} 💬'), backgroundColor: const Color(0xFF10B981)));
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String val, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00C7E6), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ─── LOGIN PROMPT (guest mode)
  void _showLoginPrompt(String menuName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_add_outlined, size: 44, color: Color(0xFF00C7E6)),
          const SizedBox(height: 14),
          Text('ต้องการสั่ง "$menuName" ไหม?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('กรุณาเข้าสู่ระบบเพื่อสั่งอาหารล่วงหน้าและรับที่หน้าร้านได้เลย', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C7E6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
            onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
            child: const Text('เข้าสู่ระบบ / สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ไม่เป็นไร ขอดูก่อน', style: TextStyle(color: Color(0xFF94A3B8)))),
        ]),
      ),
    );
  }

  // ─── ORDER OPTIONS SHEET (เพิ่มรายการใหม่)
  void _showOrderOptionsSheet(Map<String, dynamic> menu) {
    final name = menu['name'] as String;
    final price = menu['price'] as String;
    final img = menu['img'] as String;
    final soldCount = (menu['soldCount'] as String?) ?? '';
    final optionGroups = List<Map<String, dynamic>>.from(menu['optionGroups'] ?? []);

    final basePrice = (double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0).toInt();
    int qty = 1;
    // selected options: groupIndex -> Set<optionIndex>
    final Map<int, Set<int>> selectedOpts = {};
    for (int i = 0; i < optionGroups.length; i++) {
      selectedOpts[i] = {};
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSheet) {
          // Compute total price
          int extraPrice = 0;
          selectedOpts.forEach((gi, optSet) {
            for (final oi in optSet) {
              extraPrice += (optionGroups[gi]['options'] as List)[oi]['price'] as int;
            }
          });
          final totalPrice = (basePrice + extraPrice) * qty;

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
                          child: Text('เพิ่มรายการใหม่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
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
                  const Divider(height: 1),

                  // ── Scrollable body
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
                                    if (soldCount.isNotEmpty) ...
                                      [const SizedBox(height: 4), Text(soldCount, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))],
                                    const SizedBox(height: 8),
                                    Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
                                    const SizedBox(height: 10),
                                    // ── Qty stepper
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => setSheet(() { if (qty > 1) qty--; }),
                                          child: Container(
                                            width: 34, height: 34,
                                            decoration: BoxDecoration(
                                              color: qty > 1 ? const Color(0xFF00C7E6) : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.remove, color: qty > 1 ? Colors.white : const Color(0xFF94A3B8), size: 18),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                                        ),
                                        GestureDetector(
                                          onTap: () => setSheet(() => qty++),
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

                        // ── Option groups
                        ...List.generate(optionGroups.length, (gi) {
                          final grp = optionGroups[gi];
                          final title = grp['title'] as String;
                          final maxSelect = grp['maxSelect'] as int;
                          final opts = List<Map<String, dynamic>>.from(grp['options'] as List);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                color: const Color(0xFFF4F7FA),
                                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              ),
                              // Options
                              ...List.generate(opts.length, (oi) {
                                final opt = opts[oi];
                                final optName = opt['name'] as String;
                                final optPrice = opt['price'] as int;
                                final isSelected = selectedOpts[gi]?.contains(oi) ?? false;

                                return GestureDetector(
                                  onTap: () {
                                    setSheet(() {
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
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0).withAlpha(128))),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(optName,
                                                style: TextStyle(
                                                  fontSize: 14, fontWeight: FontWeight.w500,
                                                  color: isSelected ? const Color(0xFF0B1A30) : const Color(0xFF374151),
                                                ),
                                              ),
                                              if (optPrice > 0) ...
                                                [const SizedBox(height: 2), Text('฿$optPrice', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))]
                                              else
                                                const SizedBox(height: 2),
                                              Text(optPrice == 0 ? '฿0' : '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                            ],
                                          ),
                                        ),
                                        // Checkbox style
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: 22, height: 22,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF00C7E6) : Colors.white,
                                            borderRadius: BorderRadius.circular(maxSelect == 1 ? 11 : 4),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF00C7E6) : const Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
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
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),

                  // ── Bottom add button
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
                          elevation: 0,
                        ),
                        onPressed: allRequiredSelected ? () {
                          // สร้างอ็อปชันสำหรับบันทึกลงตะกร้า
                          final List<String> optNames = [];
                          selectedOpts.forEach((gi, optSet) {
                            for (final oi in optSet) {
                              optNames.add((optionGroups[gi]['options'] as List)[oi]['name'] as String);
                            }
                          });
                          final String optSummary = optNames.isEmpty ? 'รสชาติมาตรฐาน ทางร้านปรุงปกติ' : optNames.join(', ');

                          final int singleUnitPrice = basePrice + extraPrice;
                          widget.onUpdateQuantity(
                            name, '฿$singleUnitPrice', img,
                            (widget.cartQuantities[name] ?? 0) + qty,
                            storeTitle: widget.truck['title'] as String,
                            optionsNote: optSummary,
                          );
                          setState(() {});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เพิ่ม $name x$qty ไปยังตะกร้าแล้ว 🛒'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          // เมื่อกดเพิ่มในตะกร้า ห้ามเปิดตะกร้าหรือสร้างปุ่มตะกร้าซ้ำซ้อน (ตามกฎข้อที่ 8)
                        } : null,
                        child: Text(
                          'เพิ่มไปยังตะกร้า ฿$totalPrice',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  int get _totalCartCount => widget.cartQuantities.values.fold(0, (sum, c) => sum + c);


  void _openCheckoutScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyCartScreen(
          cartQuantities: widget.cartQuantities,
          cartPrices: widget.cartPrices,
          cartImages: widget.cartImages,
          cartStores: widget.cartStores,
          cartOptions: widget.cartOptions,
          allFoodTrucks: widget.allFoodTrucks,
          onUpdateQuantity: (name, price, img, newQty, {modalSetter, storeTitle, optionsNote}) {
            widget.onUpdateQuantity(name, price, img, newQty, modalSetter: modalSetter, storeTitle: storeTitle ?? widget.truck['title'] as String, optionsNote: optionsNote);
            setState(() {});
          },
          onClearStoreCart: (storeTitle) {
            widget.onClearCart?.call(storeTitle);
            setState(() {
              final toDel = <String>[];
              for (var k in widget.cartQuantities.keys) {
                if ((widget.cartStores[k] ?? widget.truck['title']) == storeTitle) toDel.add(k);
              }
              for (var k in toDel) {
                widget.cartQuantities.remove(k);
                widget.cartPrices.remove(k);
                widget.cartImages.remove(k);
                widget.cartStores.remove(k);
                widget.cartOptions.remove(k);
              }
            });
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenus = (_selectedMenuCat == 'ทั้งหมด')
        ? _menus
        : _menus.where((m) => (m['category'] ?? 'เมนูหลัก').toString() == _selectedMenuCat).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 16), onPressed: () => Navigator.pop(context)),
              ),
            ),
            actions: [
              // 🛒 Cart Icon in Store Header
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0B1A30), size: 18),
                        onPressed: () {
                          if (widget.isGuestMode) {
                            _showLoginPrompt('ตะกร้าสินค้า');
                          } else if (_totalCartCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยังไม่มีสินค้าในตะกร้า 🛒')));
                          } else {
                            _openCheckoutScreen();
                          }
                        },
                      ),
                    ),
                    if (!widget.isGuestMode && _totalCartCount > 0)
                      Positioned(
                        right: 2, top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFF00C7E6), shape: BoxShape.circle),
                          child: Text('$_totalCartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(icon: const Icon(Icons.share_outlined, color: Color(0xFF0B1A30), size: 18), onPressed: () {
                    final title = widget.truck['title'] as String;
                    final shopType = widget.truck['shopType'] as String;
                    final rating = widget.truck['rating'] as String;
                    final distance = widget.truck['info'] as String;
                    Share.share(
                      '🛒 แนะนำร้าน "$title"\n📌 $shopType\n⭐ คะแนน $rating/5\n📍 ห่าง $distance\n\nดาวน์โหลดแอปเพื่อสั่งอาหารล่วงหน้าแล้วไปรับที่ร้าน!',
                    );
                  }),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.truck['img'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF4F5F7), child: const Icon(Icons.storefront_outlined, size: 60, color: Color(0xFF94A3B8))),
              ),
            ),
          ),

          // ── Store info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.truck['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                          const SizedBox(height: 2),
                          Text(widget.truck['shopType'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ]),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => widget.onNavigate(widget.truck['title'], widget.truck['info']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF00C7E6).withAlpha(76), blurRadius: 8, offset: const Offset(0, 4))]),
                              child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.near_me, color: Colors.white, size: 14), SizedBox(width: 5), Text('นำทาง', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))]),
                            ),
                          ),
                          const SizedBox(height: 6),
                         
                            GestureDetector(
                                onTap: () async {
                                  if (widget.isGuestMode) {
                                    _showLoginPrompt('ติดตามร้านค้า เพื่อรับแจ้งเตือนเมื่อเปิดขายหรือย้ายตำแหน่ง');
                                    return;
                                  }

                                  setState(() {
                                    _isFollowing = !_isFollowing;
                                    if (_isFollowing) {
                                      _followerCount++;
                                    } else {
                                      if (_followerCount > 0) _followerCount--;
                                    }
                                  });

                                  try {
                                    final int mId = int.tryParse(widget.truck['id']?.toString() ?? widget.truck['merchant_id']?.toString() ?? '1') ?? 1;
                                   
                                    // 🟢 กลับมาใช้ JSON แต่ส่งคีย์เผื่อไป "ทุกรูปแบบ" ดักทาง Backend ไว้หมดแล้ว!
                                    final int cId = int.tryParse(widget.customerId) ?? 1;
                                    final Map<String, dynamic> payload = {
                                      "id": cId,
                                      "customer_id": cId,
                                      "customerId": cId,
                                      "user_id": cId,
                                      "userId": cId,
                                      "merchant_id": mId,
                                      "merchantId": mId
                                    };
                                    print('🚀 [แอป] ส่ง JSON หว่านแห: ${jsonEncode(payload)}');
                                   
                                    final response = await http.post(
                                      Uri.parse('${ApiConfig.baseUrl}/api/customers/follow'),
                                      headers: {
                                        'Content-Type': 'application/json', // 🟢 ย้ำว่าต้องเป็น JSON
                                        'Accept': 'application/json'
                                      },
                                      body: jsonEncode(payload),
                                    );
                                   
                                    print('🚀 [Backend] ตอบ: ${response.statusCode} - ${response.body}');
                                    if (response.statusCode != 200) throw Exception('Server Error');
                                   
                                    // ดึงยอดใหม่จาก Database
                                    await _fetchStoreData();
                                   
                                    if (!mounted) return;
                                    if (_isFollowing) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('ติดตาม ${widget.truck['title']} เรียบร้อย 🔔'),
                                        backgroundColor: const Color(0xFF10B981),
                                      ));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('ยกเลิกการติดตาม ${widget.truck['title']} แล้ว'),
                                        backgroundColor: const Color(0xFF64748B),
                                      ));
                                    }
                                  } catch (e) {
                                    print('🚀 [Error]: $e');
                                    if (!mounted) return;
                                    setState(() {
                                      _isFollowing = !_isFollowing;
                                      if (_isFollowing) {
                                        _followerCount++;
                                      } else {
                                        if (_followerCount > 0) _followerCount--;
                                      }
                                    });
                                  }
                                },

                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isFollowing ? const Color(0xFFE6F8F3) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _isFollowing ? const Color(0xFF10B981) : const Color(0xFF00C7E6), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_isFollowing ? Icons.check : Icons.add_alert_outlined, size: 14, color: _isFollowing ? const Color(0xFF10B981) : const Color(0xFF00C7E6)),
                                  const SizedBox(width: 4),
                                  Text(
                                    // แสดงยอดผู้ติดตามในปุ่ม
                                    _isFollowing ? 'ติดตามแล้ว ($_followerCount)' : '+ ติดตาม ($_followerCount)',
                                    style: TextStyle(
                                      color: _isFollowing ? const Color(0xFF10B981) : const Color(0xFF00C7E6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // ลบช่องว่างระหว่างดาวกับประเภทร้านออก ตามข้อกำหนด
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: widget.onViewReviews,
                    child: Row(children: [
                      ...List.generate(5, (i) {
                        final r = double.parse(widget.truck['rating']);
                        return Icon(i < r.floor() ? Icons.star : (i < r ? Icons.star_half : Icons.star_border), color: Colors.amber, size: 20);
                      }),
                      const SizedBox(width: 6),
                      Text(widget.truck['rating'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B1A30))),
                      const SizedBox(width: 4),
                      Text('(${widget.truck['reviewCount']} รีวิวร้านค้า)', style: const TextStyle(color: Color(0xFF00C7E6), fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Color(0xFF00C7E6), size: 16),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('ห่างจากคุณ ${widget.truck['info']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                    const SizedBox(width: 16),
                    // 아이คอนนาฬิกา และตัว 'V' ข้างหลังเพื่อกดเปิด popup
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: [
                                const Icon(Icons.access_time_filled, color: Color(0xFF00C7E6), size: 24),
                                const SizedBox(width: 8),
                                const Text('เวลาเปิดขายของร้าน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0B1A30))),
                              ],
                            ),
                            content: Text(
                              'ร้านเปิดขายเวลา \'${widget.truck['openTime']} อัปเดตล่าสุดเมื่อ ${widget.truck['lastUpdate'] ?? '9:00 30/7/2026'}\'',
                              style: const TextStyle(fontSize: 15, color: Color(0xFF0B1A30), height: 1.5, fontWeight: FontWeight.w500),
                            ),
                            actions: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C7E6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('ตกลง', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 15, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(widget.truck['openTime'], style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF00C7E6)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  // ── ไอคอนช่องทางติดต่อ ลงมาอยู่เดียวกับรายละเอียดร้าน และกดเชื่อมลิงก์/โทรศัพท์ได้จริงตามธีมสีแอป
                  Row(
                    children: [
                      const Text('ติดต่อ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                      const SizedBox(width: 10),
                      // โทรศัพท์
                      GestureDetector(
                        onTap: () async {
                          final phone = widget.truck['phone'] ?? '081-234-5678';
                          final cleanPhone = phone.replaceAll('-', '').replaceAll(' ', '');
                          final uri = Uri.parse('tel:$cleanPhone');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('หมายเลขโทรศัพท์: $phone 📞'), backgroundColor: const Color(0xFF10B981)));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE5EEF5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00C7E6).withAlpha(100))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.phone, color: Color(0xFF00C7E6), size: 15),
                            SizedBox(width: 4),
                            Text('โทร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Facebook
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://m.facebook.com/wongnai');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังเปิด Facebook Official 🌐'), backgroundColor: Color(0xFF0088CC)));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF0088CC).withAlpha(100))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.facebook, color: Color(0xFF0088CC), size: 15),
                            SizedBox(width: 4),
                            Text('Facebook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0088CC))),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // LINE Official
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://line.me/ti/p/~@wongnai');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังเปิด LINE Official 💬'), backgroundColor: Color(0xFF10B981)));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE6F8F3), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF10B981).withAlpha(100))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.chat_bubble, color: Color(0xFF10B981), size: 15),
                            SizedBox(width: 4),
                            Text('LINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── 🍽️ Sticky Category Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryTabDelegate(
              categories: _menuCategories,
              selected: _selectedMenuCat,
              onSelect: (cat) => setState(() => _selectedMenuCat = cat),
            ),
          ),

          // ── Menu count label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text('$_selectedMenuCat (${filteredMenus.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
            ),
          ),

          // ── Menu grid (2 columns)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildMenuGridCard(filteredMenus[i]),
                childCount: filteredMenus.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      // ── Mobile Bottom Navigation Bar (คงอยู่เสมอเหมือนหน้าหลักตามข้อ 4 / ห้ามแสดงปุ่มตะกร้าของฉันซ้ำซ้อนตามข้อ 8)
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isGuestMode)
            Container(
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))]),
              child: BottomNavigationBar(
                currentIndex: 0,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF00C7E6),
                unselectedItemColor: const Color(0xFF64748B),
                selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                elevation: 0,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    widget.onSwitchTab?.call(index);
                  }
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'หน้าหลัก'),
                  BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'คำสั่งซื้อ'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'โปรไฟล์'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuGridCard(Map<String, dynamic> menu) {
    final name = menu['name'] as String;
    final price = menu['price'] as String;
    final img = menu['img'] as String;
    final soldCount = (menu['soldCount'] as String?) ?? '';
    final status = (widget.truck['status'] ?? 'open') as String;
    final bool isNotOpen = status == 'closed' || status == 'moving';
    final currentQty = widget.cartQuantities[name] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Food image with + button overlay
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Opacity(
                    opacity: status == 'closed' ? 0.4 : 1.0,
                    child: Image.network(img, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF4F5F7),
                            child: const Icon(Icons.fastfood_outlined, size: 36, color: Color(0xFF94A3B8)))),
                  ),
                  // "สั่งเยอะที่สุด" badge (for high sold count items)
                  if (soldCount.contains('100+') || soldCount.contains('200+'))
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF00C7E6), borderRadius: BorderRadius.circular(8)),
                        child: const Text('สั่งเยอะที่สุด', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  // + / - stepper or + button bottom right
                  Positioned(
                    bottom: 6, right: 6,
                    child: isNotOpen ? Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                    ) : (currentQty > 0 && !widget.isGuestMode)
                        ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1A30),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      widget.onUpdateQuantity(name, price, img, currentQty - 1, storeTitle: widget.truck['title'] as String);
                                    });
                                  },
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                                    child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                  child: Text('$currentQty', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      widget.onUpdateQuantity(name, price, img, currentQty + 1, storeTitle: widget.truck['title'] as String);
                                    });
                                  },
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(color: Color(0xFF00C7E6), shape: BoxShape.circle),
                                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              if (widget.isGuestMode) {
                                _showLoginPrompt(name);
                              } else {
                                _showOrderOptionsSheet(menu);
                              }
                            },
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C7E6),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // ── Name + Price
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: status == 'closed' ? const Color(0xFF94A3B8) : const Color(0xFF0B1A30)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(price, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: status == 'closed' ? const Color(0xFF94A3B8) : const Color(0xFF00C7E6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky Category Tab Bar Delegate
class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final Function(String) onSelect;

  _CategoryTabDelegate({required this.categories, required this.selected, required this.onSelect});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) {
            final sel = selected == cat;
            return GestureDetector(
              onTap: () => onSelect(cat),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: sel ? const Color(0xFF00C7E6) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? const Color(0xFF00C7E6) : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryTabDelegate oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.categories != categories;
}
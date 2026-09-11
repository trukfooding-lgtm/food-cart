import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'api.config.dart';
import 'location_selection_screen.dart';
import 'buyer_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'followed_shops_screen.dart';
import 'refund_details_screen.dart';
import 'help_center_screen.dart';
import 'cancelled_order_details_screen.dart';
import 'notification_screen.dart';
import 'payment_screen.dart';
import 'all_stores_screen.dart';
import 'my_cart_screen.dart';
import 'order_detail_screen.dart';
import 'reviews_page.dart';
import 'store_rating_screen.dart';
import 'rate_store_screen.dart';
import 'checkout_screen.dart';
import 'store_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ============================================================
// BUYER HOME SCREEN
// ============================================================
// ── สร้างตัวแปร GlobalKey สำหรับสั่งสลับแท็บจากหน้าย่อย
final GlobalKey<_BuyerHomeScreenState> buyerHomeKey = GlobalKey<_BuyerHomeScreenState>();

class BuyerHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  // นำ GlobalKey มาผูกกับหน้าหลัก
  BuyerHomeScreen({Key? key, this.userData}) : super(key: key ?? buyerHomeKey);

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
    // เพิ่มบรรทัดนี้เพื่อเปิดทางให้ไฟล์อื่นดึงข้อมูลร้านได้
  get publicFoodTrucks => _allFoodTrucks;
  // ── ฟังก์ชันสั่งเปลี่ยนแท็บจากหน้าอื่น ──
  void switchTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
        if (index == 1) {
          _refreshOrders();
        }
      });
    }
  }

  void setOrderFilter(String filter) {
    if (mounted) {
      setState(() {
        _orderFilter = filter;
      });
    }
  }



  int _currentIndex = 0;
  final String baseUrl = ApiConfig.baseUrl;

  String _selectedCategory = 'ทั้งหมด';
  String _currentLocation = '763R+7FQ ตำบล ขามเรียง มหาสารคาม';
  double _customerLat = LocationService.defaultLat;
  double _customerLng = LocationService.defaultLng;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = false;

  final Map<String, int> _cartQuantities = {};
  final Map<String, String> _cartPrices = {};
  final Map<String, String> _cartImages = {};
  final Map<String, String> _cartStores = {};
  final Map<String, String> _cartOptions = {};

  String _orderFilter = 'สถานะทั้งหมด';

  // 📝 ประวัติการสั่งซื้อ: storeTitle -> จำนวนครั้งที่สั่ง, จำนวนรีวิวที่เขียนแล้ว
  final Map<String, int> _orderHistory = {}; // storeTitle -> orderCount
  final Map<String, int> _reviewHistory = {}; // storeTitle -> reviewCount

  List<String> get _categories {
    final cats = <String>{'ทั้งหมด'};
    for (final t in _allFoodTrucks) {
      final c = (t['category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    return cats.toList();
  }
  
  // ==========================================
  // Backend States (อ้างอิงจาก K)
  // ==========================================
  Future<List<dynamic>>? _ordersFuture;
  bool _isLoadingTrucks = true;
  final Map<int, String> _tempComments = {};
  final Map<int, int> _tempRatings = {};
  
  List<Map<String, dynamic>> _allFoodTrucks = [];
  // _myOrders ถูกลบออกเนื่องจากเปลี่ยนไปดึงข้อมูลจาก _ordersFuture แทน

  @override
  void initState() {
    super.initState();
    _loadSavedCustomerLocation();
    _ordersFuture = _fetchMyOrdersFromDB();
    _fetchFoodTrucks();
    _syncStoreReviews();
    _loadSavedCart();
  }

  Future<void> _loadSavedCustomerLocation() async {
    final saved = await LocationService.getSavedLocation();
    if (saved != null && mounted) {
      setState(() {
        _customerLat = saved.latitude;
        _customerLng = saved.longitude;
        _currentLocation = saved.address;
      });
      _recalculateAllStoreDistances();
    }
  }

  @override
  void didUpdateWidget(covariant BuyerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userData?['customer_id'] != widget.userData?['customer_id'] ||
        oldWidget.userData?['id'] != widget.userData?['id']) {
      _loadSavedCart();
      _ordersFuture = _fetchMyOrdersFromDB();
    }
  }

  Future<void> _loadSavedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String customerId = widget.userData?['customer_id']?.toString() 
          ?? widget.userData?['id']?.toString() 
          ?? 'guest';
      final String? cartJson = prefs.getString('cart_$customerId');
      if (cartJson != null && cartJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(cartJson);
        if (!mounted) return;
        setState(() {
          _cartQuantities.clear();
          _cartPrices.clear();
          _cartImages.clear();
          _cartStores.clear();
          _cartOptions.clear();

          if (data['quantities'] != null) {
            (data['quantities'] as Map).forEach((k, v) {
              final int qty = int.tryParse(v.toString()) ?? 0;
              if (qty > 0) _cartQuantities[k.toString()] = qty;
            });
          }
          if (data['prices'] != null) {
            (data['prices'] as Map).forEach((k, v) => _cartPrices[k.toString()] = v.toString());
          }
          if (data['images'] != null) {
            (data['images'] as Map).forEach((k, v) => _cartImages[k.toString()] = v.toString());
          }
          if (data['stores'] != null) {
            (data['stores'] as Map).forEach((k, v) => _cartStores[k.toString()] = v.toString());
          }
          if (data['options'] != null) {
            (data['options'] as Map).forEach((k, v) => _cartOptions[k.toString()] = v.toString());
          }
        });
      }
    } catch (e) {
      print("Error loading cart from storage: $e");
    }
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String customerId = widget.userData?['customer_id']?.toString() 
          ?? widget.userData?['id']?.toString() 
          ?? 'guest';
      final cartData = {
        'quantities': _cartQuantities,
        'prices': _cartPrices,
        'images': _cartImages,
        'stores': _cartStores,
        'options': _cartOptions,
      };
      await prefs.setString('cart_$customerId', jsonEncode(cartData));
    } catch (e) {
      print("Error saving cart to storage: $e");
    }
  }

  Future<void> _fetchFoodTrucks() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getFoodTrucks));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            int truckIdx = 0;
            _allFoodTrucks = List<Map<String, dynamic>>.from(data['data'].map((item) {
              truckIdx++;
              final double? realLat = double.tryParse(item['latitude']?.toString() ?? item['lat']?.toString() ?? '');
              final double? realLng = double.tryParse(item['longitude']?.toString() ?? item['lng']?.toString() ?? item['lon']?.toString() ?? '');

              final double storeLat = realLat ?? (LocationService.defaultLat + (((truckIdx * 3) % 7) - 3) * 0.0032);
              final double storeLng = realLng ?? (LocationService.defaultLng + (((truckIdx * 2) % 5) - 2) * 0.0035);

              final double distKm = LocationService.calculateDistanceKm(_customerLat, _customerLng, storeLat, storeLng);
              final String distText = LocationService.formatDistance(distKm);

              final String rawStatus = (item['status'] ?? (item['isOpen'] == false ? 'closed' : 'open')).toString().toLowerCase();
              final String currentStatus = (rawStatus == 'closed' || rawStatus == 'ปิด')
                  ? 'closed'
                  : (rawStatus == 'moving' || rawStatus == 'กำลังย้าย')
                      ? 'moving'
                      : 'open';

              return {
                'id': item['id'].toString(),
                'title': item['name'],
                'category': item['type'],
                'rating': '5.0',
                'img': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=200&auto=format&fit=crop',
                'isOpen': currentStatus == 'open',
                'status': currentStatus,
                'latitude': storeLat,
                'longitude': storeLng,
                'distance': distText,
                'distanceVal': distKm,
                'info': distText,
                'openTime': '09:00 - 20:00',
                'shopType': item['type'] ?? 'สตรีทฟู้ด',
                'menus': item['items'] != null ? List<Map<String, dynamic>>.from(item['items'].map((m) => {
                  'name': m['name'],
                  'price': m['price'].toString(),
                  'img': m['image_url'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=200&auto=format&fit=crop',
                  'category': 'เมนูหลัก',
                  // คอมเมนต์ตามคำขอผู้ใช้: จำลอง optionGroups ไว้เพื่อป้องกัน UI พัง อนาคตถ้า backend รองรับแล้วสามารถมาสานต่อส่วนนี้ได้
                  'optionGroups': [
                    {'title': 'ตัวเลือก (เลือก 1)', 'required': false, 'maxSelect': 1,
                     'options': [{'name': 'มาตรฐาน', 'price': 0}, {'name': 'พิเศษ', 'price': 10}]}
                  ],
                  'description': 'อร่อย สดใหม่'
                })) : [],
              };
            }));
            _allFoodTrucks.sort((a, b) => (a['distanceVal'] as double).compareTo(b['distanceVal'] as double));
            _isLoadingTrucks = false;
          });
          _syncStoreReviews();
        }
      }
    } catch (e) {
      print("Error fetching trucks: $e");
      setState(() => _isLoadingTrucks = false);
    }
  }
  // --- โค้ดดึงข้อมูลใหม่เมื่อเอานิ้วรูดหน้าจอ ---
  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchMyOrdersFromDB(); // สั่งให้ไปดึงข้อมูลจาก Database ใหม่
    });
    await _ordersFuture; // รอจนกว่าจะโหลดเสร็จ
  }

  Future<void> _confirmReceiveOrder(Map<String, dynamic> order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6))),
    );
    try {
      final String idStr = (order['order_id'] ?? order['id']).toString().replaceAll(RegExp(r'[^0-9]'), '');
      final int realOrderId = int.tryParse(idStr) ?? 0;
      final url = Uri.parse('${ApiConfig.baseUrl}/api/orders/$realOrderId/complete');
      final response = await http.put(url);
      if (!mounted) return;
      Navigator.pop(context); // ปิด Loading
      if (response.statusCode == 200) {
        setState(() {
          order['isCompleted'] = true;
          order['status'] = 'รับอาหารสำเร็จแล้ว';
        });
        _refreshOrders();
        _openRateStoreScreen(order);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: ${response.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }
  // ----------------------------------------
  Future<List<dynamic>> _fetchMyOrdersFromDB() async {
    try {
      final String customerId = widget.userData?['customer_id']?.toString() ?? '1';
      final String url = '${ApiConfig.baseUrl}/api/orders/customer/$customerId';
      print('👉 ดึงออเดอร์ของ customerId: $customerId จาก URL: $url');
      final response = await http.get(Uri.parse(url));
      print('👉 ผลการดึงออเดอร์: Status ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          return resData['data'] as List<dynamic>;
        } else {
          throw Exception('API แจ้งว่าไม่สำเร็จ: ${resData['message']}');
        }
      } else {
        throw Exception('เซิร์ฟเวอร์ตอบกลับ Error ${response.statusCode}');
      }
    } catch (e) {
      print(e.toString());
      throw Exception('ไม่สามารถดึงข้อมูลได้: $e');
    }
  }

  void _syncStoreReviews() {
    for (var truck in _allFoodTrucks) {
      final reviews = (truck['reviews'] as List<ReviewModel>?) ?? [];
      truck['reviewCount'] = reviews.length;
      if (reviews.isNotEmpty) {
        final avg = reviews.fold<double>(0.0, (sum, r) => sum + r.rating) / reviews.length;
        truck['rating'] = avg.toStringAsFixed(1);
      } else {
        truck['rating'] = '0.0';
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuantity(String menuName, String price, String imgUrl, int newQty, {StateSetter? modalSetter, String? storeTitle, String? optionsNote}) {
    setState(() {
      if (newQty <= 0) {
        _cartQuantities.remove(menuName);
        _cartPrices.remove(menuName);
        _cartImages.remove(menuName);
        _cartStores.remove(menuName);
        _cartOptions.remove(menuName);
      } else {
        _cartQuantities[menuName] = newQty;
        _cartPrices[menuName] = price;
        _cartImages[menuName] = imgUrl;
        if (storeTitle != null) _cartStores[menuName] = storeTitle;
        if (optionsNote != null) _cartOptions[menuName] = optionsNote;
      }
    });
    _saveCartToStorage();
    modalSetter?.call(() {});
  }

  int get _totalCartCount => _cartQuantities.values.fold(0, (sum, c) => sum + c);

  // ─────────────────────────────────────────
  // 📍 LOCATION PICKER (Customer Pin & GPS)
  // ─────────────────────────────────────────
  void _showLocationPicker() {
    LocationService.openAddressSelector(context, (selected) {
      if (selected is CustomerLocation) {
        setState(() {
          _customerLat = selected.latitude;
          _customerLng = selected.longitude;
          _currentLocation = selected.address;
        });
      } else if (selected is String) {
        setState(() {
          _currentLocation = selected.replaceAll('\n', ' ').split(' - ').last;
        });
      }
      _recalculateAllStoreDistances();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปเดตตำแหน่งของคุณเรียบร้อยแล้ว 📍'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _recalculateAllStoreDistances() {
    if (!mounted || _allFoodTrucks.isEmpty) return;
    setState(() {
      for (final store in _allFoodTrucks) {
        final double storeLat = (store['latitude'] as num?)?.toDouble() ?? LocationService.defaultLat;
        final double storeLng = (store['longitude'] as num?)?.toDouble() ?? LocationService.defaultLng;
        final double distKm = LocationService.calculateDistanceKm(_customerLat, _customerLng, storeLat, storeLng);
        final String distText = LocationService.formatDistance(distKm);
        store['distance'] = distText;
        store['distanceVal'] = distKm;
        store['info'] = distText;
      }
      _allFoodTrucks.sort((a, b) => (a['distanceVal'] as double).compareTo(b['distanceVal'] as double));
    });
  }

  // ─────────────────────────────────────────
  // 🗺️ OPEN EXTERNAL GOOGLE MAPS
  // ─────────────────────────────────────────
  void _openExternalGoogleMaps(String storeName, String distance) async {
    final store = _allFoodTrucks.firstWhere(
      (s) => s['title'] == storeName,
      orElse: () => <String, dynamic>{},
    );

    final lat = store['latitude'] as double?;
    final lng = store['longitude'] as double?;

    Uri mapUri;
    if (lat != null && lng != null) {
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(storeName)}');
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.map_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text('เปิด Google Maps: นำทางไปยัง "$storeName" (ห่าง $distance)', style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: const Color(0xFF0B1A30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🛒 CART & CHECKOUT SYSTEMS
  // ─────────────────────────────────────────
  void _clearStoreCart(String storeTitle) {
    final storeQtys = <String, int>{};
    final storePrices = <String, String>{};
    final storeImages = <String, String>{};
    final storeOptions = <String, String>{};

    final keysToRemove = <String>[];
    for (final key in _cartQuantities.keys) {
      final itemStore = _cartStores[key] ?? (_allFoodTrucks.isNotEmpty ? _allFoodTrucks.first['title'] as String : 'ร้านสตรีทฟู้ด');
      if (itemStore == storeTitle) {
        storeQtys[key] = _cartQuantities[key]!;
        storePrices[key] = _cartPrices[key] ?? '฿0';
        storeImages[key] = _cartImages[key] ?? '';
        storeOptions[key] = _cartOptions[key] ?? 'รสชาติมาตรฐาน ทางร้านปรุงปกติ';
        keysToRemove.add(key);
      }
    }

    if (storeQtys.isNotEmpty) {
      // คอมเมนต์: ยกเลิกการสร้างออเดอร์จำลองในเครื่อง เนื่องจากเปลี่ยนไปใช้ backend
      setState(() {
        for (final k in keysToRemove) {
          _cartQuantities.remove(k);
          _cartPrices.remove(k);
          _cartImages.remove(k);
          _cartStores.remove(k);
          _cartOptions.remove(k);
        }
      });
      _saveCartToStorage();
    }
  }

  void _showCartModal() {
    if (_cartQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีสินค้าในตะกร้า 🛒'), duration: Duration(seconds: 2)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyCartScreen(
          cartQuantities: _cartQuantities,
          cartPrices: _cartPrices,
          cartImages: _cartImages,
          cartStores: _cartStores,
          cartOptions: _cartOptions,
          allFoodTrucks: _allFoodTrucks,
          onUpdateQuantity: (name, price, img, newQty, {modalSetter, storeTitle, optionsNote}) {
            _updateQuantity(name, price, img, newQty, modalSetter: modalSetter, storeTitle: storeTitle, optionsNote: optionsNote);
          },
          onClearStoreCart: _clearStoreCart,
        ),
      ),
    ).then((_) {
      _saveCartToStorage();
      setState(() {});
    });
  }

  void _openNotificationsScreen() {
    final String customerId = widget.userData?['customer_id']?.toString() ?? '1';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationScreen(customerId: customerId)),
    );
  }

  void _showOrderStatusPopup(String status) {
    String explanation = 'ทางร้านกำลังเตรียมอาหารตามคำสั่งซื้อของคุณ โปรดรอก่อนเข้ารับสินค้า ณ รถเข็นในเวลาที่กำหนดครับ';
    if (status.contains('สำเร็จ')) {
      explanation = 'รายการสั่งซื้อนี้สำเร็จแล้ว คุณได้ทำการตรวจสอบและรับอาหาร ณ หน้าร้านเรียบร้อยแล้วครับ ขอบคุณที่ใช้บริการครับ';
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF00C7E6), size: 26),
            const SizedBox(width: 8),
            const Expanded(child: Text('สถานะคำสั่งซื้อ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)))),
          ],
        ),
        content: Text(explanation, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เข้าใจแล้ว', style: TextStyle(color: Color(0xFF00C7E6), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRatedDetailPopup(Map<String, dynamic> order) {
    final int score = int.tryParse(order['ratingScore']?.toString() ?? '5') ?? 5;
    // อ่านค่าคอมเมนต์จริง ถ้าลูกค้าไม่ได้พิมพ์ให้เป็นค่าว่าง
    final String comment = (order['comment'] as String?)?.trim() ?? ''; 
    // อ่านค่ารูปร้านค้า (ถ้ามี)
    final List<dynamic> images = (order['images'] as List<dynamic>?) ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFB300), size: 28),
            const SizedBox(width: 8),
            const Text('คะแนนรีวิวของคุณ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < score ? Icons.star : Icons.star_border,
                  color: index < score ? Colors.amber : const Color(0xFFCBD5E1),
                  size: 26,
                );
              }),
            ),
            // โชว์กล่องข้อความ ก็ต่อเมื่อลูกค้ามีการพิมพ์รีวิวเท่านั้น
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: Text('"$comment"', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
              ),
            ],
            // 🟢 โชว์รูปภาพแนบด้านล่างคอมเมนต์ (ถ้ามีการแนบรูป)
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: images.map((img) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        image: DecorationImage(
                          image: NetworkImage(img.toString()),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('คุณได้ทำการประเมินคำสั่งซื้อมื้อนี้เรียบร้อยแล้ว', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิดหน้าต่าง', style: TextStyle(color: Color(0xFF00C7E6), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  void _openOrderDetailScreen(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          order: order,
          allFoodTrucks: _allFoodTrucks,
          onNavigate: _openExternalGoogleMaps,
          onConfirmReceive: () {
            setState(() {
              order['isCompleted'] = true;
              order['status'] = 'รับอาหารสำเร็จแล้ว';
            });
            _refreshOrders();
            _openRateStoreScreen(order);
          },
        ),
      ),
    ).then((_) {
      _refreshOrders();
      setState(() {});
    });
  }

   void _showOrderFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (_) {
        // 🔴 เพิ่ม 'คืนเงิน' เข้าไปใน list options
        final options = ['สถานะทั้งหมด', 'กำลังปรุงอาหาร', 'รับอาหารสำเร็จแล้ว', 'คืนเงิน'];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เลือกแสดงสถานะคำสั่งซื้อ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              const SizedBox(height: 14),
              ...options.map((opt) {
                final sel = _orderFilter == opt;
                return ListTile(
                  onTap: () {
                    setState(() => _orderFilter = opt);
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
  // ─────────────────────────────────────────
  // ⭐ REVIEWS PAGE (full screen, not popup)
  // ─────────────────────────────────────────
  void _navigateToReviews(Map<String, dynamic> truck) {
    final storeTitle = truck['title'] as String;
    final orderCount = _orderHistory[storeTitle] ?? 0;
    final reviewCount = _reviewHistory[storeTitle] ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewsPage(
        truck: truck,
        isGuestMode: false,
        canWriteReview: orderCount > reviewCount,
        onReviewSubmitted: () {
          _reviewHistory[storeTitle] = (_reviewHistory[storeTitle] ?? 0) + 1;
          _syncStoreReviews();
          setState(() {});
        },
      )),
    );
  }

  // ─────────────────────────────────────────
  // 🏬 STORE DETAILS PAGE (full screen)
  // ─────────────────────────────────────────
  void _showStoreDetails(Map<String, dynamic> truck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailPage(
        truck: truck,
        isGuestMode: false,
        customerId: widget.userData?['customer_id']?.toString() ?? '1',
        onNavigate: _openExternalGoogleMaps,
        cartQuantities: _cartQuantities,
        cartPrices: _cartPrices,
        cartImages: _cartImages,
        cartStores: _cartStores,
        cartOptions: _cartOptions,
        allFoodTrucks: _allFoodTrucks,
        onUpdateQuantity: (name, price, img, newQty, {modalSetter, storeTitle, optionsNote}) {
          _updateQuantity(name, price, img, newQty, modalSetter: modalSetter, storeTitle: storeTitle ?? truck['title'] as String, optionsNote: optionsNote);
        },
        onViewReviews: () => _navigateToReviews(truck),
        onSwitchTab: (index) => setState(() => _currentIndex = index),
        onClearCart: _clearStoreCart,
      )),
    ).then((_) {
      _saveCartToStorage();
      setState(() {});
    });
  }


  // ─────────────────────────────────────────
  // ALL STORES
  // ─────────────────────────────────────────
  void _navigateToAllStores() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AllStoresScreen(
      allFoodTrucks: _allFoodTrucks,
      onStoreTap: _showStoreDetails,
      onNavigate: _openExternalGoogleMaps,
    )));
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: [_buildHomeTab(), _buildOrdersTab(), _buildProfileTab()])),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4))]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF00C7E6),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            if (i == 1) {
              _refreshOrders();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'คำสั่งซื้อ'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
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

  // ─────────────────────────────────────────
  // HOME TAB
  // ─────────────────────────────────────────
  Widget _buildHomeTab() {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFE5EEF5), shape: BoxShape.circle), child: const Icon(Icons.person, color: Color(0xFF0B1A30), size: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _showLocationPicker,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ตำแหน่งปัจจุบัน (พื้นที่ค้นหาร้าน)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Row(children: [
                        Flexible(child: Text(_currentLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)), overflow: TextOverflow.ellipsis, maxLines: 1)),
                        const SizedBox(width: 2),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF0B1A30)),
                      ]),
                    ],
                  ),
                ),
              ),
              Stack(clipBehavior: Clip.none, children: [
                _buildIconBtn(Icons.shopping_cart_outlined, onTap: _showCartModal),
                if (_totalCartCount > 0)
                  Positioned(right: 2, top: 2, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF00C7E6), shape: BoxShape.circle), child: Text('$_totalCartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
              ]),
              const SizedBox(width: 8),
              _buildIconBtn(Icons.notifications_none_outlined, onTap: _openNotificationsScreen),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อร้านในพื้นที่ของคุณ...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),

          // ── Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _categories.map((cat) => _buildCategoryChip(cat, isSelected: _selectedCategory == cat)).toList()),
          ),
          const SizedBox(height: 24),

          // ── Nearby stores (horizontal)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ร้านรถเข็นใกล้คุณ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              GestureDetector(onTap: _navigateToAllStores, child: const Text('ดูทั้งหมด', style: TextStyle(fontSize: 13, color: Color(0xFF00C7E6), fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 24),

          // ── Top rated
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('⭐ ร้านยอดฮิต', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
              GestureDetector(
                onTap: () => setState(() => _sortAscending = !_sortAscending),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE5EEF5), shape: BoxShape.circle), child: Icon(_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18, color: const Color(0xFF00C7E6))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...topRated.map((shop) => _buildTopRatedCard(shop)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Nearby horizontal card (องค์ประกอบตรงตามหน้า ร้านรถเข็นทั้งหมด)
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

  // ── Top rated card (ดีไซน์กะทัดรัด ดาวเดียว ⭐️ และตัดคำว่า "เริ่มขาย")
  Widget _buildTopRatedCard(Map<String, dynamic> shop) {
    final bool isClosed = shop['status'] == 'closed';
    String opTime = (shop['openTime'] ?? '').toString().replaceAll('เริ่มขาย ', '').replaceAll(' น.', '');
    return GestureDetector(
      onTap: isClosed
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ร้านนี้ปิดให้บริการอยู่ 🔒'), backgroundColor: Color(0xFF64748B)))
          : () => _showStoreDetails(shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 14, offset: const Offset(0, 3))]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: isClosed ? 0.4 : 1.0,
                  child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(shop['img'], width: 78, height: 78, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 78, height: 78, color: const Color(0xFFF4F5F7), child: const Icon(Icons.storefront, color: Color(0xFF94A3B8))))),
                ),
                Positioned(top: 4, left: 4, child: _buildStatusBadge(shop['status'] ?? 'open')),
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
                  Text(shop['shopType'] ?? 'ร้านสตรีทฟู้ด', style: TextStyle(fontSize: 11.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFFFFB300), size: 17),
                      const SizedBox(width: 3),
                      Text(shop['rating'], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF0B1A30))),
                      Text(' (${shop['reviewCount']})', style: TextStyle(fontSize: 11.5, color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
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
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // ORDERS TAB (คำสั่งซื้อของฉัน)
  // ─────────────────────────────────────────
  // ─────────────────────────────────────────
  // ORDERS TAB (แท็บคำสั่งซื้อ)
  // ─────────────────────────────────────────
  Widget _buildOrdersTab() {
    return Container(
      color: const Color(0xFFF4F7FA), // สีพื้นหลังเทาอ่อนตามภาพ
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Header (ปุ่ม Back แบบไอคอนล้วน และ ชื่อหน้า)
          Container(
            padding: const EdgeInsets.only(top: 50, left: 8, right: 8, bottom: 10), // ปรับระยะให้บางลงเหมือน AppBar ปกติ
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0; // กลับไปที่แท็บหน้าหลัก
                    });
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'คำสั่งซื้อของฉัน',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // ถ่วงน้ำหนักขวาให้ตรงกลางพอดีกับปุ่มฝั่งซ้าย
              ],
            ),
          ),
          
          // ── 2. Filter Dropdown "สถานะทั้งหมด v"
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 20, 10),
            child: GestureDetector(
              onTap: _showOrderFilterSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_orderFilter, style: const TextStyle(fontSize: 14.5, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF334155)),
                ],
              ),
            ),
          ),

          // ── 3. Orders List (แสดงรายการการ์ด)
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF00C7E6),
              onRefresh: _refreshOrders, // 👈 ดึงจอลงเพื่อโหลดข้อมูลซ้ำได้ตลอดเวลา
              child: FutureBuilder<List<dynamic>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  Widget buildScrollableMessage(String message, {Color color = const Color(0xFF94A3B8)}) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: color, fontSize: 15, height: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6)));
                  } else if (snapshot.hasError) {
                    return buildScrollableMessage('เซิร์ฟเวอร์ยังไม่พร้อม/เกิดข้อผิดพลาด\n(รูดหน้าจอลงเพื่อลองใหม่อีกครั้ง)', color: Colors.red);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return buildScrollableMessage('ยังไม่มีประวัติคำสั่งซื้อ\n(รูดหน้าจอลงเพื่อดึงข้อมูลใหม่)');
                  }

                  final allOrders = snapshot.data!;
                  final filteredOrders = allOrders.where((o) {
                    final status = (o['status'] ?? '').toString().trim();
                    final isCompleted = status == 'รับอาหารสำเร็จแล้ว' || (o['isCompleted'] == true);
                    if (_orderFilter == 'สถานะทั้งหมด') return true;
                    if (_orderFilter == 'กำลังปรุงอาหาร') return !isCompleted && status != 'คืนเงิน' && status != 'ปฏิเสธ';
                    if (_orderFilter == 'รับอาหารสำเร็จแล้ว') return isCompleted && status != 'คืนเงิน' && status != 'ปฏิเสธ';
                    if (_orderFilter == 'คืนเงิน') return status == 'คืนเงิน' || status == 'ปฏิเสธ';
                    return true;
                  }).toList();
                  
                  if (filteredOrders.isEmpty) {
                    return buildScrollableMessage('ไม่พบคำสั่งซื้อในสถานะนี้\n(รูดหน้าจอลงเพื่อดึงข้อมูลใหม่)');
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index] as Map<String, dynamic>;
                      final int orderId = int.tryParse(order['order_id']?.toString() ?? order['id']?.toString() ?? '0') ?? 0;
                      
                      final double rawTotal = double.tryParse((order['totalPrice']?.toString() ?? order['total_price']?.toString() ?? '0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                      final String displayTotal = rawTotal > 0 
                          ? rawTotal.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},') 
                          : (order['totalPrice']?.toString() ?? order['total_price']?.toString() ?? '0.00');
                      
                      final formattedOrder = {
                        'id': '#ORD-$orderId',
                        'order_id': orderId,
                        'merchant_id': order['merchant_id'] ?? 1,
                        'storeTitle': order['storeTitle'] ?? order['merchant_name'] ?? 'ไม่ระบุร้านค้า',
                        'date': order['date']?.toString().substring(0, 10) ?? order['created_at']?.toString().substring(0, 10) ?? '-',
                        'totalPrice': '฿$displayTotal',
                        'total_price': rawTotal,
                        'itemsCount': order['itemsCount'] ?? (order['items'] is List ? (order['items'] as List).fold<int>(0, (sum, item) => sum + (int.tryParse(item['qty']?.toString() ?? '1') ?? 1)) : 0),
                        'status': order['status'] ?? 'รอชำระเงิน',
                        'isCompleted': order['status'] == 'รับอาหารสำเร็จแล้ว' || (order['isCompleted'] == true),
                        
                        // 🟢 อัปเดต 4 บรรทัดนี้ เพื่อให้รับค่ารีวิวและรูปภาพจาก Backend โดยตรง
                        'isRated': order['ratingScore'] != null || order['rating'] != null || order['isRated'] == true || order['isRated'] == 1,
                        'ratingScore': order['ratingScore'] ?? order['rating'] ?? _tempRatings[orderId] ?? 5,
                        'comment': order['comment'] ?? _tempComments[orderId] ?? '',
                        'images': (order['images'] is String) ? jsonDecode(order['images']) : (order['images'] ?? []),
                        
                        'items': order['items'] ?? [],
                        'refund_status': order['refund_status'],
                      };
                      return _buildRealOrderCard(formattedOrder);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openRateStoreScreen(Map<String, dynamic> order) {
    final String storeTitle = (order['storeTitle'] ?? order['merchant_name'] ?? 'ร้านค้าทั่วไป').toString();
    Map<String, dynamic> truck = {
      'id': (order['merchant_id'] ?? order['merchantId'] ?? 1).toString(),
      'title': storeTitle,
      'shopType': 'ร้านอาหารสตรีทฟู้ด',
      'img': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=200&auto=format&fit=crop',
    };
    if (_allFoodTrucks.isNotEmpty) {
      truck = _allFoodTrucks.firstWhere(
        (t) => t['title'] == storeTitle,
        orElse: () => _allFoodTrucks.first,
      );
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RateStoreScreen(
          truck: truck,
          onSubmitted: (stars, comment, images) async {
            try {
              // 1. อัปโหลดรูปภาพทั้งหมดก่อน (ถ้ามีรูป)
              List<String> uploadedImageUrls = [];
              if (images.isNotEmpty) {
                print('==== กำลังอัปโหลดรูปภาพ ${images.length} รูป ====');
                for (String path in images) {
                  try {
                    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/orders/upload-image'));
                    request.files.add(await http.MultipartFile.fromPath('image', path));
                    var res = await request.send();
                    if (res.statusCode == 200) {
                      var resBody = await res.stream.bytesToString();
                      var data = jsonDecode(resBody);
                      if (data['success'] == true) {
                        // 🟢 ดักจับทั้ง imageUrl และ image_url กันพลาด (เผื่อ backend ใช้ชื่อคีย์ไหน)
                        final String newUrl = data['imageUrl']?.toString() ?? data['image_url']?.toString() ?? data['url']?.toString() ?? '';
                        if (newUrl.isNotEmpty) {
                          uploadedImageUrls.add(newUrl);
                          print('อัปโหลดสำเร็จ: $newUrl');
                        }
                      }
                    } else {
                      print('อัปโหลดรูปล้มเหลว Status: ${res.statusCode}');
                    }
                  } catch (e) {
                    print('Error uploading image $path: $e');
                  }
                }
              }

              // 2. สกัดเอาแค่ตัวเลขล้วนๆ (เอา #ORD- ออก) แปลงเป็นตัวเลข (int) ก่อนส่ง
              final String idStr = order['id'].toString().replaceAll(RegExp(r'[^0-9]'), '');
              final int realOrderId = int.tryParse(idStr) ?? 0;

              // 👉 ดึง customer_id จริงๆ จาก userData 
              final int customerId = int.tryParse(widget.userData?['customer_id']?.toString() ?? '1') ?? 1;

              final url = '${ApiConfig.baseUrl}/api/orders/review';
             
              print('==== กำลังส่งรีวิว ====');
              print('ส่ง order_id: $realOrderId, merchant_id: ${order['merchantId']}, customer_id: $customerId');
             
              final response = await http.post(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'order_id': realOrderId,
                  'merchant_id': int.tryParse(order['merchant_id']?.toString() ?? order['merchantId']?.toString() ?? '1') ?? 1, // 🟢 เติมกลับมาแล้วครับ!
                  'customer_id': customerId, // 🟢 เติมกลับมาแล้วครับ!
                  'rating': stars,
                  'comment': comment,
                  'images': uploadedImageUrls, // 🟢 ส่ง URL รูปภาพจริงๆ ที่อัปโหลดผ่านแล้วไปบันทึก
                }),
              );

              print('Status Code: ${response.statusCode}');
              print('Response: ${response.body}');

              if (response.statusCode == 200 || response.statusCode == 201) {
                if (!mounted) return;
                setState(() {
                  // 🌟 แอบเซฟคอมเมนต์และดาวเก็บไว้ในเครื่อง (Cache)
                  _tempRatings[realOrderId] = stars;
                  _tempComments[realOrderId] = comment;
                  
                  order['isRated'] = true;
                  order['ratingScore'] = stars;
                  order['comment'] = comment;
                  order['images'] = uploadedImageUrls;
                });
                _syncStoreReviews();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ส่งรีวิวสำเร็จและบันทึกลงฐานข้อมูลแล้ว 🌟'), 
                    backgroundColor: Color(0xFF00C7E6), 
                    duration: Duration(seconds: 2)
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ไม่สามารถส่งรีวิวได้ (Error: ${response.statusCode})')),
                );
              }
            } catch (e) {
              if (!mounted) return;
              print('Error submitting review: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildRealOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? [];
    final isCompleted = order['isCompleted'] == true;
    final isRated = order['isRated'] == true;
    final storeTitle = order['storeTitle'] ?? 'ร้านค้า';
    
    // ดึงคอมเมนต์ (ถ้ามี)
    final ratingScore = order['ratingScore']?.toString() ?? '5';
    final ratingComment = order['comment'] ?? 'รสชาติอร่อยมากครับ'; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20), // เพิ่มระยะขอบให้ดูคลีนเหมือนในภาพ
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Store Header (ชื่อร้าน ไอคอน และวันที่)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  final truck = _allFoodTrucks.firstWhere(
                    (t) => t['title'] == storeTitle, 
                    orElse: () => _allFoodTrucks.isNotEmpty ? _allFoodTrucks.first : <String, dynamic>{'title': storeTitle, 'menus': []},
                  );
                  if (truck.containsKey('id')) {
                    _showStoreDetails(truck);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: Color(0xFF475569), size: 20),
                    const SizedBox(width: 8),
                    Text(storeTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Color(0xFF0B1A30))),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 16),
                  ],
                ),
              ),
              // 🟢 ตัดเอาเฉพาะ "วันที่" มาโชว์ (ตัดเวลาทิ้งเพื่อให้การ์ดดูคลีน)
              Text((order['date'] ?? '').split(' ').take(3).join(' '), style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 18),

          // ── 2. Items Display & Price (รองรับการแสดงรูป 1 รูป หรือเรียงกัน 2 รูปตามภาพเป๊ะ)
          GestureDetector(
            onTap: () {
              bool isRefund = order['status'] == 'คืนเงิน' || order['status'] == 'ปฏิเสธ';
              if (isRefund) {
                final int orderId = int.tryParse((order['order_id'] ?? order['id'])?.toString() ?? '0') ?? 0;
                
                // 🟢 อ่านค่า refund_status จาก Backend โดยตรง (ถ้าไม่มีให้ถือว่า Pending ไว้ก่อน)
                String refundStatusDB = order['refund_status']?.toString().toLowerCase() ?? 'pending';
                bool isSuccess = refundStatusDB == 'success';
                
                Navigator.push(context, MaterialPageRoute(builder: (context) => RefundDetailsScreen(
                  refundData: {
                    'order_id': 'ORD-$orderId',
                    'charge_id': 'CHG-$orderId',
                    'refund_amount': double.tryParse((order['total_price']?.toString() ?? order['totalPrice']?.toString() ?? '฿0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                    'refund_status': isSuccess ? 'Success' : 'Pending',
                    'store_name': order['merchant_name'] ?? order['storeTitle'] ?? 'ร้านค้า',
                  }
                )));
              } else {
                _openOrderDetailScreen(order);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: items.length == 1
                      // กรณีมี 1 รายการ -> โชว์รูปและชื่อด้านข้าง (แบบไก่ย่างเจ๊จิ๋ว)
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                (items[0]['img']?.toString().isNotEmpty == true && items[0]['img'] != 'null') 
                                    ? items[0]['img'] 
                                    : 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80', // รูปแทนเมื่อไม่มีรูปจาก DB
                                width: 62, 
                                height: 62, 
                                fit: BoxFit.cover, 
                                errorBuilder: (_, __, ___) => Container(width: 62, height: 62, color: const Color(0xFFF4F5F7), child: const Icon(Icons.fastfood, size: 24, color: Color(0xFF94A3B8)))
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(items[0]['name'] ?? '', style: const TextStyle(fontSize: 14.5, color: Color(0xFF334155), fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        )
                      // กรณีมีมากกว่า 1 รายการ -> โชว์รูปเรียงกันและชื่อด้านล่างรูป (แบบร้านนมอุ่น)
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: items.map<Widget>((item) {
                              return Container(
                                width: 58,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        (item['img']?.toString().isNotEmpty == true && item['img'] != 'null') 
                                            ? item['img'] 
                                            : 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80', // รูปแทนเมื่อไม่มีรูปจาก DB
                                        width: 58, 
                                        height: 58, 
                                        fit: BoxFit.cover, 
                                        errorBuilder: (_, __, ___) => Container(width: 58, height: 58, color: const Color(0xFFF4F5F7), child: const Icon(Icons.fastfood, size: 24, color: Color(0xFF94A3B8)))
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item['name'] ?? '', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // ฝั่งขวา: ราคาและจำนวนรายการ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(order['totalPrice'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Color(0xFF0B1A30))),
                    const SizedBox(height: 4),
                    Text('${order['itemsCount']} รายการ >', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── 3. Rating Box (กรณีรีวิวแล้ว จะมีกล่องโชว์คะแนนดาว)
          if (isRated) ...[
            GestureDetector(
              onTap: () => _showRatedDetailPopup(order), // ทำให้กดแล้วเด้งป๊อปอัพได้
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Text(order['ratingScore']?.toString() ?? '5', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0B1A30))),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
                    
                    // ถ้ามีข้อความรีวิวให้โชว์ ถ้าไม่มีให้ซ่อนข้อความไปเลย
                    if ((order['comment']?.toString().trim() ?? '').isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('"${order['comment']}"', style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ] else ...[
                      const Spacer(), // ถ้าไม่มีข้อความ ดันลูกศรไปชิดขวาสุด
                    ],
                    
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 16),
                  ],
                ),
              ),
            ),
          ],

          // ถ้ายังไม่รีวิว จะมีเส้นคั่นบางๆ แบบในภาพร้านเจ๊จิ๋ว
          if (!isRated) const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (!isRated) const SizedBox(height: 16),

          // ── 4. Footer (สถานะ & ปุ่มให้คะแนน / สั่งใหม่)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 👈 ข้อความสถานะที่สั้นลง และทำให้กดเข้าหน้ารายละเอียดสถานะได้
              GestureDetector(
                onTap: () {
                  bool isRefund = order['status'] == 'คืนเงิน' || order['status'] == 'ปฏิเสธ';
                  if (isRefund) {
                    final int orderId = int.tryParse((order['order_id'] ?? order['id'])?.toString() ?? '0') ?? 0;
                    
                    // 🟢 อ่านค่า refund_status จาก Backend โดยตรง
                    String refundStatusDB = order['refund_status']?.toString().toLowerCase() ?? 'pending';
                    bool isSuccess = refundStatusDB == 'success';
                    
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RefundDetailsScreen(
                      refundData: {
                        'order_id': 'ORD-$orderId',
                        'charge_id': 'CHG-$orderId',
                        'refund_amount': double.tryParse((order['total_price']?.toString() ?? order['totalPrice']?.toString() ?? '฿0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                        'refund_status': isSuccess ? 'Success' : 'Pending', 
                        'store_name': order['merchant_name'] ?? order['storeTitle'] ?? 'ร้านค้า',
                      }
                    )));
                  } else {
                    _openOrderDetailScreen(order);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (context) {
                        bool isRefund = order['status'] == 'คืนเงิน' || order['status'] == 'ปฏิเสธ';
                        
                        // 🟢 อ่านค่า refund_status จาก Backend โดยตรงสำหรับแสดงข้อความ
                        String refundStatusDB = order['refund_status']?.toString().toLowerCase() ?? 'pending';
                        bool isSuccess = refundStatusDB == 'success';
                        
                        String displayStatusText = isCompleted ? 'รับอาหารสำเร็จ' : (order['status']?.toString().split(' (').first ?? 'กำลังปรุงอาหาร');
                        
                        if (order['status']?.toString().trim() == 'พร้อมรับ' && !isCompleted) {
                          displayStatusText = 'พร้อมรับอาหาร';
                        } else if (isRefund) {
                          displayStatusText = isSuccess ? 'คืนเงินสำเร็จ' : 'รอดำเนินการ';
                        }
                        
                        return Text(
                          displayStatusText,
                          style: TextStyle(
                            fontSize: 14, 
                            color: (order['status']?.toString().trim() == 'พร้อมรับ' && !isCompleted)
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF0B1A30),
                            fontWeight: FontWeight.w800
                          ),
                        );
                      }
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF00C7E6)), 
                  ],
                ),
              ),
              
              Row(
                children: [
                  // ปุ่มยืนยันรับอาหาร เมื่อสถานะเป็น "พร้อมรับ"
                  if (order['status']?.toString().trim() == 'พร้อมรับ' && !isCompleted) ...[
                    ElevatedButton(
                      onPressed: () => _confirmReceiveOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C7E6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('ยืนยันรับอาหาร', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // ซ่อนปุ่มให้คะแนนไว้ก่อน ถ้าอาหารยังทำไม่เสร็จ (โชว์เฉพาะตอนรับอาหารแล้ว)
                  if (isCompleted) ...[
                    OutlinedButton(
                      onPressed: isRated ? () => _showRatedDetailPopup(order) : () => _openRateStoreScreen(order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(isRated ? 'ดูการให้คะแนน' : 'ให้คะแนนร้าน', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // ปุ่ม สั่งใหม่สีฟ้า
                  if (isCompleted || order['status']?.toString().trim() != 'พร้อมรับ')
                    ElevatedButton(
                      onPressed: () {
                        final truck = _allFoodTrucks.firstWhere(
                          (t) => t['title'] == storeTitle, 
                          orElse: () => _allFoodTrucks.isNotEmpty ? _allFoodTrucks.first : <String, dynamic>{'title': storeTitle, 'menus': []},
                        );
                        if (truck.containsKey('id')) {
                          _showStoreDetails(truck);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C7E6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('สั่งใหม่', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  // =========================================
  // 3. แท็บโปรไฟล์ (ดีไซน์ใหม่ คลีนสุด ไม่มีประวัติ)
  // =========================================
  Widget _buildProfileTab() {
    final String customerId = widget.userData?['customer_id']?.toString() ?? '1';
    final String name = widget.userData?['name_surname'] ?? widget.userData?['name'] ?? 'สมชาย จันทร์ฉาย';
    final String email = widget.userData?['email'] ?? 'somchai@email.com';
    final String phone = widget.userData?['phone'] ?? '081-234-5678';
    final String? profileImage = widget.userData?['profile_image'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
         
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('โปรไฟล์ของฉัน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
          ),
          const SizedBox(height: 35),

          // ── ข้อมูลบัญชีและปุ่มแก้ไข ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final updatedData = await Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          customerId: customerId,
                          initialName: name,
                          initialPhone: phone,
                          initialEmail: email,
                          initialImage: profileImage,
                        )
                      )
                    );

                    if (updatedData != null && updatedData is Map) {
                      setState(() {
                        if (widget.userData != null) {
                          widget.userData!['name_surname'] = updatedData['name'];
                          widget.userData!['name'] = updatedData['name'];
                          widget.userData!['phone'] = updatedData['phone'];
                          widget.userData!['email'] = updatedData['email'];
                          if (updatedData['profile_image'] != null) {
                            widget.userData!['profile_image'] = updatedData['profile_image'];
                          }
                        }
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                            ? NetworkImage(profileImage)
                            : null,
                        child: (profileImage == null || profileImage.isEmpty)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!)),
                          child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                      const SizedBox(height: 4),
                      Text(phone, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C7E6), elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: () async {
                            // 🔴 ส่งข้อมูลเดิมไป และรอรับข้อมูลใหม่ที่แก้ไขเสร็จกลับมา
                            final updatedData = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  customerId: customerId,
                                  initialName: name,
                                  initialPhone: phone,
                                  initialEmail: email,
                                  initialImage: profileImage,
                                )
                              )
                            );

                            // 🔴 ถ้ามีการกดปุ่ม "บันทึก" (ส่งข้อมูลกลับมา) ไม่ออกเฉยๆ ให้ทำการ setState
                            if (updatedData != null && updatedData is Map) {
                              setState(() {
                                // อัปเดตข้อมูลลงในตัวแปร widget.userData
                                if (widget.userData != null) {
                                  widget.userData!['name_surname'] = updatedData['name'];
                                  widget.userData!['name'] = updatedData['name']; // อัปเดตเผื่อไว้ทั้ง 2 key
                                  widget.userData!['phone'] = updatedData['phone'];
                                  widget.userData!['email'] = updatedData['email'];
                                  if (updatedData['profile_image'] != null) {
                                    widget.userData!['profile_image'] = updatedData['profile_image'];
                                  }
                                }
                              });
                            }
                          },
                          child: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          _buildCleanMenuTile(
            Icons.storefront_outlined, 'ร้านที่ติดตาม', 
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => FollowedShopsScreen(
                    customerId: customerId,
                    allShops: _allFoodTrucks, // 🔴 ส่งข้อมูลร้านทั้งหมดไป
                    onShopTap: (truck) {
                      // 🔴 เมื่อกดร้าน ให้เด้งเปิดหน้ารายละเอียดร้าน (StoreDetails)
                      _showStoreDetails(truck);
                    },
                  )
                )
              );
            },
          ),
          
          _buildCleanMenuTile(
            Icons.settings_outlined, 'ตั้งค่าการแจ้งเตือน & บัญชี',
            onTap: () {
              // ลิงก์ไปหน้า Settings ที่เราทำไว้เรียบร้อยแล้ว
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => BuyerSettingsScreen(customerId: customerId))
              );
            },
          ),
          
          _buildCleanMenuTile(
            Icons.headset_mic_outlined, 'ติดต่อช่วยเหลือ',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
            },
          ),
          
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider(height: 1, color: Colors.grey[200])),
          
          _buildCleanMenuTile(
            Icons.logout_rounded, 'ออกจากระบบ', isDestructive: true, 
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?', style: TextStyle(color: Color(0xFF475569))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
                    TextButton(
                      onPressed: () async {
                        await _saveCartToStorage();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                      },
                      child: const Text('ออกจากระบบ', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 40),
          Text('App version 1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
 
  Widget _buildCleanMenuTile(IconData icon, String title, {String? trailingText, bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0B1A30);
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 18),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color))),
            if (trailingText != null) ...[
              Text(trailingText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1A30))),
              const SizedBox(width: 12),
            ],
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProfileMenuTile({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B1A30))),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B))),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 4))]),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF0B1A30)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0B1A30))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  Widget _buildIconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))]), child: Icon(icon, color: const Color(0xFF0B1A30), size: 20)),
    );
  }

  Widget _buildCategoryChip(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C7E6) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF0B1A30), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}




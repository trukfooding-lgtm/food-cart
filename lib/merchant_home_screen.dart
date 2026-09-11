import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'merchant_menu.dart';
import 'merchant_map.dart';
import 'merchant_accept_order.dart';
import 'merchant_rejected_order.dart';
import 'merchant_order_status.dart';
import 'merchant_profile_screen.dart';
import 'merchant_notification_page.dart';
import 'api.config.dart';

class MerchantHomeScreen extends StatefulWidget {
  // รองรับการส่งข้อมูลผู้ค้าจากหน้า Login
  final Map<String, dynamic>? merchantData;

  const MerchantHomeScreen({super.key, this.merchantData});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _selectedIndex = 0;
  String _selectedOrderStatus = 'ทั้งหมด';

  // สถานะร้านค้าปัจจุบัน (เริ่มต้นที่ เปิดร้าน)
  String _storeStatus = 'เปิดร้าน';
  Timer? _merchantRefreshTimer;
  bool _isRefreshingMerchantData = false;

  final List<Map<String, dynamic>> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _refreshMerchantData();
    _merchantRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshMerchantData(),
    );
  }

  @override
  void dispose() {
    _merchantRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshMerchantData() async {
    if (_isRefreshingMerchantData) return;
    _isRefreshingMerchantData = true;
    try {
      await _loadMerchantOrders();
      await _loadSalesSummary();
      await _loadStoreStatus();
    } finally {
      _isRefreshingMerchantData = false;
    }
  }

  Future<void> _loadStoreStatus() async {
    final merchantId = widget.merchantData?['id'];
    if (merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantStatus(merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }
      setState(() {
        _storeStatus = body['status']?.toString() ?? 'ปิดร้าน';
      });
    } catch (error) {
      debugPrint('Error loading merchant status on home: $error');
    }
  }

  Future<bool> _updateStoreStatus(String status) async {
    final merchantId = widget.merchantData?['id'];
    if (merchantId == null) return false;
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantStatus(merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return false;
      }
      setState(() => _storeStatus = status);
      return true;
    } catch (error) {
      debugPrint('Error updating merchant status on home: $error');
      return false;
    }
  }

  Future<void> _loadMerchantOrders() async {
    final merchantId = widget.merchantData?['id'];
    if (merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantOrders(merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }
      final orders = List<Map<String, dynamic>>.from(
        (body['data'] as List).map((raw) {
          final data = Map<String, dynamic>.from(raw);
          final status = data['merchant_status']?.toString() ?? 'ใหม่';
          final orderedAt = DateTime.tryParse(
            data['ordered_at']?.toString() ?? '',
          )?.toLocal();
          final rejectedAt = DateTime.tryParse(
            data['rejected_at']?.toString() ?? '',
          )?.toLocal();
          final color = status == 'เสร็จสิ้น'
              ? const Color(0xFF10B981)
              : status == 'ยกเลิก'
              ? const Color(0xFFEF4444)
              : status == 'ใหม่'
              ? const Color(0xFF00C7E6)
              : const Color(0xFFF59E0B);
          final icon = status == 'เสร็จสิ้น'
              ? Icons.check_circle_outline
              : status == 'กำลังปรุง'
              ? Icons.access_time
              : status == 'รอรับสินค้า'
              ? Icons.shopping_bag_outlined
              : Icons.receipt_outlined;
          String displayTime(DateTime? value) => value == null
              ? '-'
              : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} น.';
          return {
            'databaseId': data['order_id'],
            'merchantId': merchantId,
            'orderId': '#ORD-${data['order_id']}',
            'customer': data['customer_name'] ?? 'ไม่ระบุชื่อลูกค้า',
            'details': data['items_summary'] ?? '-',
            'price': '฿${data['total_price']}',
            'time': displayTime(orderedAt),
            'paymentTime': displayTime(orderedAt),
            'status': status,
            'statusColor': color,
            'icon': icon,
            'rejectReason': data['reject_reason'],
            'rejectedAt': rejectedAt,
          };
        }),
      );
      setState(() {
        _allOrders
          ..clear()
          ..addAll(orders);
      });
    } catch (error) {
      debugPrint('Error loading merchant orders: $error');
    }
  }

  // 🟢 ข้อมูลยอดขายรายวัน (7 วันล่าสุด) สำหรับกราฟ, ยอดขายวันนี้ และยอดขายสัปดาห์นี้ — กดที่แท่งกราฟหรือการ์ดสรุปเพื่อดูรายละเอียดได้
  List<Map<String, dynamic>> _weeklySalesData = [];
  double _todaySales = 0;
  double _weekSales = 0;
  double _availableBalance = 0;
  int _todayOrderCount = 0;

  Future<void> _loadSalesSummary() async {
    final merchantId = widget.merchantData?['id'];
    if (merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantSalesSummary(merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }
      final rows = List<Map<String, dynamic>>.from(
        (body['daily'] as List).map((row) => Map<String, dynamic>.from(row)),
      );
      final now = DateTime.now();
      final amounts = <String, int>{};
      final counts = <String, int>{};
      String dateKey(DateTime date) =>
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      for (final row in rows) {
        final date = DateTime.parse(row['sale_date'].toString()).toLocal();
        final key = dateKey(date);
        amounts[key] =
            double.tryParse(row['total_sales'].toString())?.round() ?? 0;
        counts[key] = int.tryParse(row['total_orders'].toString()) ?? 0;
      }
      final dates = List.generate(
        7,
        (index) => DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: 6 - index)),
      );
      final values = dates.map((date) => amounts[dateKey(date)] ?? 0).toList();
      final maxAmount = values.fold<int>(
        0,
        (current, value) => value > current ? value : current,
      );
      const labels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
      setState(() {
        _weeklySalesData = List.generate(7, (index) {
          final amount = values[index];
          return {
            'label': labels[dates[index].weekday - 1],
            'amount': amount,
            'height': maxAmount == 0 ? 0.0 : amount / maxAmount * 140,
            'isToday': index == 6,
          };
        });
        _todaySales = values.last.toDouble();
        _weekSales = values
            .fold<int>(0, (sum, value) => sum + value)
            .toDouble();
        _todayOrderCount = counts[dateKey(dates.last)] ?? 0;
        _availableBalance =
            double.tryParse(body['available_balance'].toString()) ?? 0;
      });
    } catch (error) {
      debugPrint('Error loading merchant sales summary: $error');
    }
  }

  // 🟢 รายชื่อแอปธนาคาร/กระเป๋าเงินยอดนิยม พร้อม URL scheme สำหรับเปิดแอปภายนอกเพื่อถอนเงิน
  // หมายเหตุ: หากเปิดแอปไม่สำเร็จ (ยังไม่ได้ติดตั้ง) ระบบจะพาไปที่หน้าเว็บของธนาคารเพื่อดาวน์โหลดแอปแทน
  final List<Map<String, dynamic>> _bankApps = const [
    {
      'name': 'K PLUS (กสิกรไทย)',
      'scheme': 'kplus://',
      'storeUrl': 'https://kplus.onelink.me/8jvv/kplusshortcut',
      'color': Color(0xFF138F2D),
    },
    {
      'name': 'SCB EASY (ไทยพาณิชย์)',
      'scheme': 'scbeasy://',
      'storeUrl':
          'https://www.scb.co.th/th/personal-banking/digital-banking/scb-easy-app.html',
      'color': Color(0xFF4E2E7F),
    },
    {
      'name': 'Krungthai NEXT',
      'scheme': 'krungthainext://',
      'storeUrl': 'https://krungthai.com/th/content/personal/krungthai-next',
      'color': Color(0xFF1BA5E1),
    },
    {
      'name': 'Bangkok Bank Mobile Banking',
      'scheme': 'bblmobilebanking://',
      'storeUrl':
          'https://www.bangkokbank.com/th-th/personal/digital-banking/bualuang-mbanking',
      'color': Color(0xFF1E4598),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        // ใช้ IndexedStack เพื่อให้สลับหน้าไปมาได้โดยที่แถบเมนูด้านล่างไม่หายไป
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // =====================================
            // 🔘 แท็บที่ 0: หน้าหลัก (Dashboard)
            // =====================================
            _buildDashboardContent(),

            // =====================================
            // 🔘 แท็บที่ 1: คำสั่งซื้อ / จัดการออเดอร์
            // =====================================
            _buildOrdersTab(),

            // =====================================
            // 🔘 แท็บที่ 2: รายได้และสถิติ
            // =====================================
            _buildRevenueTab(),

            // =====================================
            // 🔘 แท็บที่ 3: หน้าโปรไฟล์ผู้ค้า
            // =====================================
            MerchantProfileScreen(merchantData: widget.merchantData),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // หน้า Dashboard หลักที่สามารถเลื่อน (Scroll) ได้ทั้งหมด
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: 40.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSalesSummaryCard(),
          const SizedBox(height: 32),
          const Text(
            'เมนูจัดการร้านด่วน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickMenu(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ออเดอร์ที่กำลังดำเนินการ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1; // สลับไปหน้าคำสั่งซื้อ
                  });
                },
                child: Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOrderList(),
        ],
      ),
    );
  }

  // แท็บที่ 1: หน้าจัดการคำสั่งซื้อ (Orders Tab)
  Widget _buildOrdersTab() {
    // 🟢 เพิ่มสถานะ "ยกเลิก" เข้ามาในแถบกรอง เพื่อให้ดูคำสั่งซื้อที่ปฏิเสธได้
    final statusFilters = [
      'ทั้งหมด',
      'ใหม่',
      'กำลังปรุง',
      'รอรับสินค้า',
      'เสร็จสิ้น',
      'ยกเลิก',
    ];

    final filteredOrders = _selectedOrderStatus == 'ทั้งหมด'
        ? _allOrders
        : _allOrders
              .where((order) => order['status'] == _selectedOrderStatus)
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'จัดการคำสั่งซื้อ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'ทั้งหมด ${filteredOrders.length} รายการ',
                  style: const TextStyle(
                    color: Color(0xFF00C7E6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // แถบเลือกสถานะออเดอร์ (Filter Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusFilters.map((filter) {
                final isSelected = _selectedOrderStatus == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrderStatus = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C7E6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1E293B),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // รายการการ์ดคำสั่งซื้อ
          if (filteredOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              alignment: Alignment.center,
              child: const Text(
                'ไม่มีคำสั่งซื้อในหมวดหมู่นี้',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else
            ...filteredOrders.map((order) {
              return _buildManageOrderCard(order);
            }),
        ],
      ),
    );
  }

  // 🟢 Widget แสดงการ์ดคำสั่งซื้อแบบละเอียด ปรับปุ่มให้ไปหน้าจัดการใหม่ตามดีไซน์รูปภาพ
  Widget _buildManageOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  // 🟢 เปลี่ยนไอคอนเป็นวงกลมขอบสีเทา ไอคอนสีดำ (ขาวดำ) ตามภาพตัวอย่างที่ส่งมา
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(
                      Icons.receipt_outlined,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['orderId'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            order['customer'],
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                          // 🟢 แต้มสะสมของลูกค้า — ให้ร้านค้าเห็นได้ทันทีจากหน้าจัดการคำสั่งซื้อ ไม่ต้องกดดูรายละเอียดก่อน
                          if (order['customerPoints'] != null) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.loyalty,
                              size: 12,
                              color: Color(0xFF00C7E6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${order['customerPoints']} แต้ม',
                              style: const TextStyle(
                                color: Color(0xFF00C7E6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: order['statusColor'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Text(
            order['details'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เวลา: ${order['time']}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                order['price'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF00C7E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 🟢 รวมปุ่ม "ดูรายละเอียด" กับปุ่มจัดการ/ปฏิเสธ/อัปเดตสถานะให้เหลือปุ่มเดียว
          // เพราะหน้าจัดการของแต่ละสถานะ (รับ-ปฏิเสธ / อัปเดตสถานะ) มีรายละเอียดออเดอร์ครบอยู่แล้วในตัว
          // ไม่ต้องมีปุ่ม "ดูรายละเอียด" แยกต่างหาก และย้ายการปฏิเสธไปรวมไว้ในหน้าจัดการเดียวกันแทน
          SizedBox(
            width: double.infinity,
            child:
                (order['status'] == 'เสร็จสิ้น' || order['status'] == 'ยกเลิก')
                ? OutlinedButton(
                    onPressed: () {
                      // 🟢 ออเดอร์ที่ถูกปฏิเสธ/ยกเลิก → กลับไปดูหน้ารายละเอียดการปฏิเสธได้ทุกเมื่อ (ไม่ใช่ดูได้แค่ครั้งเดียวตอนกดปฏิเสธ)
                      if (order['status'] == 'ยกเลิก') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MerchantRejectedOrder(
                              orderData: order,
                              rejectReason:
                                  order['rejectReason'] ?? 'ไม่ได้ระบุเหตุผล',
                              rejectedAt: order['rejectedAt'] ?? DateTime.now(),
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MerchantOrderStatus(
                              orderData: order,
                              onOrderUpdated: _refreshMerchantData,
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      // ออเดอร์ใหม่ → ไปหน้า "รับหรือปฏิเสธคำสั่งซื้อ" (มีรายละเอียดครบ + ปุ่มรับ/ปฏิเสธในหน้าเดียว)
                      if (order['status'] == 'ใหม่') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MerchantAcceptOrder(
                              orderData: order,
                              onOrderUpdated: _refreshMerchantData,
                            ),
                          ),
                        );
                      } else {
                        // ออเดอร์ที่รับแล้ว → ไปหน้า "อัปเดตคำสั่งซื้อ" (มีรายละเอียดครบ + อัปเดตสถานะ + ยกเลิกออเดอร์ในหน้าเดียว)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MerchantOrderStatus(
                              orderData: order,
                              onOrderUpdated: _refreshMerchantData,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7E6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // แท็บที่ 2: หน้าสรุปรายได้และสถิติ
  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปรายได้ของฉัน',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'ยอดขายวันนี้',
                  '฿ ${_todaySales.toStringAsFixed(2)}',
                  Icons.today,
                  Colors.orange,
                  onTap: () => _showTodaySalesDetail(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'สัปดาห์นี้',
                  '฿ ${_weekSales.toStringAsFixed(2)}',
                  Icons.date_range,
                  Colors.green,
                  onTap: () => _showWeekSalesDetail(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สถิติการขาย (7 วันล่าสุด)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              InkWell(
                onTap: () => _showWeekSalesDetail(context),
                child: Text(
                  'ดูสถิติ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            height: 220,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklySalesData.map((day) {
                return _buildChartBar(
                  day['label'] as String,
                  day['height'] as double,
                  amount: day['amount'] as int,
                  isToday: day['isToday'] as bool,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade300,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(
    String label,
    double height, {
    required int amount,
    bool isToday = false,
  }) {
    return GestureDetector(
      onTap: () => _showDaySalesDetail(context, label, amount, isToday),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 28,
            height: height,
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF00C7E6)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: isToday ? const Color(0xFF00C7E6) : Colors.grey,
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 ฟังก์ชันแสดง BottomSheet ให้เลือกแอปธนาคารที่จะใช้ถอนเงิน
  void _showWithdrawOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกแอปธนาคารเพื่อถอนเงิน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1A30),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ยอดเงินที่สามารถถอนได้ ฿ ${_availableBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ..._bankApps.map((bank) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                      ); // ปิด BottomSheet ก่อนเปิดแอปธนาคาร
                      _launchBankApp(
                        context,
                        bank['name'] as String,
                        bank['scheme'] as String,
                        bank['storeUrl'] as String,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (bank['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance,
                              color: bank['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              bank['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 🟢 ฟังก์ชันเปิดแอปธนาคารภายนอกตาม URL scheme ที่เลือก หากเปิดไม่สำเร็จจะพาไปหน้าเว็บดาวน์โหลดแอปแทน
  Future<void> _launchBankApp(
    BuildContext context,
    String bankName,
    String scheme,
    String storeUrl,
  ) async {
    final Uri appUri = Uri.parse(scheme);
    try {
      final bool launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        await _launchFallbackUrl(context, bankName, storeUrl);
      }
    } catch (e) {
      if (context.mounted) {
        await _launchFallbackUrl(context, bankName, storeUrl);
      }
    }
  }

  // 🟢 เปิดหน้าเว็บของธนาคารเป็นทางเลือกสำรอง กรณีเปิดแอปธนาคารโดยตรงไม่สำเร็จ (เช่น ยังไม่ได้ติดตั้งแอป)
  Future<void> _launchFallbackUrl(
    BuildContext context,
    String bankName,
    String storeUrl,
  ) async {
    try {
      final Uri webUri = Uri.parse(storeUrl);
      final bool launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่พบแอป $bankName ในเครื่อง กรุณาติดตั้งแอปก่อนทำรายการถอนเงิน',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเปิดแอป $bankName: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🟢 BottomSheet แสดงรายละเอียดยอดขายวันนี้
  void _showTodaySalesDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ยอดขายวันนี้ (ศุกร์)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1A30),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดขายรวมวันนี้',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '฿ ${_todaySales.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'จากทั้งหมด $_todayOrderCount ออเดอร์',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _selectedIndex =
                          1; // สลับไปหน้าคำสั่งซื้อเพื่อดูรายละเอียดออเดอร์
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'ดูรายการออเดอร์วันนี้',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🟢 BottomSheet แสดงรายละเอียดยอดขายสัปดาห์นี้ แยกตามวัน
  void _showWeekSalesDetail(BuildContext context) {
    final int weekTotal = _weeklySalesData.fold<int>(
      0,
      (sum, day) => sum + (day['amount'] as int),
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สรุปยอดขายสัปดาห์นี้',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1A30),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'รวมทั้งสัปดาห์ ฿ ${weekTotal.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._weeklySalesData.map((day) {
                final bool isToday = day['isToday'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF00C7E6).withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          day['label'] as String,
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isToday
                                ? const Color(0xFF00C7E6)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (day['amount'] as int) / 3200,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isToday
                                  ? const Color(0xFF00C7E6)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '฿${day['amount']}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 🟢 แสดงยอดขายของวันที่กดเลือกจากกราฟแท่ง (SnackBar แบบสั้น)
  void _showDaySalesDetail(
    BuildContext context,
    String label,
    int amount,
    bool isToday,
  ) {
    final String dayText = isToday ? '$label (วันนี้)' : label;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ยอดขายวัน$dayText: ฿$amount'),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ฟังก์ชันแสดงการแจ้งเตือน — เปิดเป็นหน้าใหม่
  void _showNotificationBottomSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationPage(
          merchantId: widget.merchantData?['id'],
          onGoToOrders: () {
            Navigator.pop(context);
            setState(() {
              _selectedIndex = 1;
            });
          },
        ),
      ),
    );
  }

  // ส่วนหัวของหน้า (Header)
  Widget _buildHeader() {
    final rawShopName = widget.merchantData?['name']?.toString() ?? 'ร้านค้า';
    final shopName = rawShopName.startsWith('ร้าน')
        ? rawShopName
        : 'ร้าน$rawShopName';
    return Row(
      children: [
        // 🟢 เพิ่ม GestureDetector เพื่อให้กดรููปโปรไฟล์แล้วไปหน้าโปรไฟล์ได้
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 3; // สลับไปแท็บที่ 3 (หน้าโปรไฟล์)
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF3F4F6,
              ), // 🟢 เปลี่ยนเป็นไอคอนร้านค้าพื้นเทาอ่อนแทนวงกลมสีส้ม
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront,
              color: Color(0xFF9CA3AF),
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ยินดีต้อนรับ',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Row(
              children: [
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                // โชว์ป้ายสถานะปัจจุบันข้างๆ ชื่อร้าน
                GestureDetector(
                  onTap:
                      _showStoreStatusBottomSheet, // 🟢 เพิ่มคำสั่งเมื่อกดให้เปิดเมนูสถานะร้าน
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _storeStatus == 'เปิดร้าน'
                          ? const Color(0xFF10B981) // เขียว
                          : _storeStatus == 'กำลังย้าย'
                          ? const Color(0xFFF59E0B) // ส้ม
                          : const Color(0xFFEF4444), // แดง
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _storeStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        Stack(
          clipBehavior: Clip.none,
          children: [
            // ไอคอนกระดิ่งเรียกใช้ฟังก์ชันการแจ้งเตือน
            _buildIconWithShadow(
              Icons.notifications_none,
              onTap: _showNotificationBottomSheet,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconWithShadow(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildSalesSummaryCard() {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = 2; // สลับไปหน้ารายได้
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF28A5B9), Color(0xFF1B4D5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D5C).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สรุปยอดขายวันนี้',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${_todaySales.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'วันนี้',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$_todayOrderCount ออเดอร์วันนี้',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.trending_up, color: Colors.white54, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  // แสดง BottomSheet สำหรับเปลี่ยนสถานะร้านค้า
  void _showStoreStatusBottomSheet() {
    final List<Map<String, dynamic>> statusOptions = [
      {
        'title': 'เปิดร้าน',
        'description': 'ส่งแจ้งเตือนอัตโนมัติไปให้ลูกค้าที่ติดตาม',
        'icon': Icons.storefront_outlined,
        'activeColor': const Color(0xFF10B981),
        'bgColor': const Color(0xFFE6F4EA),
        'sendNotification': true,
      },
      {
        'title': 'กำลังย้าย',
        'description': 'ส่งแจ้งเตือนอัตโนมัติไปให้ลูกค้าที่ติดตาม',
        'icon': Icons.moped_outlined,
        'activeColor': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFEF3C7),
        'sendNotification': true,
      },
      {
        'title': 'ปิดร้าน',
        'description': 'ไม่ส่งแจ้งเตือน',
        'icon': Icons.do_not_disturb_on_outlined,
        'activeColor': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEE2E2),
        'sendNotification': false,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สถานะร้านค้า',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1A30),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'เลือกสถานะเพื่อแจ้งให้ลูกค้าทราบ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  ...statusOptions.map((option) {
                    final isSelected = _storeStatus == option['title'];
                    final activeColor = option['activeColor'];

                    return GestureDetector(
                      onTap: () async {
                        final status = option['title'].toString();
                        final updated = await _updateStoreStatus(status);
                        if (!updated || !context.mounted) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('อัปเดตสถานะร้านไม่สำเร็จ'),
                              ),
                            );
                          }
                          return;
                        }
                        setModalState(() {});
                        Navigator.pop(context);

                        if (option['sendNotification']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'อัปเดตสถานะเป็น "${option['title']}" และส่งแจ้งเตือนไปยังลูกค้าที่ติดตามแล้ว 🔔',
                              ),
                              backgroundColor: activeColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'อัปเดตสถานะเป็น "${option['title']}" แล้ว (ไม่ส่งแจ้งเตือน)',
                              ),
                              backgroundColor: const Color(0xFF64748B),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? activeColor
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: activeColor.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withOpacity(0.12)
                                    : option['bgColor'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                option['icon'],
                                color: activeColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? activeColor
                                          : const Color(0xFF0B1A30),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option['description'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: activeColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ปรับแถบ Quick Menu ให้เลื่อนซ้าย-ขวาได้
  Widget _buildQuickMenu() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuAction(
            Icons.receipt_long,
            'จัดการ\nออเดอร์',
            () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(width: 24),
          _buildMenuAction(Icons.restaurant_menu, 'แก้ไข\nเมนู', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MerchantMenu(merchantId: widget.merchantData?['id']),
              ),
            );
          }),
          const SizedBox(width: 24),
          _buildMenuAction(
            Icons.storefront,
            'สถานะ\nร้านค้า',
            _showStoreStatusBottomSheet,
          ),
          const SizedBox(width: 24),
          _buildMenuAction(Icons.location_on_outlined, 'แผนที่\nจุดขาย', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MerchantMap()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // รายการออเดอร์ในหน้า Dashboard
  Widget _buildOrderList() {
    final activeOrders = _allOrders
        .where(
          (order) =>
              order['status'] == 'ใหม่' ||
              order['status'] == 'กำลังปรุง' ||
              order['status'] == 'รอรับสินค้า',
        )
        .toList();

    if (activeOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'ยังไม่มีออเดอร์ที่กำลังดำเนินการ',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: activeOrders.map((order) {
        return _buildOrderCard(
          icon: order['icon'] as IconData,
          orderId: order['orderId'].toString(),
          details: order['details'].toString(),
          statusText: order['status'].toString(),
          statusColor: order['statusColor'] as Color,
          price: order['price'].toString(),
          time: order['time'].toString(),
          onTap: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
        );
      }).toList(),
    );
  }

  // 🟢 ปรับปรุงใหม่เพื่อให้แสดง BottomSheet โชว์รายละเอียดแบบชัดเจน (เพิ่ม UI และปุ่มเข้าไป)
  void _showOrderDetails(String orderId) {
    // 1. ค้นหาออเดอร์ตามไอดี
    final order = _allOrders.firstWhere(
      (o) => o['orderId'] == orderId,
      orElse: () => {},
    );

    if (order.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบรายละเอียดของออเดอร์ $orderId'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. แสดง UI รายละเอียดพร้อมตัวเลือกกระโดดไปยังหน้าจัดการ
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รายละเอียด ${order['orderId']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1A30),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ลูกค้า: ${order['customer']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  // 🟢 แต้มสะสมของลูกค้า — ให้ร้านค้าดูแต้มสะสมของลูกค้าได้ตั้งแต่หน้าคำสั่งซื้อ (นำไปแลกส่วนลดได้)
                  if (order['customerPoints'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.loyalty,
                          size: 15,
                          color: Color(0xFF00C7E6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${order['customerPoints']} แต้ม',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00879E),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.list_alt, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'รายการ:\n${order['details']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'เวลาสั่งซื้อ: ${order['time']}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              // 🟢 เวลาชำระเงิน — เพิ่มให้ร้านค้าดูได้ว่าลูกค้าชำระเงินตอนไหน
              if (order['paymentTime'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'เวลาชำระเงิน: ${order['paymentTime']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ยอดรวมทั้งหมด:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${order['price']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C7E6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // ปิดหน้าต่าง Popup
                    setState(() {
                      _selectedIndex = 1; // สลับไปหน้าแท็บ 'คำสั่งซื้อ' ทันที
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'จัดการออเดอร์นี้',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard({
    required IconData icon,
    required String orderId,
    required String details,
    required String statusText,
    required Color statusColor,
    required String price,
    required String time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.receipt_outlined,
                color: Color(0xFF1E293B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        orderId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF00C7E6),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // แถบเมนูด้านล่าง
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0 || index == 1 || index == 2) {
            _refreshMerchantData();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E293B),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'คำสั่งซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'รายได้',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.config.dart';
import 'order_detail_screen.dart';
import 'refund_details_screen.dart';
import 'buyer_home_screen.dart';

class WaitingOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> allFoodTrucks;

  const WaitingOrderScreen({
    Key? key,
    required this.order,
    required this.allFoodTrucks,
  }) : super(key: key);

  @override
  State<WaitingOrderScreen> createState() => _WaitingOrderScreenState();
}

class _WaitingOrderScreenState extends State<WaitingOrderScreen> with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  int _remainingSeconds = 180;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final rawOrderId = widget.order['order_id'] ?? widget.order['id'];
      if (rawOrderId == null) return;
      final orderId = rawOrderId.toString().replaceAll('ORD-', '');

      try {
        final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId'));
        print('🚀 [เช็คสถานะออเดอร์]: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          if (resData['success'] == true) {
            final orderData = resData['data'];
            final String status = orderData['status']?.toString().trim() ?? '';

            final updatedOrder = Map<String, dynamic>.from(widget.order);
            updatedOrder['status'] = status;

            // 🔴 1. ถ้าร้านปฏิเสธ หรือยกเลิก -> เด้ง Popup ตามภาพ
            if (status == 'ปฏิเสธ' || status == 'ยกเลิก' || status == 'ร้านปฏิเสธคำสั่งซื้อ') {
              _cancelTimers();
              if (!mounted) return;
              _showCancelledPopup(updatedOrder);
              return;
            }

            // 🟢 2. ถ้าร้านกดรับออเดอร์
            if (status != 'รอร้านค้าตอบรับ' && status != 'รอชำระเงิน' && status != 'รอรับออเดอร์' && status != '') {
              _cancelTimers();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: updatedOrder, allFoodTrucks: widget.allFoodTrucks),
                ),
              );
            }
          }
        }
      } catch (e) {
        print('Error polling order status: $e');
      }
    });
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
  }

  void _handleTimeout() {
    _cancelTimers();
    final updatedOrder = Map<String, dynamic>.from(widget.order);
    updatedOrder['status'] = 'หมดเวลาตอบรับ';
    _showCancelledPopup(updatedOrder);
  }

  // 🔴 Popup เต็มหน้าจอ ตามภาพ 'pop up คำสั่งซื้อถูกปฎิเสธ'
  void _showCancelledPopup(Map<String, dynamic> updatedOrder) {
    // คำนวณราคาจากออเดอร์
    final dynamic rawPrice = updatedOrder['totalPrice'] ?? updatedOrder['total_price'] ?? '0';
    final String priceStr = rawPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    final double refundAmount = double.tryParse(priceStr) ?? 0.0;

    final String orderIdStr = (updatedOrder['order_id'] ?? updatedOrder['id'] ?? '0').toString().replaceAll('ORD-', '');
    final String storeName = updatedOrder['storeTitle'] ?? updatedOrder['merchant_name'] ?? 'ร้านค้า';

    // เวลาปัจจุบัน
    final now = DateTime.now();
    final months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final String dateStr = '${now.day} ${months[now.month - 1]} ${now.year + 543} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _CancelledFullScreen(
          refundAmount: refundAmount,
          orderIdStr: orderIdStr,
          storeName: storeName,
          dateStr: dateStr,
        ),
      ),
    );
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('สถานะคำสั่งซื้อ', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _glowAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00C7E6).withOpacity(0.15),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB1F0F9)),
                            child: const Icon(Icons.storefront_outlined, color: Color(0xFF0B1A30), size: 30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text('รอร้านรับคำสั่งซื้อของคุณ...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                    const SizedBox(height: 8),
                    const Text('คุณจะทราบผลภายใน', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formattedTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                          const SizedBox(width: 8),
                          const Text('นาที', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified_user_outlined, color: Color(0xFF00C7E6), size: 18),
                SizedBox(width: 8),
                Text('เราจะแจ้งให้คุณทราบทันทีเมื่อร้านตอบรับ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// หน้าจอ Popup เต็มจอ "คำสั่งซื้อถูกยกเลิก" (ตามภาพ 100%)
// ============================================================
class _CancelledFullScreen extends StatelessWidget {
  final double refundAmount;
  final String orderIdStr;
  final String storeName;
  final String dateStr;

  const _CancelledFullScreen({
    required this.refundAmount,
    required this.orderIdStr,
    required this.storeName,
    required this.dateStr,
  });

  // ฟังก์ชันกลับไปหน้า Home แท็บคำสั่งซื้อ + เลือกหมวด "คืนเงิน"
  void _goBackToHome(BuildContext ctx) {
    if (buyerHomeKey.currentContext != null) {
      final homeRoute = ModalRoute.of(buyerHomeKey.currentContext!);
      if (homeRoute != null) {
        Navigator.of(ctx).popUntil((route) => route == homeRoute);
      } else {
        Navigator.of(ctx).popUntil((route) => route.isFirst);
      }
    } else {
      Navigator.of(ctx).popUntil((route) => route.isFirst);
    }
    buyerHomeKey.currentState?.switchTab(1);
    buyerHomeKey.currentState?.setOrderFilter('คืนเงิน');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => _goBackToHome(context),
        ),
        title: const Text('รายละเอียดคำสั่งซื้อ', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ไอคอน X สีแดงวงกลม (ตามภาพเป๊ะ)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEF4444),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'คำสั่งซื้อถูกยกเลิก',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'เหตุผล: สินค้าหมด (ร้านค้าขอยกเลิก)',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),

          // ปุ่ม "ตรวจสอบการคืนเงิน" สีฟ้า (ตามภาพเป๊ะ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7E6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (refundCtx) => RefundDetailsScreen(
                        refundData: {
                          'order_id': 'ORD-$orderIdStr',
                          'charge_id': 'CHG-$orderIdStr',
                          'refund_amount': refundAmount,
                          'refund_status': 'Pending',
                          'store_name': storeName,
                          'cancellation_reason': 'สินค้าหมด',
                          'request_date': dateStr,
                        },
                        onBackPressed: () {
                          // กลับไปที่หน้า Home
                          if (buyerHomeKey.currentContext != null) {
                            final homeRoute = ModalRoute.of(buyerHomeKey.currentContext!);
                            if (homeRoute != null) {
                              Navigator.of(refundCtx).popUntil((route) => route == homeRoute);
                            } else {
                              Navigator.of(refundCtx).popUntil((route) => route.isFirst);
                            }
                          } else {
                            Navigator.of(refundCtx).popUntil((route) => route.isFirst);
                          }
                          buyerHomeKey.currentState?.switchTab(1);
                          buyerHomeKey.currentState?.setOrderFilter('คืนเงิน');
                        },
                      ),
                    ),
                  );
                },
                child: const Text('ตรวจสอบการคืนเงิน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
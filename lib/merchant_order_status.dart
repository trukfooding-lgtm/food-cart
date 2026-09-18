import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

// =======================================================================
// 🟢 หน้า 2: อัปเดตคำสั่งซื้อ (ตามดีไซน์รูปขวา)
// =======================================================================
class MerchantOrderStatus extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onOrderUpdated;

  const MerchantOrderStatus({
    super.key,
    required this.orderData,
    required this.onOrderUpdated,
  });

  @override
  State<MerchantOrderStatus> createState() => _MerchantOrderStatusState();
}

class _MerchantOrderStatusState extends State<MerchantOrderStatus> {
  // 0: รับคำสั่งซื้อ, 1: กำลังทำ, 2: พร้อมรับ, 3: รับอาหารสำเร็จ
  int _currentStep = 1;
  bool _isCancelled =
      false; // 🟢 แยกสถานะ "ยกเลิก" ออกมาต่างหาก เพื่อไม่ให้ timeline แสดงผลผิด

  bool get _isPaid =>
      widget.orderData['isPaid'] == true ||
      widget.orderData['is_paid'] == true ||
      const {
        'ชำระเงินแล้ว',
        'พร้อมรับ',
        'รับอาหารสำเร็จแล้ว',
      }.contains(widget.orderData['status']);

  double? _asNumber(dynamic value) {
    if (value is num) return value.toDouble();
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return double.tryParse(text.replaceAll(RegExp(r'[^0-9.-]'), ''));
  }

  String _numberText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  bool get _hasLoyaltyInfo {
    if (!_isPaid) return false;
    final balance = _asNumber(widget.orderData['customerPoints']);
    final used = _asNumber(widget.orderData['pointsUsed']);
    final discount = _asNumber(widget.orderData['pointsDiscount']);
    return balance != null ||
        (used != null && used > 0) ||
        (discount != null && discount > 0);
  }

  Future<bool> _saveReadyStatus() async {
    final merchantId = widget.orderData['merchantId'];
    final orderId = widget.orderData['databaseId'];
    if (merchantId == null || orderId == null) return false;
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantOrderStatus(merchantId, orderId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'รอรับสินค้า'}),
      );
      final body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    // แสดงขั้นตอนตามสถานะออเดอร์ปัจจุบัน
    switch (widget.orderData['status']) {
      case 'กำลังปรุง':
        _currentStep = 1;
        break;
      case 'รอรับสินค้า':
        _currentStep = 2;
        break;
      case 'เสร็จสิ้น':
        _currentStep = 3;
        break;
      case 'ยกเลิก':
        // 🟢 ออเดอร์ที่ถูกยกเลิก ให้หยุดไว้ที่ขั้นตอน "รับคำสั่งซื้อ" และไม่แสดงว่ากำลังดำเนินการต่อ
        _currentStep = 0;
        _isCancelled = true;
        break;
      default:
        _currentStep = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canUpdateToReady = widget.orderData['status'] == 'กำลังปรุง';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
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
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'อัปเดตคำสั่งซื้อ',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // การ์ดข้อมูลออเดอร์ลูกค้า
                  Container(
                    padding: const EdgeInsets.all(20),
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
                            Text(
                              'Order ${widget.orderData['orderId']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.orderData['time'],
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.orderData['customer'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            // 🟢 แต้มสะสมของลูกค้า แสดงไว้ข้างชื่อเหมือนหน้าจัดการคำสั่งซื้อ
                            if (_isPaid &&
                                widget.orderData['customerPoints'] != null) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.loyalty,
                                size: 12,
                                color: Color(0xFF00C7E6),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.orderData['customerPoints']} แต้ม',
                                style: const TextStyle(
                                  color: Color(0xFF00C7E6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_hasLoyaltyInfo) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF99F6E4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.loyalty,
                                      size: 18,
                                      color: Color(0xFF0F766E),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'แต้มสะสมของลูกค้า',
                                      style: TextStyle(
                                        color: Color(0xFF0F766E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_asNumber(
                                      widget.orderData['customerPoints'],
                                    ) !=
                                    null)
                                  Text(
                                    'แต้มคงเหลือ: ${_numberText(_asNumber(widget.orderData['customerPoints'])!)} แต้ม',
                                    style: const TextStyle(
                                      color: Color(0xFF134E4A),
                                    ),
                                  ),
                                if ((_asNumber(
                                          widget.orderData['pointsUsed'],
                                        ) ??
                                        0) >
                                    0)
                                  Text(
                                    'ใช้แต้มแลก: ${_numberText(_asNumber(widget.orderData['pointsUsed'])!)} แต้ม',
                                    style: const TextStyle(
                                      color: Color(0xFF134E4A),
                                    ),
                                  ),
                                if ((_asNumber(
                                          widget.orderData['pointsDiscount'],
                                        ) ??
                                        0) >
                                    0)
                                  Text(
                                    'ส่วนลดจากแต้ม: ฿${_numberText(_asNumber(widget.orderData['pointsDiscount'])!)}',
                                    style: const TextStyle(
                                      color: Color(0xFF134E4A),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            // 🟢 เปลี่ยนจากไอคอนโปรไฟล์ (คน) เป็นไอคอนอาหารแทน
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(
                                Icons.receipt_outlined,
                                color: Color(0xFF1E293B),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 🟢 แสดงรายการอาหารจริงของออเดอร์นี้ แทนข้อความ "โรตีกล้วย" ที่ตายตัว
                            Expanded(
                              child: Text(
                                widget.orderData['details'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 🟢 ราคาเปลี่ยนเป็นป้าย "ยอดชำระ" พร้อมจำนวนเงินจริงของออเดอร์
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'ยอดชำระ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  widget.orderData['price'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF00C7E6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เวลาสั่งซื้อ: ${widget.orderData['time'] ?? '-'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        // 🟢 เวลาชำระเงิน — ให้ร้านค้าดูได้ในหน้านี้เลย ไม่ต้องเปิดหน้าแยก
                        if (widget.orderData['paymentTime'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'เวลาชำระเงิน: ${widget.orderData['paymentTime']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Timeline 4 ขั้นตอนตามแบบที่ต้องการ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTimelineItem(
                          Icons.receipt_long_outlined,
                          'รับคำสั่งซื้อ',
                          _currentStep >= 0,
                        ),
                      ),
                      _buildTimelineDivider(_currentStep >= 1),
                      Expanded(
                        child: _buildTimelineItem(
                          Icons.restaurant_outlined,
                          'กำลังทำ',
                          _currentStep >= 1,
                        ),
                      ),
                      _buildTimelineDivider(_currentStep >= 2),
                      Expanded(
                        child: _buildTimelineItem(
                          Icons.shopping_bag_outlined,
                          'พร้อมรับ',
                          _currentStep >= 2,
                        ),
                      ),
                      _buildTimelineDivider(_currentStep >= 3),
                      Expanded(
                        child: _buildTimelineItem(
                          Icons.check_circle_outline,
                          'รับอาหารสำเร็จ',
                          _currentStep >= 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // ปุ่มด้านล่าง: อัปเดตได้เฉพาะเป็น "พร้อมรับ" + ยกเลิกออเดอร์ได้จากหน้านี้โดยตรง
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canUpdateToReady
                    ? () async {
                        final saved = await _saveReadyStatus();
                        if (!saved) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ไม่สามารถอัปเดตออเดอร์ได้'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        if (!mounted) return;
                        widget.orderData['status'] = 'รอรับสินค้า';
                        widget.orderData['statusColor'] = const Color(
                          0xFFF59E0B,
                        );
                        widget.orderData['icon'] = Icons.shopping_bag_outlined;
                        widget.onOrderUpdated();
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'อัปเดตสถานะออเดอร์เป็น "พร้อมรับ" เรียบร้อยแล้ว',
                            ),
                            backgroundColor: Color(0xFF00C7E6),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7E6),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'อัปเดตเป็นพร้อมรับ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00C7E6) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF00C7E6) : Colors.grey.shade300,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.2,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF00C7E6) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 20),
        color: isActive ? const Color(0xFF00C7E6) : Colors.grey.shade300,
      ),
    );
  }
}

// =============================================
// หน้าการแจ้งเตือน (แยกเป็นหน้าใหม่)
// =============================================

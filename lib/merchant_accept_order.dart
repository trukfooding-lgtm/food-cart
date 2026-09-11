import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';
import 'merchant_rejected_order.dart';

// =======================================================================
// 🟢 หน้า 1: รับหรือปฏิเสธคำสั่งซื้อ (ตามดีไซน์รูปซ้าย)
// =======================================================================
class MerchantAcceptOrder extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onOrderUpdated;

  const MerchantAcceptOrder({
    super.key,
    required this.orderData,
    required this.onOrderUpdated,
  });

  @override
  State<MerchantAcceptOrder> createState() => _MerchantAcceptOrderState();
}

class _MerchantAcceptOrderState extends State<MerchantAcceptOrder> {
  int _selectedPrepTime = 15; // ค่าเริ่มต้น 15 นาที

  Future<bool> _saveStatus(
    String status, {
    int? prepMinutes,
    String? rejectReason,
  }) async {
    final merchantId = widget.orderData['merchantId'];
    final orderId = widget.orderData['databaseId'];
    if (merchantId == null || orderId == null) return false;
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantOrderStatus(merchantId, orderId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          if (prepMinutes != null) 'prep_minutes': prepMinutes,
          if (rejectReason != null) 'reject_reason': rejectReason,
        }),
      );
      final body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  void _showSaveError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ไม่สามารถอัปเดตออเดอร์ได้'),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'รับหรือปฏิเสธคำสั่งซื้อ',
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
                  // การ์ดส่วนหัวออเดอร์
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
                              'ออเดอร์ ${widget.orderData['orderId']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'รอการยืนยัน',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'มีคำสั่งซื้อใหม่',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ลูกค้า',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      widget.orderData['customer'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    // 🟢 แต้มสะสมของลูกค้า แสดงไว้ในหน้ารับ/ปฏิเสธออเดอร์ด้วย
                                    if (widget.orderData['customerPoints'] !=
                                        null) ...[
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
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        // 🟢 เวลาสั่งซื้อ / เวลาชำระเงิน — ให้ดูได้ในหน้านี้เลย ไม่ต้องเปิดหน้าแยก
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
                  const SizedBox(height: 24),

                  const Text(
                    'รายการอาหาร',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // การ์ดรายการอาหาร — 🟢 ใช้รายการจริงของออเดอร์นี้ แทนข้อมูล "โรตีกล้วย" ที่ตายตัว
                  Container(
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.orderData['details'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // การ์ดสรุปยอด — 🟢 ใช้ยอดรวมจริงของออเดอร์นี้ แทนตัวเลข 35 ที่ตายตัว
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ยอดชำระทั้งหมด',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          widget.orderData['price'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF00C7E6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'เวลาเตรียมอาหารโดยประมาณ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [10, 15, 20].map((time) {
                      bool isSelected = _selectedPrepTime == time;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPrepTime = time),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: time != 20 ? 12 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00C7E6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00C7E6)
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$time นาที',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // ปุ่มล่าง (Bottom Buttons)
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // สร้างตัวแปรเก็บข้อความเหตุผล
                      TextEditingController reasonController =
                          TextEditingController();

                      // แสดง Popup ให้ระบุเหตุผล
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'เหตุผลที่ปฏิเสธ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'กรุณาระบุเหตุผลที่ยกเลิกคำสั่งซื้อนี้:',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: reasonController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'เช่น วัตถุดิบหมด, คิวเยอะทำไม่ทัน...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF00C7E6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  context,
                                ), // ปิด Popup ถ้ายกเลิก
                                child: const Text(
                                  'ยกเลิก',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  // เช็คว่าไม่ได้พิมพ์อะไรมาเลย
                                  if (reasonController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('กรุณาระบุเหตุผล'),
                                        backgroundColor: Color(0xFFEF4444),
                                      ),
                                    );
                                    return; // หยุดทำงาน ไม่ให้ไปต่อถ้าไม่พิมพ์เหตุผล
                                  }

                                  final String reasonText = reasonController
                                      .text
                                      .trim();
                                  final DateTime rejectedAt = DateTime.now();
                                  final saved = await _saveStatus(
                                    'ยกเลิก',
                                    rejectReason: reasonText,
                                  );
                                  if (!saved) {
                                    _showSaveError();
                                    return;
                                  }
                                  if (!mounted) return;
                                  Navigator.pop(context); // ปิด Popup

                                  // อัปเดตสถานะเป็นยกเลิก
                                  widget.orderData['status'] = 'ยกเลิก';
                                  widget.orderData['statusColor'] = const Color(
                                    0xFFEF4444,
                                  );
                                  widget.orderData['icon'] =
                                      Icons.receipt_outlined;
                                  widget.orderData['rejectReason'] =
                                      reasonText; // 🟢 บันทึกเหตุผลเอาไว้ในข้อมูลออเดอร์
                                  widget.orderData['rejectedAt'] =
                                      rejectedAt; // 🟢 บันทึกเวลาปฏิเสธไว้ด้วย เพื่อให้กลับมาดูรายละเอียดซ้ำได้ทีหลัง

                                  widget.onOrderUpdated();

                                  // 🟢 แทนที่หน้านี้ด้วยหน้า "รายละเอียดการปฏิเสธคำสั่งซื้อ" แบบเดียวกับตัวอย่างฝั่งลูกค้า
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MerchantRejectedOrder(
                                            orderData: widget.orderData,
                                            rejectReason: reasonText,
                                            rejectedAt: rejectedAt,
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'ยืนยัน',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          Colors.white, // 🟢 ปุ่มปฏิเสธออเดอร์ = พื้นหลังสีขาว
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ), // 🟢 กรอบสีเทาอ่อน
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'ปฏิเสธออเดอร์',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ), // 🟢 ตัวหนังสือสีดำ
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final saved = await _saveStatus(
                        'กำลังปรุง',
                        prepMinutes: _selectedPrepTime,
                      );
                      if (!saved) {
                        _showSaveError();
                        return;
                      }
                      if (!mounted) return;
                      widget.orderData['status'] = 'กำลังปรุง';
                      widget.orderData['statusColor'] = const Color(0xFFF59E0B);
                      widget.orderData['icon'] = Icons.access_time;
                      widget.onOrderUpdated();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'รับออเดอร์แล้ว! กำหนดเวลาเตรียม $_selectedPrepTime นาที',
                          ),
                          backgroundColor: const Color(0xFF00C7E6),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7E6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'รับออเดอร์',
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
          ),
        ],
      ),
    );
  }
}

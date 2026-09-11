import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CancelledOrderDetailsScreen extends StatelessWidget { 
  final Map<String, dynamic> order;

  const CancelledOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // กำหนดข้อมูลออเดอร์
    final String date = order['date'] ?? '06-09-2026 14:13';
    final String storeTitle = order['storeTitle'] ?? order['merchant_name'] ?? 'ร้านค้า';
    final String orderIdStr = order['order_id']?.toString() ?? order['id']?.toString() ?? '8822';
    final String displayOrderId = orderIdStr.startsWith('ORD-') ? orderIdStr : 'ORD-$orderIdStr';
    final String chargeId = 'CHG-$orderIdStr';
    
    // ดึงราคา (จัดการทั้งกรณีที่เป็นตัวเลขและ String)
    final dynamic rawPrice = order['totalPrice'] ?? order['total_price'] ?? '0';
    final String priceText = rawPrice.toString().replaceAll('฿', '');
    
    // ดึงรายการอาหารมาจัดเรียงแบบย่อ
    final List items = (order['items'] as List?) ?? [];
    String itemsSummary = '';
    if (items.isNotEmpty) {
      itemsSummary = items.map((item) {
        final name = item['name'] ?? '';
        final qty = item['qty']?.toString() ?? '1';
        return '$name x$qty';
      }).join(', ');
    } else {
      itemsSummary = 'ไม่มีรายการอาหาร';
    }

    // ดึงเหตุผล
    final String cancelReason = order['cancel_reason'] ?? order['reject_reason'] ?? 'สินค้าหมด';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('รายละเอียดคำสั่งซื้อ', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header (ข้อความถูกปฏิเสธ)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'คำสั่งซื้อถูกปฏิเสธ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 8),
                      Text('เมื่อ $date', style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 36),
                  ),
                ],
              ),
            ),
            
            // แถบเทากั้น
            Container(height: 8, color: const Color(0xFFF4F7FA)),

            // ── 2. Order Details (ออเดอร์ #ORD-...)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemsSummary,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text('ออเดอร์ #$displayOrderId', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '฿$priceText',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 1),
                  const SizedBox(height: 24),
                  
                  // ── 3. Detail Rows
                  _buildDetailRow('เหตุผลที่ยกเลิก', cancelReason),
                  const SizedBox(height: 16),
                  _buildDetailRow('วัน/เวลาที่ถูกยกเลิก', date),
                  const SizedBox(height: 16),
                  _buildDetailRow('รหัสคำสั่งซื้อ (Order ID)', displayOrderId),
                  const SizedBox(height: 16),
                  _buildCopyRow('รหัสคำขอ (Charge ID)', chargeId, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
        Expanded(
          child: Text(
            value, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)), 
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyRow(String title, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('คัดลอกรหัสคำขอแล้ว'), duration: Duration(seconds: 1)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F9FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('คัดลอก', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C7E6))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

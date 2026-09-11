import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =======================================================================
// 🟢 หน้ารายละเอียดการปฏิเสธคำสั่งซื้อ (MerchantRejectedOrder)
// ออกแบบอ้างอิงจากหน้า "รายละเอียดคำขอยกเลิก" ฝั่งลูกค้าที่ส่งมาเป็นตัวอย่าง
// ปรับสีและสไตล์ให้เข้ากับธีมแอปร้านค้า (ฟ้า #00C7E6 / การ์ดขาวมุมโค้ง / ตัวหนังสือกรมท่า #1E293B)
// แสดงหลังจากร้านค้ายืนยันปฏิเสธคำสั่งซื้อสำเร็จ
// =======================================================================
class MerchantRejectedOrder extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String rejectReason;
  final DateTime rejectedAt;

  const MerchantRejectedOrder({
    super.key,
    required this.orderData,
    required this.rejectReason,
    required this.rejectedAt,
  });

  // แปลงวันเวลาให้อยู่ในรูปแบบ วว-ดด-ปปปป ชช:นน เหมือนตัวอย่างที่ส่งมา
  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  // 🟢 สร้างรหัสคำขอ (Charge ID) จำลองจากเลขออเดอร์ เพื่อแสดงคู่กับปุ่ม "คัดลอก" ตามภาพตัวอย่าง
  String get _chargeId {
    final digits = (orderData['orderId'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    return 'CHG-${digits.isNotEmpty ? digits : '00000'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายละเอียดการปฏิเสธคำสั่งซื้อ',
          style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 แถบสถานะด้านบน (คู่กับ "คำขอยกเลิกได้รับการยอมรับแล้ว" ของฝั่งลูกค้า)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ปฏิเสธคำสั่งซื้อสำเร็จแล้ว',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'เมื่อ ${_formatDate(rejectedAt)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 30),
                  ),
                ],
              ),
            ),
            Container(height: 10, color: const Color(0xFFF3F4F6)), // เส้นคั่นหนา เหมือนตัวอย่างที่ส่งมา

            // 🟢 การ์ดสินค้าของออเดอร์ที่ถูกปฏิเสธ
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ออเดอร์ ${orderData['orderId'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.receipt_outlined, color: Color(0xFF1E293B), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderData['details'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B), height: 1.4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              orderData['customer'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        orderData['price'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),

                  // 🟢 รายละเอียดคำขอปฏิเสธ (เหตุผลที่ยกเลิก / วันเวลาที่ถูกยกเลิก / รหัสคำสั่งซื้อ / รหัสคำขอ พร้อมปุ่มคัดลอก)
                  _buildDetailRow('เหตุผลที่ยกเลิก', rejectReason),
                  _buildDetailRow('วัน/เวลาที่ถูกยกเลิก', _formatDate(rejectedAt)),
                  _buildDetailRow('รหัสคำสั่งซื้อ (Order ID)', (orderData['orderId'] ?? '').toString().replaceAll('#', '')),
                  _buildCopyableDetailRow(context, 'รหัสคำขอ (Charge ID)', _chargeId),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // แถวแสดงข้อมูล label ทางซ้าย + ค่าทางขวา ใช้ซ้ำสำหรับทุกรายการรายละเอียด
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 แถวแบบเดียวกับ _buildDetailRow แต่มีปุ่ม "คัดลอก" ต่อท้ายค่า สำหรับรหัสคำขอ (Charge ID)
  Widget _buildCopyableDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('คัดลอก $value แล้ว'), backgroundColor: const Color(0xFF00C7E6)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7E6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'คัดลอก',
                    style: TextStyle(color: Color(0xFF00C7E6), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

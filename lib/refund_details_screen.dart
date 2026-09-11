import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับระบบ Copy ลง Clipboard

class RefundDetailsScreen extends StatelessWidget {
  // รับข้อมูลจากระบบหลังบ้านที่ส่งมา
  final Map<String, dynamic> refundData;
  final VoidCallback? onBackPressed;

  const RefundDetailsScreen({super.key, required this.refundData, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูล Data to Store & Send
    final String status = refundData['refund_status'] ?? 'Pending';
    final double amount = refundData['refund_amount'] ?? 0.0;
    final String reason = refundData['cancellation_reason'] ?? 'สินค้าหมด';
    final String orderId = refundData['order_id'] ?? 'ORD-000000';
    final String chargeId = refundData['charge_id'] ?? 'CHG-000000';
    
    // ข้อมูลแสดงผลเพิ่มเติม
    final String date = refundData['request_date'] ?? '23 ส.ค. 2026 10:30';
    final String storeName = refundData['store_name'] ?? 'ร้านค้า';
    final String refundMethod = refundData['refund_method'] ?? 'พร้อมเพย์ (PromptPay)';

    bool isSuccess = status == 'Success';
    bool isFailed = status == 'Failed';
    
    // กำหนดสีและข้อความตามสถานะ (ใช้สีฟ้าแอปสำหรับ Pending, สีเขียวสำหรับ Success)
    Color statusColor = isSuccess ? const Color(0xFF10B981) : (isFailed ? const Color(0xFFEF4444) : const Color(0xFF00C7E6));
    String statusText = isSuccess ? 'คืนเงินสำเร็จแล้ว' : (isFailed ? 'การคืนเงินล้มเหลว' : 'อยู่ระหว่างดำเนินการคืนเงิน');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // สีเทาอ่อนเหมือนหน้าอื่นๆ
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('รายละเอียดการคืนเงิน', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18), 
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
            } else {
              Navigator.pop(context);
            }
          }
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── 1. แถบสถานะด้านบน (Status Header) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: statusColor,
              child: Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            // ── 2. ยอดเงินและไทม์ไลน์ (Timeline) ──
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('รายละเอียดเงินคืน', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('฿${amount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF0B1A30), fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('คืนเงินไปยัง: $refundMethod', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  
                  const SizedBox(height: 32),
                  // แสดง Timeline สถานะ 3 ขั้นตอน
                  _buildTimeline(isSuccess),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'คุณจะได้รับเงินคืนผ่านพร้อมเพย์ต้นทาง ภายใน 1-3 วันทำการ\n(โดยวันที่และเวลาคืนเงินตามจริง จะขึ้นอยู่กับทางธนาคาร)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 3. ข้อมูลคำสั่งซื้อและ Payment ──
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: Color(0xFF0B1A30), size: 20),
                      const SizedBox(width: 8),
                      Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B1A30))),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  
                  // แสดงข้อมูล Data to store ตรงนี้
                  _buildDetailRow('เหตุผลที่ยกเลิก', reason),
                  const SizedBox(height: 12),
                  _buildDetailRow('วัน/เวลาที่ถูกยกเลิก', date),
                  const SizedBox(height: 12),
                  _buildDetailRow('รหัสคำสั่งซื้อ (Order ID)', orderId),
                  const SizedBox(height: 12),
                  // แสดง Charge ID พร้อมปุ่มกดคัดลอก (สำคัญมากเวลายกเคสให้ Payment Gateway)
                  _buildDetailRow('รหัสคำขอ (Charge ID)', chargeId, isCopyable: true, context: context),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget สร้างบรรทัดรายละเอียด
  Widget _buildDetailRow(String label, String value, {bool isCopyable = false, BuildContext? context}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5))),
        Expanded(
          flex: 3, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value, 
                  style: const TextStyle(color: Color(0xFF0B1A30), fontSize: 13.5, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
              if (isCopyable && context != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('คัดลอกรหัสคำขอแล้ว 📋')));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                    child: const Text('คัดลอก', style: TextStyle(color: Color(0xFF00C7E6), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  // Widget สร้างเส้น Timeline (3 ขั้นตอนตามภาพ)
  Widget _buildTimeline(bool isSuccess) {
    final activeColor = const Color(0xFF00C7E6);
    final inactiveColor = Colors.grey[200]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ขั้นตอน 1: คำขอคืนเงินได้รับการอนุมัติ (สำเร็จเสมอ)
        _buildTimelineStep(Icons.check, 'คำขอคืนเงินได้\nรับการอนุมัติ', true, activeColor),
        Expanded(child: Container(margin: const EdgeInsets.only(top: 15), height: 2, color: activeColor)),
        // ขั้นตอน 2: กำลังดำเนินการคืนเงิน (active อยู่ถ้ายังไม่สำเร็จ)
        _buildTimelineStep(Icons.storefront_outlined, 'กำลังดำเนินการ\nคืนเงิน', true, activeColor),
        Expanded(child: Container(margin: const EdgeInsets.only(top: 15), height: 2, color: isSuccess ? activeColor : inactiveColor)),
        // ขั้นตอน 3: คืนเงินสำเร็จแล้ว
        _buildTimelineStep(Icons.account_balance, 'คืนเงินสำเร็จแล้ว', isSuccess, activeColor),
      ],
    );
  }

  // Widget สร้างจุดแต่ละจุดของ Timeline
  Widget _buildTimelineStep(IconData icon, String label, bool isActive, Color activeColor) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.grey[50],
              border: Border.all(color: isActive ? activeColor : Colors.grey[300]!, width: 2),
            ),
            child: Icon(icon, size: 16, color: isActive ? activeColor : Colors.grey[300]),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              fontSize: 11, 
              color: isActive ? const Color(0xFF0B1A30) : Colors.grey[400],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
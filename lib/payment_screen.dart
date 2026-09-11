import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// ============================================================
// PAYMENT SCREEN (หน้าชำระเงิน พร้อมหน้าต่างเลขออเดอร์ GrabFood)
// ============================================================
class PaymentScreen extends StatefulWidget {
  final String storeTitle;
  final int totalPrice;
  final String paymentMethod;
  final int itemCount;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.storeTitle,
    required this.totalPrice,
    required this.paymentMethod,
    required this.itemCount,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  int _remainingSeconds = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeString {
    final m = (_remainingSeconds ~/ 60);
    final s = _remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showCancelWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE), // สีฟ้าอ่อน
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, size: 34, color: Color(0xFF00C7E6)), // สีฟ้าทีมแอป
              ),
              const SizedBox(height: 18),
              const Text(
                'ต้องการยกเลิกหรือไม่',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
              ),
              const SizedBox(height: 10),
              const Text(
                'หากท่านยกเลิก ท่านจะสามารถสั่งซื้อร้านนี้\nได้ภายในอีก 10 นาที',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6), // สีฟ้าทีมแอป
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('ใช่', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('ไม่', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPayment() async {
    setState(() => _isProcessing = true);

    // 1. แสดงหน้าต่างแจ้งเตือนกำลังโหลดตรวจสอบการชำระเงิน
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 4.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7E6)),
              ),
              const SizedBox(height: 22),
              const Text(
                'กำลังโหลดตรวจสอบการชำระเงิน...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
              ),
              const SizedBox(height: 6),
              const Text(
                'กรุณารอสักครู่ ระบบกำลังยืนยันคำสั่งซื้อของคุณ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context); // ปิดหน้าต่างโหลด

      // 2. แสดงเลขออเดอร์สไตล์ GrabFood (ดีไซน์คลีน มินิมอล ใช้งานง่าย)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (grabCtx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ชำระเงินสำเร็จ!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0B1A30)),
                ),
                const SizedBox(height: 6),
                Text(
                  'ร้าน ${widget.storeTitle} ได้รับคำสั่งซื้อแล้ว',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'เลขออเดอร์รับอาหาร',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '#GF-4374',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF00C7E6), letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'แสดงเลขออเดอร์นี้กับทางร้านเพื่อรับอาหาร',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
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
                      Navigator.pop(grabCtx);
                      widget.onPaymentSuccess();
                    },
                    child: const Text('ติดตามสถานะคำสั่งซื้อ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showCancelWarningDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _showCancelWarningDialog,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0B1A30)),
                        ),
                      ),
                    ),
                    const Text('ชำระเงิน', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),

              // ── Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // ── Card 1: THAI QR PAYMENT
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: const Color(0xFF00C7E6).withAlpha(15), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF00C7E6), width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('PromptPay', style: TextStyle(color: Color(0xFF00C7E6), fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: Image.network(
                                'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=ThaiQRPayment_Mock',
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              '',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 16),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: CircularProgressIndicator(
                                    value: _remainingSeconds / 300,
                                    strokeWidth: 4.5,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C7E6)),
                                  ),
                                ),
                                Text(
                                  _timeString,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF00C7E6)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'จำนวนเงินชำระ : ฿${widget.totalPrice}.00',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Card 2: คำแนะนำ
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: const Color(0xFF00C7E6).withAlpha(15), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C7E6),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.info_outline, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('คำแนะนำ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0B1A30)),
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInstructionItem('1.', 'เข้าสู่ Mobile App (ทุกธนาคารในประเทศไทย)'),
                                        _buildInstructionItem('2.', 'เลือกเมนู "จ่ายบิล"'),
                                        _buildInstructionItem('3.', 'สแกนบาร์โค้ด หรือ QR Code'),
                                        _buildInstructionItem('4.', 'ชำระค่าสินค้าและบริการตามยอดเงิน'),
                                        _buildInstructionItem('5.', 'ชำระภายใน 5 นาที และไม่ปิดหน้า QR จนกว่าจะทำการชำระเสร็จ', isRed: true),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [BoxShadow(color: const Color(0xFF00C7E6).withAlpha(100), blurRadius: 14, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C7E6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              elevation: 0,
                            ),
                            onPressed: _isProcessing ? null : _confirmPayment,
                            child: _isProcessing
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('ยืนยันการชำระเงิน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TextButton(
                          onPressed: _showCancelWarningDialog,
                          child: const Text('ยกเลิกคำสั่งซื้อ', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String num, String text, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: TextStyle(fontSize: 13, color: isRed ? const Color(0xFFE53935) : const Color(0xFF64748B), fontWeight: isRed ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isRed ? const Color(0xFFE53935) : const Color(0xFF64748B), height: 1.4, fontWeight: isRed ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}
class ThaiQRPaymentScreen extends StatelessWidget {
  final String storeTitle;
  final VoidCallback onPaymentSuccess;

  const ThaiQRPaymentScreen({super.key, required this.storeTitle, required this.onPaymentSuccess});

  @override
  Widget build(BuildContext context) {
    return PaymentScreen(
      storeTitle: storeTitle,
      totalPrice: 65,
      paymentMethod: 'QR Code (พร้อมเพย์)',
      itemCount: 1,
      onPaymentSuccess: onPaymentSuccess,
    );
  }
}
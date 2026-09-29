import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';
import 'merchant_slip_review_support.dart';

class MerchantSlipReviewScreen extends StatefulWidget {
  const MerchantSlipReviewScreen({
    super.key,
    required this.merchantId,
    required this.orderId,
  });

  final Object merchantId;
  final Object orderId;

  @override
  State<MerchantSlipReviewScreen> createState() => _MerchantSlipReviewScreenState();
}

class _MerchantSlipReviewScreenState extends State<MerchantSlipReviewScreen> {
  Map<String, dynamic>? _slip;
  bool _loading = true;
  bool _reporting = false;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _loadSlip();
  }

  Future<void> _loadSlip() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantPaymentSlip(widget.merchantId, widget.orderId)),
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        _slip = response.statusCode == 200 && body['success'] == true
            ? Map<String, dynamic>.from(body['data'])
            : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reportIssue() async {
    setState(() => _reporting = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.merchantReportPaymentSlip(widget.merchantId, widget.orderId)),
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['message']?.toString() ?? 'แจ้งลูกค้าแล้ว'),
          backgroundColor: response.statusCode == 200
              ? const Color(0xFF00C7E6)
              : const Color(0xFFEF4444),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถรายงานสลิปได้'), backgroundColor: Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  Future<void> _approveVerifiedSlip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันรับสลิป'),
        content: const Text('ยืนยันว่าได้รับเงินตามสลิปนี้แล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('ฉันได้รับเงินแล้ว'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _approving = true);
    try {
      final response = await http
          .put(
            Uri.parse(
              ApiConfig.merchantOrderStatus(widget.merchantId, widget.orderId),
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': 'กำลังปรุง',
              'merchant_confirmed_payment': true,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยืนยันรับสลิปแล้ว เริ่มเตรียมอาหารได้เลย'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ?? 'ไม่สามารถยืนยันรับสลิปได้',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถยืนยันรับสลิปได้: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  String _money(Object? value) {
    final amount = double.tryParse(value?.toString() ?? '');
    return amount == null ? '-' : '฿${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final slip = _slip;
    final isRejected = slip?['status']?.toString() == 'REJECTED';
    final imageUrl = resolveMerchantSlipImageUrl(slip?['slip_url']?.toString() ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('ตรวจสอบสลิป', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6)))
          : slip == null
          ? const Center(child: Text('ไม่พบหลักฐานการชำระเงิน'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ออเดอร์ #ORD-${widget.orderId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0B1A30))),
                  const SizedBox(height: 4),
                  Text('ลูกค้า: ${slip['customer_name'] ?? 'ไม่ระบุชื่อ'}', style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isRejected ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      children: [
                        _amountRow('ยอดที่ต้องชำระ', _money(slip['expected_amount'])),
                        const Divider(height: 24),
                        _amountRow('ยอดจากสลิป OCR', _money(slip['detected_amount']), valueColor: isRejected ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                        const SizedBox(height: 12),
                        Text(
                          slip['validation_reason']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isRejected ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(height: 180, child: Center(child: Text('ไม่สามารถแสดงรูปสลิปได้'))),
                      ),
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _approving ? null : _approveVerifiedSlip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0xFFB8E8D0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _approving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ฉันได้รับเงินแล้ว',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                  if (isRejected) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _reporting ? null : _reportIssue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        icon: const Icon(Icons.report_problem_outlined, color: Colors.white),
                        label: Text(_reporting ? 'กำลังรายงาน...' : 'รายงานสลิปผิดปกติ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _amountRow(String label, String value, {Color valueColor = const Color(0xFF0B1A30)}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 19, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

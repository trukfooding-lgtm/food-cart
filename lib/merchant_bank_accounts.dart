import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';
import 'merchant_add_bank_account.dart';

class MerchantBankAccounts extends StatefulWidget {
  final dynamic merchantId;

  const MerchantBankAccounts({super.key, required this.merchantId});

  @override
  State<MerchantBankAccounts> createState() => _MerchantBankAccountsState();
}

class _MerchantBankAccountsState extends State<MerchantBankAccounts> {
  List<Map<String, dynamic>> _accounts = [];
  int? _selectedAccountId;
  int? _primaryAccountId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (widget.merchantId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantBankAccounts(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception('load failed');
      }
      final accounts = (body['data'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      int? primaryId;
      for (final account in accounts) {
        if (account['is_primary'] == 1 || account['is_primary'] == true) {
          primaryId = int.tryParse(account['id'].toString());
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _primaryAccountId = primaryId;
        _selectedAccountId =
            primaryId ??
            (accounts.isEmpty
                ? null
                : int.tryParse(accounts.first['id'].toString()));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('โหลดบัญชีธนาคารไม่สำเร็จ')));
    }
  }

  Future<bool> _savePrimaryAccount() async {
    if (_selectedAccountId == null || widget.merchantId == null) return false;
    setState(() => _isSaving = true);
    try {
      final response = await http.put(
        Uri.parse(
          ApiConfig.merchantPrimaryBankAccount(
            widget.merchantId,
            _selectedAccountId!,
          ),
        ),
        headers: {'Content-Type': 'application/json'},
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception('save failed');
      }
      if (!mounted) return false;
      setState(() => _primaryAccountId = _selectedAccountId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกบัญชีหลักแล้ว')));
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกบัญชีหลักไม่สำเร็จ')));
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmSavePrimaryAccount() async {
    if (_selectedAccountId == null || _isSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการเปลี่ยนบัญชีหลัก'),
        content: const Text(
          'ต้องการเปลี่ยนบัญชีที่เลือกเป็นบัญชีหลักใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08BDD7),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _savePrimaryAccount();
    }
  }

  Future<void> _openAddAccount() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantAddBankAccount(merchantId: widget.merchantId),
      ),
    );
    if (added == true) {
      setState(() => _isLoading = true);
      await _loadAccounts();
    }
  }

  Future<bool> _confirmAndDelete(Map<String, dynamic> account) async {
    final accountId = int.tryParse(account['id'].toString());
    final isPrimary = accountId == _primaryAccountId;

    if (isPrimary && _accounts.length > 1) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ไม่สามารถลบบัญชีหลักได้'),
          content: const Text(
            'กรุณาเลือกบัญชีอื่นเป็นบัญชีหลักและกดบันทึกก่อนลบบัญชีนี้',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isPrimary ? 'ลบบัญชีธนาคารสุดท้าย' : 'ลบบัญชีธนาคาร'),
        content: Text(
          isPrimary
              ? 'หลังลบบัญชีนี้ คุณจะไม่สามารถถอนเงินได้จนกว่าจะเพิ่มบัญชีใหม่'
              : 'ต้องการลบบัญชีธนาคารนี้จริงหรือไม่? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );
    if (confirmed != true || accountId == null || widget.merchantId == null) {
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.merchantBankAccount(widget.merchantId, accountId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception('delete failed');
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบบัญชีธนาคารไม่สำเร็จ')));
      }
      return false;
    }
  }

  String _bankName(String code) {
    const names = {
      'KBANK': 'กสิกรไทย (KBANK)',
      'SCB': 'ไทยพาณิชย์ (SCB)',
      'BBL': 'กรุงเทพ (BBL)',
      'KTB': 'กรุงไทย (KTB)',
    };
    return names[code] ?? code;
  }

  String _logoPath(String code) {
    const logos = {
      'KBANK': 'assets/images/kbank_logo.png',
      'SCB': 'assets/images/scb_logo.png',
      'BBL': 'assets/images/bbl_logo.png',
      'KTB': 'assets/images/ktb_logo.png',
    };
    return logos[code] ?? 'assets/images/ktb_logo.png';
  }

  String _promptPayTypeName(String type) {
    const names = {
      'PHONE': 'เบอร์โทรศัพท์',
      'NATIONAL_ID': 'เลขบัตรประชาชน',
      'TAX_ID': 'เลขประจำตัวผู้เสียภาษี',
    };
    return names[type] ?? 'PromptPay';
  }

  String _maskedNumber(Object? value) {
    final number = value?.toString() ?? '';
    if (number.length <= 4) return number;
    return 'xxxxxx${number.substring(number.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF314158),
            size: 19,
          ),
        ),
        title: const Text(
          'บัญชีธนาคาร',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < _accounts.length;
                            index++
                          ) ...[
                            Dismissible(
                              key: ValueKey(_accounts[index]['id']),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) =>
                                  _confirmAndDelete(_accounts[index]),
                              onDismissed: (_) {
                                final removedId = int.tryParse(
                                  _accounts[index]['id'].toString(),
                                );
                                setState(() {
                                  _accounts.removeAt(index);
                                  if (_selectedAccountId == removedId) {
                                    _selectedAccountId =
                                        _primaryAccountId == removedId
                                        ? null
                                        : _primaryAccountId;
                                  }
                                  if (_primaryAccountId == removedId) {
                                    _primaryAccountId = null;
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ลบบัญชีธนาคารแล้ว'),
                                  ),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              child: _BankCard(
                                selected:
                                    _selectedAccountId ==
                                    int.tryParse(
                                      _accounts[index]['id'].toString(),
                                    ),
                                onTap: () {
                                  setState(() {
                                    _selectedAccountId = int.tryParse(
                                      _accounts[index]['id'].toString(),
                                    );
                                  });
                                },
                                logoPath: _logoPath(
                                  _accounts[index]['bank_code'].toString(),
                                ),
                                isPromptPay:
                                    _accounts[index]['payment_type'] ==
                                    'PROMPTPAY',
                                bankName:
                                    _accounts[index]['payment_type'] ==
                                        'PROMPTPAY'
                                    ? 'PromptPay (${_promptPayTypeName(_accounts[index]['promptpay_type'].toString())})'
                                    : _bankName(
                                        _accounts[index]['bank_code']
                                            .toString(),
                                      ),
                                accountName:
                                    _accounts[index]['payment_type'] ==
                                        'PROMPTPAY'
                                    ? _accounts[index]['receiver_name']
                                          .toString()
                                    : _accounts[index]['account_name']
                                          .toString(),
                                accountNumber: _maskedNumber(
                                  _accounts[index]['payment_type'] ==
                                          'PROMPTPAY'
                                      ? _accounts[index]['promptpay_id']
                                      : _accounts[index]['account_number'],
                                ),
                                primary:
                                    _primaryAccountId ==
                                    int.tryParse(
                                      _accounts[index]['id'].toString(),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          InkWell(
                            onTap: _openAddAccount,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFCAD5E5),
                                  width: 1.5,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFFE9EEF5),
                                    child: Icon(
                                      Icons.add,
                                      size: 19,
                                      color: Color(0xFF52647C),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'เพิ่มบัญชีธนาคาร',
                                    style: TextStyle(
                                      color: Color(0xFF42536A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'บัญชีที่เลือกจะใช้เป็นบัญชีหลักสำหรับรับเงินและถอนเงิน',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF91A3BF),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _selectedAccountId == null || _isSaving
                      ? null
                      : _confirmSavePrimaryAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08BDD7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9DEE4),
                    elevation: 8,
                    shadowColor: const Color(0x5500BCD4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Text(
                    _isSaving ? 'กำลังบันทึก...' : 'บันทึก',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String logoPath;
  final bool isPromptPay;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final bool primary;

  const _BankCard({
    required this.selected,
    required this.onTap,
    required this.logoPath,
    required this.isPromptPay,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF05BDD8) : const Color(0xFFE1E7EF),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPromptPay)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FAFD),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Color(0xFF08AFC9),
                  size: 32,
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  logoPath,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: const TextStyle(
                      color: Color(0xFF253247),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ชื่อบัญชี $accountName',
                    style: const TextStyle(
                      color: Color(0xFF8291A7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accountNumber,
                    style: const TextStyle(
                      color: Color(0xFF253247),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    children: [
                      if (primary)
                        const _Badge(
                          text: 'บัญชีหลัก',
                          foreground: Color(0xFF078BA4),
                          background: Color(0xFFE7FAFD),
                          border: Color(0xFF73DDEB),
                        ),
                      const _Badge(
                        text: 'ยืนยันแล้ว',
                        foreground: Color(0xFF078960),
                        background: Color(0xFFEAFBF4),
                        border: Color(0xFF8DE7C1),
                        dot: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF18BE8A) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF18BE8A)
                      : const Color(0xFFCAD5E1),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color foreground;
  final Color background;
  final Color border;
  final bool dot;

  const _Badge({
    required this.text,
    required this.foreground,
    required this.background,
    required this.border,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

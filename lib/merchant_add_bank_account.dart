import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

class MerchantAddBankAccount extends StatefulWidget {
  final dynamic merchantId;

  const MerchantAddBankAccount({super.key, required this.merchantId});

  @override
  State<MerchantAddBankAccount> createState() => _MerchantAddBankAccountState();
}

class _MerchantAddBankAccountState extends State<MerchantAddBankAccount> {
  String _paymentType = 'BANK_ACCOUNT';
  String _selectedBank = 'KTB';
  String _promptPayType = 'PHONE';
  bool _setAsPrimary = true;
  bool _isSaving = false;
  bool _accountNameTouched = false;
  bool _accountNumberTouched = false;
  bool _promptPayIdTouched = false;
  bool _receiverNameTouched = false;

  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _promptPayIdController = TextEditingController();
  final _receiverNameController = TextEditingController();

  static const _banks = [
    _BankOption(
      code: 'KBANK',
      name: 'ธนาคารกสิกรไทย (KBANK)',
      englishName: 'Kasikornbank',
      logoPath: 'assets/images/kbank_logo.png',
    ),
    _BankOption(
      code: 'SCB',
      name: 'ธนาคารไทยพาณิชย์ (SCB)',
      englishName: 'Siam Commercial Bank',
      logoPath: 'assets/images/scb_logo.png',
    ),
    _BankOption(
      code: 'BBL',
      name: 'ธนาคารกรุงเทพ (BBL)',
      englishName: 'Bangkok Bank',
      logoPath: 'assets/images/bbl_logo.png',
    ),
    _BankOption(
      code: 'KTB',
      name: 'ธนาคารกรุงไทย (KTB)',
      englishName: 'Krungthai Bank PCL.',
      logoPath: 'assets/images/ktb_logo.png',
    ),
  ];

  static const _promptPayTypes = {
    'PHONE': 'เบอร์โทรศัพท์',
    'NATIONAL_ID': 'เลขบัตรประชาชน',
    'TAX_ID': 'เลขประจำตัวผู้เสียภาษี',
  };

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _promptPayIdController.dispose();
    _receiverNameController.dispose();
    super.dispose();
  }

  bool _isThaiOrEnglishName(String value) =>
      RegExp(r'^[A-Za-z\u0E00-\u0E4F\s]+$').hasMatch(value.trim());

  bool get _bankFormValid {
    final name = _accountNameController.text.trim();
    final number = _accountNumberController.text.trim();
    return name.isNotEmpty &&
        _isThaiOrEnglishName(name) &&
        number.isNotEmpty &&
        RegExp(r'^\d+$').hasMatch(number);
  }

  bool get _promptPayFormValid {
    final id = _promptPayIdController.text.trim();
    final receiver = _receiverNameController.text.trim();
    final correctLength = _promptPayType == 'PHONE'
        ? id.length == 10 && id.startsWith('0')
        : id.length == 13;
    return correctLength &&
        RegExp(r'^\d+$').hasMatch(id) &&
        receiver.isNotEmpty &&
        _isThaiOrEnglishName(receiver);
  }

  bool get _isFormValid =>
      _paymentType == 'BANK_ACCOUNT' ? _bankFormValid : _promptPayFormValid;

  String? get _accountNameError {
    if (!_accountNameTouched) return null;
    final value = _accountNameController.text.trim();
    if (value.isEmpty) return 'กรุณากรอกชื่อบัญชี';
    if (!_isThaiOrEnglishName(value)) {
      return 'ชื่อบัญชีต้องเป็นตัวอักษรเท่านั้น';
    }
    return null;
  }

  String? get _accountNumberError {
    if (!_accountNumberTouched) return null;
    final value = _accountNumberController.text.trim();
    if (value.isEmpty) return 'กรุณากรอกเลขที่บัญชี';
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'เลขที่บัญชีต้องเป็นตัวเลขเท่านั้น';
    }
    return null;
  }

  String? get _promptPayIdError {
    if (!_promptPayIdTouched) return null;
    final value = _promptPayIdController.text.trim();
    if (value.isEmpty) return 'กรุณากรอกหมายเลข PromptPay';
    if (_promptPayType == 'PHONE' &&
        (value.length != 10 || !value.startsWith('0'))) {
      return 'หมายเลขโทรศัพท์ไม่ถูกต้อง';
    }
    if (_promptPayType != 'PHONE' && value.length != 13) {
      return 'หมายเลข PromptPay ต้องมี 13 หลัก';
    }
    return null;
  }

  String? get _receiverNameError {
    if (!_receiverNameTouched) return null;
    final value = _receiverNameController.text.trim();
    if (value.isEmpty) return 'กรุณากรอกชื่อผู้รับเงิน';
    if (!_isThaiOrEnglishName(value)) {
      return 'ชื่อผู้รับเงินต้องเป็นตัวอักษรเท่านั้น';
    }
    return null;
  }

  String get _promptPayHint {
    switch (_promptPayType) {
      case 'NATIONAL_ID':
        return 'X-XXXX-XXXXX-XX-X';
      case 'TAX_ID':
        return 'XXXXXXXXXXXXX';
      default:
        return '08X-XXX-XXXX';
    }
  }

  Future<void> _addAccount() async {
    if (!_isFormValid || _isSaving || widget.merchantId == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final data = _paymentType == 'BANK_ACCOUNT'
        ? {
            'payment_type': 'BANK_ACCOUNT',
            'bank_code': _selectedBank,
            'account_name': _accountNameController.text.trim(),
            'account_number': _accountNumberController.text.trim(),
            'is_primary': _setAsPrimary,
          }
        : {
            'payment_type': 'PROMPTPAY',
            'promptpay_type': _promptPayType,
            'promptpay_id': _promptPayIdController.text.trim(),
            'receiver_name': _receiverNameController.text.trim(),
            'is_primary': _setAsPrimary,
          };

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.merchantBankAccounts(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 201 || body['success'] != true) {
        throw Exception(body['message'] ?? 'เพิ่มช่องทางรับเงินไม่สำเร็จ');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มช่องทางรับเงินเรียบร้อยแล้ว')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        surfaceTintColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF314158),
            size: 18,
          ),
        ),
        title: const Text(
          'บัญชี',
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
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(text: 'วิธีรับเงิน'),
                    const SizedBox(height: 8),
                    _SimpleSelector(
                      value: _paymentType,
                      options: const {
                        'BANK_ACCOUNT': 'บัญชีธนาคาร',
                        'PROMPTPAY': 'PromptPay',
                      },
                      onSelected: (value) {
                        setState(() => _paymentType = value);
                      },
                    ),
                    const SizedBox(height: 22),
                    if (_paymentType == 'BANK_ACCOUNT')
                      _buildBankFields()
                    else
                      _buildPromptPayFields(),
                    const SizedBox(height: 28),
                    _buildPrimarySwitch(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isSaving ? _addAccount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08BDD7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9DEE4),
                    elevation: 5,
                    shadowColor: const Color(0x5500BCD4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'เพิ่มบัญชี',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankFields() {
    final selected = _banks.firstWhere((bank) => bank.code == _selectedBank);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: 'เลือกธนาคาร'),
        const SizedBox(height: 8),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => PopupMenuButton<String>(
              initialValue: _selectedBank,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 4),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
              onSelected: (value) => setState(() => _selectedBank = value),
              itemBuilder: (context) => _banks
                  .map(
                    (bank) => PopupMenuItem<String>(
                      value: bank.code,
                      height: 62,
                      child: _BankOptionView(bank: bank),
                    ),
                  )
                  .toList(),
              child: Row(
                children: [
                  Expanded(child: _BankOptionView(bank: selected)),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF5C6168),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _FieldLabel(text: 'ชื่อบัญชี'),
        const SizedBox(height: 8),
        _FormInput(
          icon: Icons.badge_outlined,
          hint: 'ชื่อบัญชี',
          controller: _accountNameController,
          errorText: _accountNameError,
          onChanged: (_) {
            setState(() => _accountNameTouched = true);
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel(text: 'เลขที่บัญชี'),
        const SizedBox(height: 8),
        _FormInput(
          icon: Icons.credit_card,
          hint: 'หมายเลขบัญชี',
          controller: _accountNumberController,
          errorText: _accountNumberError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          showClearButton: true,
          onChanged: (_) {
            setState(() => _accountNumberTouched = true);
          },
        ),
      ],
    );
  }

  Widget _buildPromptPayFields() {
    final maxLength = _promptPayType == 'PHONE' ? 10 : 13;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: 'ประเภท PromptPay'),
        const SizedBox(height: 8),
        _SimpleSelector(
          value: _promptPayType,
          options: _promptPayTypes,
          onSelected: (value) {
            setState(() {
              _promptPayType = value;
              _promptPayIdController.clear();
              _promptPayIdTouched = false;
            });
          },
        ),
        const SizedBox(height: 22),
        const _FieldLabel(text: 'หมายเลข PromptPay'),
        const SizedBox(height: 8),
        _FormInput(
          icon: Icons.numbers,
          hint: _promptPayHint,
          controller: _promptPayIdController,
          errorText: _promptPayIdError,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          showClearButton: true,
          onChanged: (_) {
            setState(() => _promptPayIdTouched = true);
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel(text: 'ชื่อผู้รับเงิน'),
        const SizedBox(height: 8),
        _FormInput(
          icon: Icons.person_outline,
          hint: 'ชื่อผู้รับเงิน',
          controller: _receiverNameController,
          errorText: _receiverNameError,
          onChanged: (_) {
            setState(() => _receiverNameTouched = true);
          },
        ),
      ],
    );
  }

  Widget _buildPrimarySwitch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE6F7FA),
            child: Icon(Icons.star, color: Color(0xFF087E91), size: 19),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตั้งเป็นบัญชีหลักทันที',
                  style: TextStyle(
                    color: Color(0xFF202A3A),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'ยอดเงินการขายทั้งหมดจะใช้ช่องทางนี้เป็นช่องทางรับเงินหลัก',
                  style: TextStyle(
                    color: Color(0xFF5E6570),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _setAsPrimary,
            onChanged: (value) => setState(() => _setAsPrimary = value),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF08BDD7),
          ),
        ],
      ),
    );
  }
}

class _SimpleSelector extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  const _SimpleSelector({
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: PopupMenuButton<String>(
        initialValue: value,
        position: PopupMenuPosition.under,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        onSelected: onSelected,
        itemBuilder: (context) => options.entries
            .map(
              (entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                options[value] ?? '',
                style: const TextStyle(
                  color: Color(0xFF202A3A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5C6168)),
          ],
        ),
      ),
    );
  }
}

class _BankOption {
  final String code;
  final String name;
  final String englishName;
  final String logoPath;

  const _BankOption({
    required this.code,
    required this.name,
    required this.englishName,
    required this.logoPath,
  });
}

class _BankOptionView extends StatelessWidget {
  final _BankOption bank;

  const _BankOptionView({required this.bank});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            bank.logoPath,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bank.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF202A3A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                bank.englishName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF5E6570), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF202A3A),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool showClearButton;

  const _FormInput({
    required this.icon,
    required this.hint,
    required this.controller,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.showClearButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(14),
            border: errorText == null
                ? null
                : Border.all(color: const Color(0xFFEF4444)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF737B85)),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: Color(0xFF202A3A),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFFAEB8C8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (showClearButton)
                InkWell(
                  onTap: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  borderRadius: BorderRadius.circular(13),
                  child: const CircleAvatar(
                    radius: 13,
                    backgroundColor: Color(0xFFDDE2E7),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF5D6874),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
          ),
        ],
      ],
    );
  }
}

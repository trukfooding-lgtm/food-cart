import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';

class EditMerchantProfileScreen extends StatefulWidget {
  final dynamic merchantId;
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialType;
  // 🟢 เพิ่มค่าเริ่มต้นสำหรับ เบอร์ติดต่อร้าน และช่องทางติดต่ออื่น (Line, Facebook)
  final String initialLineId;
  final String initialFacebook;

  const EditMerchantProfileScreen({
    super.key,
    required this.merchantId,
    this.initialName = 'สมชาย สายกิน',
    this.initialEmail = 'somchai@mail.com',
    this.initialPhone = '0812345678',
    this.initialType = 'ร้านอาหารสตรีทฟู้ด',
    this.initialLineId = '',
    this.initialFacebook = '',
  });

  @override
  State<EditMerchantProfileScreen> createState() =>
      _EditMerchantProfileScreenState();
}

class _EditMerchantProfileScreenState extends State<EditMerchantProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedType;

  // 🟢 Controller สำหรับ เบอร์ติดต่อร้าน และช่องทางติดต่ออื่น (Line, Facebook)
  late TextEditingController _lineIdController;
  late TextEditingController _facebookController;

  final List<String> _merchantTypes = [
    'ร้านอาหารสตรีทฟู้ด',
    'ร้านเครื่องดื่ม / คาเฟ่',
    'ร้านเบเกอรี่ / ของหวาน',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _selectedType = _merchantTypes.contains(widget.initialType)
        ? widget.initialType
        : _merchantTypes[0];

    // 🟢 ตั้งค่าเริ่มต้นของ เบอร์ติดต่อร้าน และช่องทางติดต่ออื่น
    _lineIdController = TextEditingController(text: widget.initialLineId);
    _facebookController = TextEditingController(text: widget.initialFacebook);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _lineIdController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // ดึงข้อมูลที่แก้ไขแล้วไปใช้งานต่อ
      String updatedName = _nameController.text;
      String updatedEmail = _emailController.text;
      String updatedStorePhone = _phoneController.text;
      String updatedType = _selectedType;

      // 🟢 ดึงข้อมูล เบอร์ติดต่อร้าน และช่องทางติดต่ออื่นที่แก้ไขแล้ว
      String updatedLineId = _lineIdController.text.trim();
      String updatedFacebook = _facebookController.text;

      if (widget.merchantId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบ ID ร้านค้า กรุณาเข้าสู่ระบบใหม่'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final response = await http.put(
          Uri.parse(ApiConfig.merchantProfile(widget.merchantId)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': updatedName,
            'email': updatedEmail,
            'store_phone': updatedStorePhone,
            'type': updatedType,
            'line_id': updatedLineId,
            'facebook_url': updatedFacebook,
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode != 200 || data['success'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'ไม่สามารถบันทึกข้อมูลได้'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (!mounted) return;

        // แสดง Popup แจ้งเตือนบันทึกสำเร็จ
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'สำเร็จ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('บันทึกข้อมูลโปรไฟล์ร้านค้าเรียบร้อยแล้ว'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Dialog
                  Navigator.pop(context, {
                    'name': updatedName,
                    'email': updatedEmail,
                    'type': updatedType,
                    // 🟢 ส่งค่าที่แก้ไขแล้วกลับไปด้วย
                    'storePhone': updatedStorePhone,
                    'lineId': updatedLineId,
                    'facebook': updatedFacebook,
                  }); // กลับหน้าก่อนหน้าพร้อมส่งค่าใหม่
                },
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    color: Color(0xFF00C7E6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // เปลี่ยนพื้นหลังเป็นสีขาว
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0B1A30),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แก้ไขโปรไฟล์ร้านค้า',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 ส่วนรูปโปรไฟล์ร้านค้าตรงกลาง — 🟢 ใช้ไอคอนคนว่าง (placeholder) แทนรูปคนจริง (คงที่ ไม่รองรับการเปลี่ยนรูปในหน้านี้)
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F4F6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF9CA3AF),
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 📝 ฟิลด์แก้ไขชื่อร้านค้า
              _buildLabel('ชื่อร้านค้า'),
              _buildTextFormField(
                controller: _nameController,
                hintText: 'กรุณากรอกชื่อร้านค้า',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อร้านค้า';
                  }
                  // 🟢 อนุญาตเฉพาะภาษาไทยและภาษาอังกฤษ (รวมช่องว่าง) เท่านั้น
                  final nameRegex = RegExp(r'^[a-zA-Zก-๙\s]+$');
                  if (!nameRegex.hasMatch(value)) {
                    return 'ชื่อร้านค้าต้องเป็นภาษาไทยหรือภาษาอังกฤษเท่านั้น';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 📧 ฟิลด์แก้ไขอีเมล
              _buildLabel('อีเมล'),
              _buildTextFormField(
                controller: _emailController,
                hintText: 'กรุณากรอกอีเมล',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกอีเมล';
                  }
                  // 🟢 ต้องมี @ และรูปแบบอีเมลที่ถูกต้อง
                  final emailRegex = RegExp(
                    r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'รูปแบบอีเมลไม่ถูกต้อง (ต้องมี @อีเมล)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 📱 ฟิลด์แก้ไขเบอร์โทรศัพท์
              _buildLabel('เบอร์โทรศัพท์'),
              _buildTextFormField(
                controller: _phoneController,
                hintText: 'กรุณากรอกเบอร์โทรศัพท์',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  // 🟢 ต้องเป็นตัวเลข 10 หลักเท่านั้น
                  final phoneRegex = RegExp(r'^[0-9]{10}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลักเท่านั้น';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 🏷️ ดร็อปดาวน์เลือกประเภทร้านค้า
              _buildLabel('ประเภทร้านค้า'),
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF9CA3AF),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF00C7E6),
                      width: 1.5,
                    ),
                  ),
                ),
                items: _merchantTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // 💬 ฟิลด์ LINE ID
              _buildLabel('LINE ID'),
              _buildTextFormField(
                controller: _lineIdController,
                hintText: 'เช่น @merchantshop',
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return null; // ไม่บังคับกรอก
                  final lineIdRegex = RegExp(r'^@?[A-Za-z0-9._-]{2,100}$');
                  if (!lineIdRegex.hasMatch(value.trim())) {
                    return 'กรุณากรอก LINE ID ให้ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 📘 ฟิลด์ Facebook
              _buildLabel('เฟซบุ๊ก (ลิงก์ Facebook)'),
              _buildTextFormField(
                controller: _facebookController,
                hintText: 'เช่น https://facebook.com/merchantshop',
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return null; // ไม่บังคับกรอก
                  // 🟢 ถ้ากรอก ต้องเป็นลิงก์เท่านั้น
                  final urlRegex = RegExp(
                    r'^(https?:\/\/)?([\w\-]+\.)+[a-zA-Z]{2,}(\/\S*)?$',
                  );
                  if (!urlRegex.hasMatch(value)) {
                    return 'กรุณากรอกเป็นลิงก์ Facebook เท่านั้น';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // 💾 ปุ่มบันทึกข้อมูล
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'บันทึกการแก้ไข',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ช่วยสร้าง Label ด้านบนช่องกรอก
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B1A30),
        ),
      ),
    );
  }

  // Widget ช่วยสร้าง TextFormField โค้งมนสไตล์ใหม่ (รองรับ validation)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00C7E6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

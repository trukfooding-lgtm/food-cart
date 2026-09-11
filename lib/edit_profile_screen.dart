import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'api.config.dart';

class EditProfileScreen extends StatefulWidget {
  final String customerId;
  final String initialName, initialPhone, initialEmail;
  final String? initialImage;
  const EditProfileScreen({
    super.key,
    this.customerId = '1',
    required this.initialName,
    required this.initialPhone,
    required this.initialEmail,
    this.initialImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fNameCtrl, _lNameCtrl, _phoneCtrl, _emailCtrl;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final names = widget.initialName.split(' ');
    _fNameCtrl = TextEditingController(text: names.isNotEmpty ? names[0] : '');
    _lNameCtrl = TextEditingController(text: names.length > 1 ? names.sublist(1).join(' ') : '');
    _phoneCtrl = TextEditingController(text: widget.initialPhone.replaceAll('-', ''));
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _currentImageUrl = widget.initialImage;
  }

  // ตัวช่วยแสดงแจ้งเตือนเวลากรอกผิด
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );

  // เลือกรูปภาพจากเครื่อง
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      _showError('เลือกรูปภาพไม่สำเร็จ: $e');
    }
  }

  // เมนูเลือกวิธีอัปรูป
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'เลือกรูปโปรไฟล์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00C7E6)),
                title: const Text('เลือกจากแกลเลอรี (Gallery)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00C7E6)),
                title: const Text('ถ่ายรูปด้วยกล้อง (Camera)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('ข้อมูลของคุณ (Your Information)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)))),
            const SizedBox(height: 20),
            
            _buildField('ชื่อ', _fNameCtrl),
            _buildField('นามสกุล', _lNameCtrl),
            _buildField('เบอร์โทรศัพท์', _phoneCtrl, isNum: true, maxLen: 10),
            _buildField('อีเมล', _emailCtrl, isEmail: true),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24).copyWith(top: 10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7E6),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _onSave,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('บันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันกดบันทึก 
  Future<void> _onSave() async {
    final fName = _fNameCtrl.text.trim(), lName = _lNameCtrl.text.trim(), phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase(); 

    // เช็คข้อมูลเบื้องต้น
    if (fName.isEmpty || lName.isEmpty || !RegExp(r'^[a-zA-Zก-ฮะ-์\s]+$').hasMatch('$fName$lName')) return _showError('⚠️ ชื่อ-นามสกุลไม่ถูกต้อง');
    if (phone.length != 10 || !phone.startsWith('0')) return _showError('⚠️ เบอร์โทรต้องมี 10 หลัก');
    if (!email.endsWith('@gmail.com') || !RegExp(r'^[a-z0-9@._-]+$').hasMatch(email)) return _showError('⚠️ อีเมลไม่ถูกต้อง');

    setState(() => _isLoading = true);

    try {
      final customerId = widget.customerId; 
      final String fullName = '$fName $lName'.trim();
      String? finalImageUrl = _currentImageUrl;

      // 1. ถ้ามีการเลือกรูปใหม่ ให้อัปโหลดไฟล์ไปยังเซิร์ฟเวอร์ก่อน
      if (_selectedImage != null) {
        final uploadUri = Uri.parse(ApiConfig.uploadCustomerImage);
        final request = http.MultipartRequest('POST', uploadUri);
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );

        final streamedResponse = await request.send();
        final uploadResponse = await http.Response.fromStream(streamedResponse);

        if (uploadResponse.statusCode == 200) {
          final uploadData = jsonDecode(uploadResponse.body);
          finalImageUrl = uploadData['url'];
        } else {
          setState(() => _isLoading = false);
          return _showError('⚠️ อัปโหลดรูปภาพไม่สำเร็จ (${uploadResponse.statusCode})');
        }
      }

      // 2. ยิง API อัปเดตข้อมูลลูกค้า
      final url = '${ApiConfig.baseUrl}/api/customers/$customerId';
      
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': fullName,
          'email': email,
          'phone': phone,
          'profile_image': finalImageUrl,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // ส่งข้อมูลกลับไปให้หน้า Profile อัปเดต UI ทันที
        Navigator.pop(context, {
          'name': fullName,
          'phone': phone,
          'email': email,
          'profile_image': finalImageUrl,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('บันทึกข้อมูลโปรไฟล์เรียบร้อยแล้ว ✅'), 
          backgroundColor: Color(0xFF10B981)
        ));
      } else {
        final resData = jsonDecode(response.body);
        _showError(resData['message'] ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e');
    }
  }

  // --- ส่วนของ UI ย่อยที่แยกออกมาเพื่อความคลีน ---

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentImageUrl!);
    }

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isNum = false, bool isEmail = false, int? maxLen}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : (isEmail ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]'))] : []),
        maxLength: maxLen,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.black54, fontSize: 14), counterText: '',
          filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C7E6), width: 2)),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.config.dart';

// =======================================================================
// 🟢 หน้าสำหรับแจ้งรายงานปัญหา (MerchantReport)
// =======================================================================
class MerchantReport extends StatefulWidget {
  final dynamic merchantId;

  const MerchantReport({super.key, required this.merchantId});

  @override
  State<MerchantReport> createState() => _MerchantReportState();
}

class _MerchantReportState extends State<MerchantReport> {
  String _selectedIssueType = 'ปัญหาระบบแอปพลิเคชัน';
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _orderIdController =
      TextEditingController(); // 🟢 เลขออเดอร์ของลูกค้าที่สั่งเล่น (บังคับกรอกกรณีปัญหาเกี่ยวกับออเดอร์)
  final List<File> _selectedImages = [];
  bool _isSending = false;

  final List<String> _issueTypes = [
    'ปัญหาระบบแอปพลิเคชัน',
    'ปัญหาเกี่ยวกับออเดอร์',
    'ข้อเสนอแนะอื่นๆ',
  ];

  // 🟢 กำหนดว่าหัวข้อนี้ต้องบังคับกรอกเลขออเดอร์หรือไม่ (เช่น กรณีลูกค้าสั่งเล่น)
  bool get _isOrderIssue => _selectedIssueType == 'ปัญหาเกี่ยวกับออเดอร์';

  Future<String?> _uploadImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/orders/upload-image'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    final response = await request.send();
    if (response.statusCode != 200) return null;
    final body = jsonDecode(await response.stream.bytesToString());
    return body['url']?.toString() ??
        body['imageUrl']?.toString() ??
        body['image_url']?.toString();
  }

  Future<void> _sendReport() async {
    if (_isOrderIssue && _orderIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุเลขออเดอร์ก่อนส่งรายงาน')),
      );
      return;
    }
    if (_detailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุรายละเอียดปัญหาก่อนส่ง')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final imageUrls = <String>[];
      for (final image in _selectedImages) {
        final imageUrl = await _uploadImage(image);
        if (imageUrl == null) throw Exception('upload failed');
        imageUrls.add(imageUrl);
      }
      final response = await http.post(
        Uri.parse(ApiConfig.merchantIssueReports(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'issue_type': _selectedIssueType,
          'order_reference': _isOrderIssue
              ? _orderIdController.text.trim()
              : null,
          'details': _detailController.text.trim(),
          'image_url': imageUrls.isEmpty ? null : jsonEncode(imageUrls),
        }),
      );
      if (response.statusCode != 201) throw Exception();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งรายงานปัญหาเรียบร้อยแล้ว')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งรายงานปัญหาไม่สำเร็จ')));
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
          'แจ้งรายงานปัญหา',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'หัวข้อปัญหา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedIssueType,
                  items: _issueTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIssueType = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🟢 บังคับให้ระบุเลขออเดอร์ เมื่อเลือกหัวข้อ "ปัญหาเกี่ยวกับออเดอร์" (เช่น กรณีลูกค้าสั่งเล่น)
            if (_isOrderIssue) ...[
              Row(
                children: const [
                  Text(
                    'เลขออเดอร์ที่ต้องการรายงาน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderIdController,
                decoration: InputDecoration(
                  hintText: 'เช่น #ORD-8822',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF00C7E6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ระบุเลขออเดอร์ทุกครั้งเพื่อให้ทีมงานตรวจสอบและดำเนินการได้ถูกต้อง',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'รายละเอียดปัญหา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'อธิบายรายละเอียดปัญหาที่คุณพบ...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF00C7E6),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'แนบรูปภาพ (ทางเลือก)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._selectedImages.asMap().entries.map((entry) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          entry.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _selectedImages.removeAt(entry.key),
                          ),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.redAccent,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_selectedImages.length < 3)
                  GestureDetector(
                    onTap: () async {
                      final pickedFiles = await ImagePicker().pickMultiImage();
                      if (pickedFiles.isEmpty || !mounted) return;
                      final remaining = 3 - _selectedImages.length;
                      setState(() {
                        _selectedImages.addAll(
                          pickedFiles
                              .take(remaining)
                              .map((file) => File(file.path)),
                        );
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7E6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                onPressed: _isSending ? null : _sendReport,
                child: Text(
                  _isSending ? 'กำลังส่ง...' : 'ส่งรายงานปัญหา',
                  style: const TextStyle(
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
    );
  }
}

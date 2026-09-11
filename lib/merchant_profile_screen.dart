import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';
import 'edit_merchant_profile_screen.dart';
import 'merchant_login_screen.dart';
import 'merchant_settings.dart';
import 'merchant_help.dart';

class MerchantProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? merchantData;

  const MerchantProfileScreen({super.key, this.merchantData});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  // ข้อมูลร้านค้าและช่องทางติดต่อที่สามารถแก้ไขได้ (แก้ไขผ่านหน้า "แก้ไขโปรไฟล์" เท่านั้น)
  String _shopName = 'ร้านลูกชิ้น';
  String _storePhone = '';
  String _email = 'somchai@mail.com';
  String _merchantType = 'ร้านอาหารสตรีทฟู้ด';

  // 🟢 เบอร์ติดต่อร้าน และช่องทางติดต่ออื่น (Line, Facebook) แก้ไขผ่านหน้า "แก้ไขโปรไฟล์" เช่นกัน
  String _lineId = '';
  String _facebook = '';

  @override
  void initState() {
    super.initState();
    final merchant = widget.merchantData;
    if (merchant != null) {
      _shopName = merchant['name']?.toString() ?? _shopName;
      _storePhone = merchant['store_phone']?.toString() ?? _storePhone;
      _email = merchant['email']?.toString() ?? _email;
      _merchantType = merchant['type']?.toString() ?? _merchantType;
      _lineId = merchant['line_id']?.toString() ?? _lineId;
      _facebook = merchant['facebook_url']?.toString() ?? _facebook;
    }
    _fetchMerchantProfile();
  }

  Future<void> _fetchMerchantProfile() async {
    final merchantId = widget.merchantData?['id'];
    if (merchantId == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantProfile(merchantId)),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      if (data['success'] != true || data['merchant'] == null || !mounted) {
        return;
      }

      final merchant = Map<String, dynamic>.from(data['merchant']);
      setState(() {
        _shopName = merchant['name']?.toString() ?? _shopName;
        _storePhone = merchant['store_phone']?.toString() ?? _storePhone;
        _email = merchant['email']?.toString() ?? _email;
        _merchantType = merchant['type']?.toString() ?? _merchantType;
        _lineId = merchant['line_id']?.toString() ?? _lineId;
        _facebook = merchant['facebook_url']?.toString() ?? _facebook;
      });
    } catch (error) {
      debugPrint('Error fetching merchant profile: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ==========================================
              // ส่วน Header ด้านบน (รูปโปรไฟล์ และชื่อร้าน) — ปรับให้ตรงตามภาพตัวอย่างที่ได้รับ
              // ==========================================
              const SizedBox(height: 24),
              const Text(
                'โปรไฟล์ของฉัน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1A30),
                ),
              ),
              const SizedBox(height: 24),

              // 🟢 ปรับเลย์เอาต์ใหม่: รูปโปรไฟล์อยู่ด้านซ้าย ชื่อ/เบอร์โทร/อีเมล อยู่ด้านขวา ตามตัวอย่างภาพ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🟢 รูปโปรไฟล์เป็นไอคอนคนว่าง (placeholder) แทนรูปคนจริง — ไม่มีปุ่มเพิ่ม/เปลี่ยนรูปตามที่ร้านค้าต้องการ
                    Container(
                      width: 90,
                      height: 90,
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
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // ชื่อร้าน, เบอร์โทร, อีเมล
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _shopName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1A30),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _storePhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🟢 ปุ่ม "แก้ไขโปรไฟล์" ทรงแคปซูล ตามตัวอย่างภาพ
              SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7E6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () async {
                    // ส่งค่าข้อมูลเดิมไปที่หน้าแก้ไข
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMerchantProfileScreen(
                          merchantId: widget.merchantData?['id'],
                          initialName: _shopName,
                          initialEmail: _email,
                          initialPhone: _storePhone,
                          initialType: _merchantType,
                          // 🟢 ส่งค่าเดิมของ เบอร์ติดต่อร้าน และช่องทางติดต่ออื่นไปด้วย
                          initialLineId: _lineId,
                          initialFacebook: _facebook,
                        ),
                      ),
                    );

                    // รับค่าที่อัปเดตกลับมาจาก EditMerchantProfileScreen
                    if (result != null && result is Map) {
                      setState(() {
                        if (result['name'] != null) _shopName = result['name'];
                        if (result['email'] != null) _email = result['email'];
                        if (result['storePhone'] != null)
                          _storePhone = result['storePhone'];
                        if (result['type'] != null)
                          _merchantType = result['type'];
                        // 🟢 รับค่าที่อัปเดตของ เบอร์ติดต่อร้าน และช่องทางติดต่ออื่นกลับมา
                        if (result['lineId'] != null)
                          _lineId = result['lineId'];
                        if (result['facebook'] != null)
                          _facebook = result['facebook'];
                      });
                    }
                  },
                  child: const Text(
                    'แก้ไขโปรไฟล์',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 28,
              ), // 🟢 เพิ่มระยะห่างระหว่างปุ่ม "แก้ไขโปรไฟล์" กับการ์ดตั้งค่าด้านล่าง
              // ==========================================
              // รายละเอียดข้อมูลร้านค้า
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // รายการเมนู: ตั้งค่าการแจ้งเตือน & บัญชี, ติดต่อช่วยเหลือ
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 🟢 ย้าย "ผู้ติดตามร้านค้า" ขึ้นมาก่อนการตั้งค่า ตามที่ร้านค้าขอ
                          _buildMenuTile(
                            icon: Icons.people_outline,
                            title: 'ผู้ติดตามร้านค้า',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MerchantFollowersScreen(
                                    merchantId: widget.merchantData?['id'],
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          // 🟢 ย้ายการตั้งค่ามาไว้ในหน้าโปรไฟล์ ใช้เป็นตั้งค่าการแจ้งเตือน & บัญชี (รวมเปลี่ยนรหัสผ่าน)
                          _buildMenuTile(
                            icon: Icons.settings_outlined,
                            title: 'ตั้งค่าการแจ้งเตือน & บัญชี',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MerchantSettings(
                                    merchantId: widget.merchantData?['id'],
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          // 🟢 เพิ่มทางลัดไปหน้าช่วยเหลือและสนับสนุนไว้ในหน้าโปรไฟล์
                          _buildMenuTile(
                            icon: Icons.headset_mic_outlined,
                            title: 'ติดต่อช่วยเหลือ',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MerchantHelp(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          // 🟢 ย้ายปุ่ม "ออกจากระบบ" เข้ามาเป็นรายการเมนูในการ์ดเดียวกัน (ตามรูปแบบที่ขอ)
                          _buildMenuTile(
                            icon: Icons.logout,
                            title: 'ออกจากระบบ',
                            color: Colors.red,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text('ออกจากระบบ'),
                                  content: const Text(
                                    'คุณต้องการออกจากระบบร้านค้าใช่หรือไม่?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'ยกเลิก',
                                        style: TextStyle(color: Colors.black45),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MerchantLoginScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      child: const Text(
                                        'ออกจากระบบ',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างปุ่มเมนู
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? const Color(0xFF0B1A30), size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? const Color(0xFF0B1A30),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// =======================================================================
// 🟢 หน้าดูผู้ติดตามร้านค้า (MerchantFollowersScreen)
// =======================================================================
class MerchantFollowersScreen extends StatefulWidget {
  final dynamic merchantId;

  const MerchantFollowersScreen({super.key, required this.merchantId});

  @override
  State<MerchantFollowersScreen> createState() =>
      _MerchantFollowersScreenState();
}

class _MerchantFollowersScreenState extends State<MerchantFollowersScreen> {
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    if (widget.merchantId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่พบรหัสร้านค้า';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantFollowers(widget.merchantId)),
      );
      final body = jsonDecode(response.body);

      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'โหลดผู้ติดตามไม่สำเร็จ');
      }

      if (!mounted) return;
      setState(() {
        _followers = List<Map<String, dynamic>>.from(
          (body['data'] as List? ?? []).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'โหลดรายชื่อผู้ติดตามไม่สำเร็จ';
      });
      debugPrint('Error fetching merchant followers: $error');
    }
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
          'ผู้ติดตามร้านค้า',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7E6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Color(0xFF00C7E6),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_followers.length} คน',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF0B1A30),
                      ),
                    ),
                    const Text(
                      'กำลังติดตามร้านค้าของคุณ',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : _followers.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีผู้ติดตามร้านค้า',
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _followers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final follower = _followers[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(
                                0xFF00C7E6,
                              ).withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF00C7E6),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    follower['name_surname']?.toString() ??
                                        follower['username']?.toString() ??
                                        'ไม่ระบุชื่อ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (follower['email'] != null)
                                    Text(
                                      follower['email'].toString(),
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

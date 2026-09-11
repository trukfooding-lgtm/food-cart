import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';
import 'merchant_map.dart';
import 'merchant_loyalty.dart';
import 'merchant_reviews.dart';
import 'merchant_report.dart';
import 'merchant_status.dart';
import 'merchant_password.dart';
import 'merchant_prep_time.dart';
import 'merchant_hours.dart';
import 'merchant_login_screen.dart';
import 'merchant_bank_accounts.dart';

// =======================================================================
// หน้าตั้งค่าร้านค้า (MerchantSettings)
// =======================================================================
class MerchantSettings extends StatefulWidget {
  final dynamic merchantId;

  const MerchantSettings({super.key, required this.merchantId});

  @override
  State<MerchantSettings> createState() => _MerchantSettingsState();
}

class _MerchantSettingsState extends State<MerchantSettings> {
  bool _orderNotification = true;
  bool _autoHideMenu = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadPrepTime();
    _loadOperatingHours();
    _loadStoreStatus();
  }

  Future<void> _loadPrepTime() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantPrepTime(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }

      final totalMinutes = int.tryParse(body['prepMinutes'].toString()) ?? 15;
      setState(() {
        _prepTimeDisplay = totalMinutes >= 60
            ? '${totalMinutes ~/ 60} ชม. ${totalMinutes % 60} นาที'
            : '$totalMinutes นาที';
      });
    } catch (error) {
      debugPrint('Error loading merchant prep time in settings: $error');
    }
  }

  Future<void> _loadOperatingHours() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantHours(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      final hours = body['hours'];
      if (response.statusCode != 200 || hours == null || !mounted) return;

      final openTime = hours['open_time'].toString().substring(0, 5);
      final closeTime = hours['close_time'].toString().substring(0, 5);
      final openEveryday =
          hours['open_everyday'] == 1 || hours['open_everyday'] == true;
      final days = hours['selected_days']?.toString() ?? '';
      setState(() {
        _operatingHoursDisplay = openEveryday
            ? '$openTime - $closeTime (ทุกวัน)'
            : '$openTime - $closeTime ($days)';
      });
    } catch (error) {
      debugPrint('Error loading merchant hours in settings: $error');
    }
  }

  Future<void> _loadStoreStatus() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantStatus(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }
      setState(() {
        _storeStatusDisplay = body['status']?.toString() ?? 'ปิดร้าน';
      });
    } catch (error) {
      debugPrint('Error loading merchant status in settings: $error');
    }
  }

  Future<void> _loadPreferences() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantPreferences(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true || !mounted) {
        return;
      }
      final preferences = body['preferences'];
      setState(() {
        _orderNotification =
            preferences['order_notification'] == 1 ||
            preferences['order_notification'] == true;
        _autoHideMenu =
            preferences['auto_hide_menu'] == 1 ||
            preferences['auto_hide_menu'] == true;
      });
    } catch (error) {
      debugPrint('Error loading merchant preferences: $error');
    }
  }

  Future<void> _savePreferences() async {
    if (widget.merchantId == null) return;
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.merchantPreferences(widget.merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_notification': _orderNotification,
          'auto_hide_menu': _autoHideMenu,
        }),
      );
      if (response.statusCode != 200) throw Exception('save failed');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการตั้งค่าไม่สำเร็จ')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext dialogContext) async {
    if (widget.merchantId == null || _isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.merchantProfile(widget.merchantId)),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(dialogContext);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MerchantLoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ไม่สามารถลบบัญชีได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // 🟢 ตัวแปรสำหรับแสดงค่าในหน้าตั้งค่าหลังจากกลับมาจากหน้าแก้ไข
  String _prepTimeDisplay = '15 นาที';
  String _operatingHoursDisplay = '08:00 - 18:00 (ทุกวัน)';
  String _storeStatusDisplay =
      'เปิดร้าน'; // 🟢 เก็บสถานะร้านปัจจุบัน แสดงผลหลังกลับจากหน้าเลือกสถานะ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1E293B),
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'การตั้งค่าระบบร้านค้า',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 32),

              // 🟢 เพิ่มส่วน "บัญชีและความปลอดภัย" พร้อมเมนูเปลี่ยนรหัสผ่าน
              const Text(
                'บัญชีและความปลอดภัย',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                children: [
                  _buildListTile(
                    icon: Icons.lock_outline,
                    title: 'เปลี่ยนรหัสผ่าน',
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MerchantPassword(merchantId: widget.merchantId),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.account_balance_outlined,
                    title: 'บัญชีรับเงิน / ธนาคาร',
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MerchantBankAccounts(
                            merchantId: widget.merchantId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'การดำเนินงานร้าน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                children: [
                  // 🟢 ปุ่มไปหน้าตั้งเวลาเตรียมสินค้า
                  _buildListTile(
                    icon: Icons.timer_outlined,
                    title: 'เวลาเตรียมอาหาร',
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _prepTimeDisplay,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MerchantPrepTime(merchantId: widget.merchantId),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _prepTimeDisplay = result;
                        });
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.storefront_outlined,
                    title: 'สถานะร้าน',
                    subtitle: _storeStatusDisplay,
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MerchantStatus(
                            merchantId: widget.merchantId,
                            initialStatus: _storeStatusDisplay,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _storeStatusDisplay = result;
                        });
                      }
                    },
                  ),
                  _buildDivider(),
                  // 🟢 ปุ่มไปหน้าแก้ไขเวลาทำการ
                  _buildListTile(
                    icon: Icons.access_time,
                    title: 'เวลาทำการ',
                    subtitle: _operatingHoursDisplay,
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MerchantHours(merchantId: widget.merchantId),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _operatingHoursDisplay = result;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'การตั้งค่าออเดอร์',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                children: [
                  _buildListTile(
                    icon: Icons.notifications_none,
                    title: 'แจ้งเตือนออเดอร์',
                    trailingWidget: Switch.adaptive(
                      value: _orderNotification,
                      activeColor: const Color(0xFF00C7E6),
                      onChanged: (val) {
                        setState(() => _orderNotification = val);
                        _savePreferences();
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.visibility_off_outlined,
                    title: 'ซ่อนเมนูที่หมดอัตโนมัติ',
                    trailingWidget: Switch.adaptive(
                      value: _autoHideMenu,
                      activeColor: const Color(0xFF00C7E6),
                      onChanged: (val) {
                        setState(() => _autoHideMenu = val);
                        _savePreferences();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'ที่ตั้งและแผนที่',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                children: [
                  _buildListTile(
                    icon: Icons.location_on_outlined,
                    title: 'ตำแหน่งจุดขาย (Selling\nLocation)',
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    // 🟢 กดเข้าไปหน้าตำแหน่งจุดขาย ซึ่งมีปุ่มลิงก์ไปยัง Google Maps ภายนอก
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantMap(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🟢 ย้าย แต้มสะสม รีวิวลูกค้า แจ้งปัญหา มาไว้ในการตั้งค่าเป็นรูปแบบเดียวกับการตั้งค่าอื่นๆ
              const Text(
                'เมนูเพิ่มเติม',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                children: [
                  _buildListTile(
                    icon: Icons.card_giftcard,
                    title: 'แต้มสะสม',
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MerchantLoyalty(merchantId: widget.merchantId),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.star_outline_rounded,
                    title: 'รีวิวจากลูกค้า',
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MerchantReviews(merchantId: widget.merchantId),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.report_problem_outlined,
                    title: 'แจ้งปัญหา',
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MerchantReport(merchantId: widget.merchantId),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  // 🟢 ย้าย "ลบบัญชี" เข้ามาเป็นรายการในการ์ด สไตล์เดียวกับ "ออกจากระบบ" ในหน้าโปรไฟล์
                  _buildListTile(
                    icon: Icons.delete_outline,
                    title: 'ลบบัญชี',
                    color: const Color(0xFFEF4444),
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'ลบบัญชี',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            'คุณแน่ใจหรือไม่ว่าต้องการยกเลิกและลบบัญชีนี้? ข้อมูลทั้งหมดของคุณจะสูญหาย การกระทำนี้ไม่สามารถกู้คืนได้',
                          ),
                          actions: [
                            TextButton(
                              onPressed: _isDeleting
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text(
                                'ยกเลิก',
                                style: TextStyle(color: Colors.black45),
                              ),
                            ),
                            TextButton(
                              onPressed: _isDeleting
                                  ? null
                                  : () => _deleteAccount(dialogContext),
                              child: const Text(
                                'ยืนยันการลบ',
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // 🟢 เพิ่ม onTap เพื่อให้กดไปหน้าอื่นได้
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailingWidget,
    VoidCallback? onTap,
    Color? color, // 🟢 เพิ่มสีสำหรับรายการสีแดงอย่าง "ลบบัญชี"
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (color ?? Colors.grey).withOpacity(0.2),
                ),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF1E293B),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: color ?? const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 64.0, right: 16.0),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
    );
  }
}

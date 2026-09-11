import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.config.dart';

// ============================================================
// NOTIFICATION SCREEN (หน้าการแจ้งเตือน)
// ============================================================
class NotificationScreen extends StatefulWidget {
  final String customerId;
  const NotificationScreen({super.key, this.customerId = '1'});

  // เก็บแจ้งเตือนที่ได้รับสดๆ บนเครื่อง
  static final List<Map<String, dynamic>> localReceivedNotifications = [];

  static void addLocalNotification({required String title, required String sub}) {
    localReceivedNotifications.removeWhere((item) => item['title'] == title && item['sub'] == sub);
    localReceivedNotifications.insert(0, {
      'title': title,
      'sub': sub,
      'time': 'เมื่อสักครู่',
      'icon': Icons.notifications_active_outlined,
      'color': const Color(0xFF00C7E6),
      'unread': true,
    });
  }

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> apiList = [];
    try {
      final url = Uri.parse('${ApiConfig.getNotifications}/${widget.customerId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] is List) {
          final List list = resData['data'];
          apiList = list.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'title': item['title'] ?? 'การแจ้งเตือน',
              'sub': item['body'] ?? '',
              'time': _formatTimestamp(item['created_at']),
              'icon': _getIconForTitle(item['title'] ?? ''),
              'color': _getColorForTitle(item['title'] ?? ''),
              'unread': item['is_read'] == 0 || item['is_read'] == false,
            };
          }).toList();
        }
      }
    } catch (e) {
      print('⚠️ ไม่สามารถดึงแจ้งเตือนจาก Backend: $e');
    }

    setState(() {
      _notifications = [
        ...NotificationScreen.localReceivedNotifications,
        ...apiList,
      ];
      _isLoading = false;
    });
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return 'เมื่อสักครู่';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'เมื่อสักครู่';
      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return 'เมื่อสักครู่';
    }
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('เสร็จ') || title.contains('สำเร็จ') || title.contains('พร้อมรับ')) {
      return Icons.check_circle_outline;
    }
    if (title.contains('ยกเลิก')) {
      return Icons.cancel_outlined;
    }
    if (title.contains('ปรุง') || title.contains('รับออเดอร์')) {
      return Icons.restaurant_outlined;
    }
    return Icons.notifications_active_outlined;
  }

  Color _getColorForTitle(String title) {
    if (title.contains('เสร็จ') || title.contains('สำเร็จ') || title.contains('พร้อมรับ')) {
      return Colors.green;
    }
    if (title.contains('ยกเลิก')) {
      return Colors.redAccent;
    }
    if (title.contains('ปรุง') || title.contains('รับออเดอร์')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF00C7E6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('การแจ้งเตือน', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6)))
          : RefreshIndicator(
              color: const Color(0xFF00C7E6),
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? const Center(child: Text('ไม่มีการแจ้งเตือน', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
          final unread = n['unread'] == true;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationDetailScreen(notification: n)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unread ? Colors.white : const Color(0xFFFAFCFF),
                borderRadius: BorderRadius.circular(16),
                border: unread ? Border.all(color: const Color(0xFF00C7E6).withOpacity(0.3), width: 1.5) : Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: (n['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(n['title'] as String, style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.w600, fontSize: 14, color: const Color(0xFF0B1A30)))),
                            if (unread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(n['sub'] as String, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4)),
                        const SizedBox(height: 8),
                        Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
}

// ============================================================
// NOTIFICATION DETAIL SCREEN (รายละเอียดการแจ้งเตือน)
// ============================================================
class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String;
    final sub = notification['sub'] as String;
    final time = notification['time'] as String;
    final icon = notification['icon'] as IconData;
    final color = notification['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('รายละเอียดการแจ้งเตือน', style: TextStyle(color: Color(0xFF0B1A30), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0B1A30))),
                            const SizedBox(height: 4),
                            Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),
                  Text(sub, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.6)),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'นี่คือข้อความอัตโนมัติ',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
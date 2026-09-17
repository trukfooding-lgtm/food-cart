import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.config.dart';
import 'merchant_profile_screen.dart';
import 'merchant_reviews.dart';

class NotificationPage extends StatefulWidget {
  final dynamic merchantId;
  final VoidCallback onGoToOrders;

  const NotificationPage({
    super.key,
    required this.merchantId,
    required this.onGoToOrders,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.merchantNotifications(widget.merchantId)),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true)
        throw Exception();
      if (!mounted) return;
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(
          (body['data'] as List).map((item) => Map<String, dynamic>.from(item)),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('ยังไม่มีการแจ้งเตือน'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final type = notification['source_type']?.toString();
                final isOrderNotification = type == 'order' ||
                    type == 'order_cancelled' ||
                    type == 'order_completed';
                final isCancelledOrder = type == 'order_cancelled';
                final isCompletedOrder = type == 'order_completed';
                final icon = isCancelledOrder
                    ? Icons.cancel_outlined
                    : isCompletedOrder
                    ? Icons.check_circle_outline
                    : type == 'order'
                    ? Icons.receipt_long
                    : type == 'review'
                    ? Icons.star
                    : Icons.favorite;
                final color = isCancelledOrder
                    ? const Color(0xFFEF4444)
                    : isCompletedOrder
                    ? const Color(0xFF10B981)
                    : type == 'order'
                    ? const Color(0xFF00C7E6)
                    : type == 'review'
                    ? Colors.amber
                    : const Color(0xFFEC4899);
                return GestureDetector(
                  onTap: () {
                    if (isOrderNotification) {
                      widget.onGoToOrders();
                    } else if (type == 'follower') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MerchantFollowersScreen(
                            merchantId: widget.merchantId,
                          ),
                        ),
                      );
                    } else if (type == 'review') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MerchantReviews(merchantId: widget.merchantId),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['title']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0B1A30),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['message']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notification['event_at']
                                        ?.toString()
                                        .replaceFirst('T', ' ')
                                        .split('.')
                                        .first ??
                                    '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api.config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../merchant_home_screen.dart';
import '../notification_screen.dart';

// ฟังก์ชันรับข้อความตอนที่ปิดแอปไปแล้ว (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 ได้รับแจ้งเตือน (Background): ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _merchantChannel =
      AndroidNotificationChannel(
        'merchant_notifications',
        'การแจ้งเตือนร้านค้า',
        description: 'การแจ้งเตือนออเดอร์และกิจกรรมของร้านค้า',
        importance: Importance.high,
      );
  static String? _activeRole;
  static String? _activeUserId;

  Future<void> initialize() async {
    // 1. ขออนุญาตส่งแจ้งเตือน (สำหรับ iOS และ Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ อนุญาตให้ส่งแจ้งเตือนแล้ว');
    }

    // 2. ตรวจสอบ Token ของเครื่อง โดยจะผูกกับบัญชีจริงหลังเข้าสู่ระบบ
    try {
      // สำหรับ iOS บางทีต้องรอ APNS Token ก่อน
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Future.delayed(const Duration(seconds: 1));
      }
      String? token = await _fcm.getToken();
      debugPrint("🔑 FCM Token: $token");
    } catch (e) {
      debugPrint("⚠️ ดึง Token ไม่สำเร็จ (มักเกิดใน iOS Simulator): $e");
    }

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _initializeMerchantLocalNotifications();
    }

    _fcm.onTokenRefresh.listen((token) {
      final role = _activeRole;
      final userId = _activeUserId;
      if (role == 'merchant' && userId != null) {
        _sendMerchantToken(token, userId);
      } else if (role == 'customer' && userId != null) {
        sendTokenToBackend(token, customerId: userId);
      }
    });

    // 3. จัดการตอนที่แอปเปิดใช้งานอยู่ (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '🔔 ได้รับแจ้งเตือน (Foreground): ${message.notification?.title}',
      );
      if (_isMerchantMessage(message)) {
        _showMerchantForegroundNotification(message);
        return;
      }
      if (message.notification != null) {
        NotificationScreen.addLocalNotification(
          title: message.notification!.title ?? 'การแจ้งเตือนใหม่',
          sub: message.notification!.body ?? '',
        );
      }
    });

    // 4. จัดการตอนผู้ใช้คลิกเปิดจากการแจ้งเตือน (ขณะแอปอยู่ Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 ผู้ใช้กดเปิดแจ้งเตือน: ${message.notification?.title}');
      if (_isMerchantMessage(message)) {
        _openMerchantHome(message);
        return;
      }
      if (message.notification != null) {
        NotificationScreen.addLocalNotification(
          title: message.notification!.title ?? 'การแจ้งเตือนใหม่',
          sub: message.notification!.body ?? '',
        );
      }
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    });

    // 5. จัดการกรณีแอปปิดสนิท (Terminated) แล้วผู้ใช้คลิกแจ้งเตือนเพื่อเปิดแอป
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '📲 เปิดแอปจากแจ้งเตือน (Terminated): ${initialMessage.notification?.title}',
      );
      if (_isMerchantMessage(initialMessage)) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _openMerchantHome(initialMessage);
        });
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        return;
      }
      if (initialMessage.notification != null) {
        NotificationScreen.addLocalNotification(
          title: initialMessage.notification!.title ?? 'การแจ้งเตือนใหม่',
          sub: initialMessage.notification!.body ?? '',
        );
      }
      Future.delayed(const Duration(milliseconds: 1000), () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
      });
    }

    // 6. ลงทะเบียนรับข้อความตอนแอปปิดไปแล้ว
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static bool _isMerchantMessage(RemoteMessage message) {
    return message.data['recipient_type'] == 'merchant';
  }

  static void _showMerchantForegroundNotification(RemoteMessage message) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidDetails = AndroidNotificationDetails(
        _merchantChannel.id,
        _merchantChannel.name,
        channelDescription: _merchantChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      final title = message.notification?.title ?? 'การแจ้งเตือนร้านค้า';
      final body = message.notification?.body ?? '';
      final sourceId = message.data['source_id']?.toString();
      _localNotifications.show(
        sourceId?.hashCode.abs() ?? DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        NotificationDetails(android: androidDetails),
      );
      return;
    }

    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          '${message.notification?.title ?? 'การแจ้งเตือนร้านค้า'}\n'
          '${message.notification?.body ?? ''}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> _initializeMerchantLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initializationSettings);
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_merchantChannel);
  }

  static void _openMerchantHome(RemoteMessage message) {
    final merchantId = message.data['merchant_id'];
    if (merchantId == null || merchantId.toString().isEmpty) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MerchantHomeScreen(
          merchantData: {
            'id': int.tryParse(merchantId.toString()) ?? merchantId,
          },
        ),
      ),
    );
  }

  static Future<void> registerCustomerToken(String customerId) async {
    _activeRole = 'customer';
    _activeUserId = customerId;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await sendTokenToBackend(token, customerId: customerId);
      }
    } catch (e) {
      debugPrint('⚠️ ลงทะเบียน Token ลูกค้าไม่สำเร็จ: $e');
    }
  }

  static Future<void> registerMerchantToken(String merchantId) async {
    _activeRole = 'merchant';
    _activeUserId = merchantId;

    try {
      // ขอสิทธิ์แสดงแจ้งเตือนในถาดระบบเฉพาะตอนที่ผู้ใช้เข้าสู่ระบบร้านค้า
      // เพื่อไม่เปลี่ยนพฤติกรรมการแจ้งเตือนของฝั่งลูกค้า
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.requestNotificationsPermission();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendMerchantToken(token, merchantId);
      }
    } catch (e) {
      debugPrint('⚠️ ลงทะเบียน Token ร้านค้าไม่สำเร็จ: $e');
    }
  }

  // ส่ง FCM Token ไปบันทึกในฐานข้อมูล Backend
  static Future<void> sendTokenToBackend(
    String token, {
    String customerId = '1',
  }) async {
    try {
      final url = Uri.parse(ApiConfig.saveFcmToken);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customer_id': customerId, 'fcm_token': token}),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ ส่ง FCM Token ไปบันทึกที่ Backend สำเร็จ');
      }
    } catch (e) {
      debugPrint('⚠️ ส่ง FCM Token ไป Backend ไม่สำเร็จ: $e');
    }
  }

  static Future<void> _sendMerchantToken(
    String token,
    String merchantId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.merchantFcmToken(merchantId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ ส่ง FCM Token ร้านค้าไปบันทึกที่ Backend สำเร็จ');
      } else {
        debugPrint(
          '⚠️ Backend ปฏิเสธ FCM Token ร้านค้า: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ ส่ง FCM Token ร้านค้าไป Backend ไม่สำเร็จ: $e');
    }
  }
}

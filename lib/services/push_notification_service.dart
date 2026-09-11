import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api.config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../notification_screen.dart';

// ฟังก์ชันรับข้อความตอนที่ปิดแอปไปแล้ว (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 ได้รับแจ้งเตือน (Background): ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. ขออนุญาตส่งแจ้งเตือน (สำหรับ iOS และ Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ อนุญาตให้ส่งแจ้งเตือนแล้ว');
    }

    // 2. ดึง FCM Token ของเครื่องนี้ (ต้องส่งให้ Backend เอายิงแจ้งเตือนมาหา)
    try {
      // สำหรับ iOS บางทีต้องรอ APNS Token ก่อน
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Future.delayed(const Duration(seconds: 1));
      }
      String? token = await _fcm.getToken();
      print("🔑 FCM Token: $token");
      if (token != null) {
        sendTokenToBackend(token);
      }
    } catch (e) {
      print("⚠️ ดึง Token ไม่สำเร็จ (มักเกิดใน iOS Simulator): $e");
    }

    // 3. จัดการตอนที่แอปเปิดใช้งานอยู่ (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 ได้รับแจ้งเตือน (Foreground): ${message.notification?.title}');
      if (message.notification != null) {
        NotificationScreen.addLocalNotification(
          title: message.notification!.title ?? 'การแจ้งเตือนใหม่',
          sub: message.notification!.body ?? '',
        );
      }
    });

    // 4. จัดการตอนผู้ใช้คลิกเปิดจากการแจ้งเตือน (ขณะแอปอยู่ Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 ผู้ใช้กดเปิดแจ้งเตือน: ${message.notification?.title}');
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
      print('📲 เปิดแอปจากแจ้งเตือน (Terminated): ${initialMessage.notification?.title}');
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

  // ส่ง FCM Token ไปบันทึกในฐานข้อมูล Backend
  static Future<void> sendTokenToBackend(String token, {String customerId = '1'}) async {
    try {
      final url = Uri.parse(ApiConfig.saveFcmToken);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': customerId,
          'fcm_token': token,
        }),
      );
      if (response.statusCode == 200) {
        print('✅ ส่ง FCM Token ไปบันทึกที่ Backend สำเร็จ');
      }
    } catch (e) {
      print('⚠️ ส่ง FCM Token ไป Backend ไม่สำเร็จ: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'home_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🟢 เริ่มต้นระบบแจ้งเตือน
  await PushNotificationService().initialize();

  runApp(const MyApp());
}     

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Food Cart App',
      theme: ThemeData(
        primaryColor: const Color(0xFF2CBCE2),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      ),
      home: const HomeScreen(),
    );
  }
}

class Merchant {
  String id;
  String name;
  String email;
  String phone;
  String type;

  Merchant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
  });
}

List<Merchant> globalMerchants = [
  Merchant(id: '1', name: 'สมชาย สายกิน', email: 'somchai@mail.com', phone: '0812345678', type: 'ร้านอาหารสตรีทฟู้ด'),
  Merchant(id: '2', name: 'สมศรี มีดี', email: 'somsri@mail.com', phone: '0898765432', type: 'ร้านเครื่องดื่ม / คาเฟ่'),
];
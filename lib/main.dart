import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'screens/main_navigation.dart';

import 'screens/weekly_duel_table.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart'; // 💡 引入通知服務

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 💡 2. 初始化台灣時間每日定時通知 (09:00 & 22:00)
  await NotificationService().initNotification();

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '雙人自律對決看板',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8F9FA),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF2D3436),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '正在安全連線中...',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3436),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigationScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
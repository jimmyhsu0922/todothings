import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'screens/main_navigation.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 💡 1. 設置防白屏全域救援 UI (當 Flutter 渲染崩潰時跳出恢復按鈕)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: const Color(0xFFFFF5F5),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF7675), size: 60),
              const SizedBox(height: 16),
              const Text(
                '系統暫時連線異常',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A3E3D)),
              ),
              const SizedBox(height: 8),
              const Text(
                '別擔心，點擊下方按鈕即可重新恢復畫面。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A7E7D), fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // 強制重新整理全局
                  runApp(const TodoApp());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('強制重新載入'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 2. 初始化 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase 初始化異常: $e");
  }

  // 💡 3. 安全初始化每日定時通知（包裹 try-catch 確保不影響啟動）
  try {
    await NotificationService().initNotification();
  } catch (e) {
    print("通知服務初始化失敗（已捕獲防崩潰）: $e");
  }

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
          // 處理 Stream 連線異常，防止卡死
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('連線發生錯誤，請重新登入'),
                    ElevatedButton(
                      onPressed: () => AuthService().signOut(),
                      child: const Text('返回登入頁'),
                    ),
                  ],
                ),
              ),
            );
          }

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
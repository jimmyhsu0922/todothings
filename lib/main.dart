import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. 引入 Firebase 核心
import 'services/firebase_options.dart';                  // 2. 引入手動建好的設定檔
import 'screens/main_navigation.dart';           // 引入主導覽列控制檔案   

// 🎯 統一使用相對路徑，徹底解決類型打架與重複引入的問題
import 'screens/weekly_duel_table.dart';                      // 認識登入畫面
import 'services/auth_service.dart';                      // 認識驗證服務
import 'screens/login_screen.dart';   

void main() async {
  // 3. 確保 Flutter 元件都有綁定好（非同步執行必加）
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 4. 正式啟動雲端連線！
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      
      // 🎯 使用 StreamBuilder 自動判斷登入狀態分流
      home: StreamBuilder(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          // ✨【全域防呆遮罩】：不論登入、登出還是初次檢查狀態，只要狀態是在 waiting，就啟動頂層鎖定
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
          
          // ✨【完美分流一】：已登入成功，優雅地引入包含底部導覽列的主畫面
          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigationScreen(); 
          }
          
          // ✨【完美分流二】：未登入狀態，精準攔截並返回登入介面，確保權限安全
          return const LoginScreen();
        },
      ),
    );
  }
}
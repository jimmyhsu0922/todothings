import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. 引入 Firebase 核心
import 'firebase_options.dart';                  // 2. 引入你手動建好的設定檔
import 'widgets/main_navigation.dart';           // 📌 修正：引入新的主導覽列控制檔案

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
      // 📌 核心修正：將 home 改為 MainNavigationScreen，讓工具列順利跑出來！
      home: const MainNavigationScreen(), 
    );
  }
}
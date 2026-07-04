import 'package:flutter/material.dart';
import 'duel_table.dart';
import 'history_view.dart';
import 'update_checker.dart'; // 📌 成功引入你寫好的高質感更新檢查器

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

// 📌 修正點：將原本拆開的 State 合併回正規的命名結構，徹底解決 mixin 報錯
class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const WeeklyDuelTable(), const HistoryView()];

  @override
  void initState() {
    super.initState();
    
    // 📌 讓 App 一進入主畫面，就在背景自動且優雅地向 Firebase 比對版本
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkVersion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2D3436), // 深色灰，展現內斂質感
          unselectedItemColor: const Color(0xFFB2BEC3),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined, size: 20), label: '本週對決'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined, size: 20), label: '歷史紀錄'),
          ],
        ),
      ),
    );
  }
}
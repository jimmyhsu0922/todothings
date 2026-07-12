import 'package:flutter/material.dart';
import 'package:todothings/widgets/update_checker.dart';
import 'weekly_duel_table.dart';
import 'history_view.dart';



class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // 這裡的 WeeklyDuelTable() 就會成功讀取新版了！
  final List<Widget> _pages = [const WeeklyDuelTable(), const HistoryView()];

  @override
  void initState() {
    super.initState();
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
          selectedItemColor: const Color(0xFF2D3436), 
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
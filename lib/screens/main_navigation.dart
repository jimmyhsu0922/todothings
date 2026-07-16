import 'package:flutter/material.dart';
import 'package:todothings/widgets/update_checker.dart'; //
import 'weekly_duel_table.dart'; //
import 'history_view.dart'; //
import '../faith/faith_growth_view.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; //
  bool _showFaithTab = true; // 🎯 核心控制：是否顯示信仰專區的分頁

  @override
  void initState() {
    super.initState(); //
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkVersion(context); //
    });
  }

  // 🎯 動態計算當前開合狀態下的分頁清單
  List<Widget> _getPages() {
    return [
      WeeklyDuelTable(
        showFaithTab: _showFaithTab,
        onFaithTabToggle: (value) {
          setState(() {
            _showFaithTab = value;
            // 如果關閉信仰專區時剛好停留在第三頁，自動跳回第一頁防禦 Bug
            if (!_showFaithTab && _currentIndex == 2) {
              _currentIndex = 0;
            }
          });
        },
      ),
      const HistoryView(),
      if (_showFaithTab) const FaithGrowthView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), //
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)), //
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, //
          onTap: (index) => setState(() => _currentIndex = index), //
          backgroundColor: Colors.white, //
          selectedItemColor: const Color(0xFF2D3436), //
          unselectedItemColor: const Color(0xFFB2BEC3), //
          selectedFontSize: 11, //
          unselectedFontSize: 11, //
          type: BottomNavigationBarType.fixed, //
          elevation: 0, //
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined, size: 20), label: '本週對決'), //
            const BottomNavigationBarItem(icon: Icon(Icons.history_outlined, size: 20), label: '歷史紀錄'), //
            if (_showFaithTab)
              const BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_mosaic_rounded, size: 20),
                label: '信仰成長',
              ),
          ],
        ),
      ),
    );
  }
}
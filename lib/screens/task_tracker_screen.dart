import 'package:flutter/material.dart';

class TaskTrackerScreen extends StatefulWidget {
  final String taskName;
  
  const TaskTrackerScreen({super.key, required this.taskName});

  @override
  State<TaskTrackerScreen> createState() => _TaskTrackerScreenState();
}

class _TaskTrackerScreenState extends State<TaskTrackerScreen> {
  // 7天的打卡狀態：0 = 灰色(未記錄), 1 = 綠色(已完成), 2 = 紅色(未完成)
  List<int> dayStates = List.generate(7, (_) => 0);
  final List<String> weekDays = ["一", "二", "三", "四", "五", "六", "日"];

  void _toggleState(int index) {
    setState(() {
      // 三態按順序循環切換：0 -> 1 -> 2 -> 0
      dayStates[index] = (dayStates[index] + 1) % 3;
    });
  }

  Color _getCircleColor(int state) {
    switch (state) {
      case 1: return const Color(0xFF2ECC71);  // 質感綠（完成）
      case 2: return const Color(0xFFE74C3C);  // 隱性紅（未完成）
      default: return const Color(0xFFDCDDE1); // 輕盈灰（未記錄）
    }
  }

  IconData? _getCircleIcon(int state) {
    switch (state) {
      case 1: return Icons.check_rounded;
      case 2: return Icons.close_rounded;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3436), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('任務進度追蹤', style: TextStyle(color: Color(0xFF2D3436), fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任務名片區塊
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENT TASK', style: TextStyle(color: Color(0xFFB2BEC3), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    widget.taskName,
                    style: const TextStyle(color: Color(0xFF2D3436), fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            
            const Text('本週每日簽到 (點擊圈圈變更狀態)', style: TextStyle(color: Color(0xFF2D3436), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 20),

            // 橫向七天圈圈列
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                return Column(
                  children: [
                    Text(
                      '週${weekDays[index]}',
                      style: const TextStyle(color: Color(0xFF636E72), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _toggleState(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _getCircleColor(dayStates[index]),
                          shape: BoxShape.circle,
                          boxShadow: dayStates[index] != 0 ? [
                            BoxShadow(color: _getCircleColor(dayStates[index]).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))
                          ] : [],
                        ),
                        child: Center(
                          child: Icon(
                            _getCircleIcon(dayStates[index]),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            
            const SizedBox(height: 36),
            
            // 底部顏色小提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF2D3436).withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF636E72)),
                  SizedBox(width: 8),
                  Text('點擊循環狀態：未記錄 ➔ 🟢 已達成 ➔ 🔴 未達成', style: TextStyle(color: Color(0xFF636E72), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
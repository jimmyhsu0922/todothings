import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskTrackerScreen extends StatelessWidget {
  final String taskName;
  final DocumentReference docRef; // 接收來自前面的資料庫路徑
  final int taskIndex;            // 接收這是第幾個任務
  final bool isLeft;              // 接收是左邊（心柔）還是右邊（靖祐）

  const TaskTrackerScreen({
    super.key, 
    required this.taskName,
    required this.docRef,
    required this.taskIndex,
    required this.isLeft,
  });

  final List<String> weekDays = const ["一", "二", "三", "四", "五", "六", "日"];

  // 根據狀態數字回傳對應的質感色系
  Color _getCircleColor(int state) {
    switch (state) {
      case 1: return const Color(0xFF2ECC71);  // 質感綠（完成）
      case 2: return const Color(0xFFE74C3C);  // 隱性紅（未完成）
      default: return const Color(0xFFDCDDE1); // 輕盈灰（未記錄）
    }
  }

  // 根據狀態數字回傳圖示
  IconData? _getCircleIcon(int state) {
    switch (state) {
      case 1: return Icons.check_rounded;
      case 2: return Icons.close_rounded;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 根據是誰的任務，決定資料庫欄位名稱（historyL 或 historyR）
    final String historyKey = isLeft ? 'historyL' : 'historyR';

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(), // 🎧 即時監聽這一週的資料庫變動
      builder: (context, snapshot) {
        // 預設全都是未記錄的 0
        List<int> dayStates = List.generate(7, (_) => 0);
        List<dynamic> allTasks = [];

        // 如果資料庫有撈到資料，就把目前的簽到狀態解包出來
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          allTasks = data['tasks'] ?? [];
          
          if (taskIndex < allTasks.length) {
            final task = allTasks[taskIndex];
            final listFromDb = task[historyKey];
            if (listFromDb != null) {
              // 從 Firestore 讀取出來的 List 轉換成強型別的 List<int>
              dayStates = List<int>.from(listFromDb);
            }
          }
        }

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
                        taskName,
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
                    int currentState = dayStates[index];
                    
                    return Column(
                      children: [
                        Text(
                          '週${weekDays[index]}',
                          style: const TextStyle(color: Color(0xFF636E72), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            if (allTasks.length > taskIndex) {
                              // 1. 在本地計算出點擊後的下一個循環狀態（0 -> 1 -> 2 -> 0）
                              int nextState = (currentState + 1) % 3;
                              dayStates[index] = nextState;
                              
                              // 2. 將修改後的 7 天陣列直接塞回原本的任務地圖中
                              allTasks[taskIndex][historyKey] = dayStates;
                              
                              // 3. 🎯 震撼一擊：一秒同步回 Firebase 雲端資料庫！
                              try {
                                await docRef.update({'tasks': allTasks});
                              } catch (e) {
                                debugPrint("同步簽到狀態失敗: $e");
                              }
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _getCircleColor(currentState),
                              shape: BoxShape.circle,
                              boxShadow: currentState != 0 ? [
                                BoxShadow(
                                  color: _getCircleColor(currentState).withOpacity(0.25), 
                                  blurRadius: 6, 
                                  offset: const Offset(0, 3)
                                )
                              ] : [],
                            ),
                            child: Center(
                              child: Icon(
                                _getCircleIcon(currentState),
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
      },
    );
  }
}
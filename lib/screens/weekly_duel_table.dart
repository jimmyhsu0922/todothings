import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; //[cite: 4]
import 'task_tracker_screen.dart'; //[cite: 4]
import '../models/task_status.dart'; //[cite: 4]
import '../widgets/custom_dialog.dart'; //[cite: 4]
import '../widgets/task_card.dart'; //[cite: 4]
import '../widgets/reward_card.dart'; //[cite: 4]

class WeeklyDuelTable extends StatefulWidget {
  // 🎯 整合修改：接收來自外層 MainNavigationScreen 的狀態與回呼函式
  final bool showFaithTab;
  final ValueChanged<bool> onFaithTabToggle;

  const WeeklyDuelTable({
    super.key,
    required this.showFaithTab,
    required this.onFaithTabToggle,
  });

  @override
  State<WeeklyDuelTable> createState() => _WeeklyDuelTableState();
}

class _WeeklyDuelTableState extends State<WeeklyDuelTable> {
  int currentYear = 2026; //[cite: 4]
  int currentMonth = 7; //[cite: 4]
  int currentWeek = 1; //[cite: 4]

  final String userL = "心柔"; //[cite: 4]
  final String userR = "靖祐"; //[cite: 4]

  @override
  void initState() {
    super.initState(); //[cite: 4]
    final now = DateTime.now(); //[cite: 4]
    currentYear = now.year; //[cite: 4]
    currentMonth = now.month; //[cite: 4]
    currentWeek = ((now.day - 1) / 7).floor() + 1; //[cite: 4]
  }

  String get _weekDocKey => "$currentYear-$currentMonth-$currentWeek"; //[cite: 4]
  DocumentReference get _weekDocRef => FirebaseFirestore.instance.collection('weeks').doc(_weekDocKey); //[cite: 4]

  // 🎯 優化 3：抽取統一的 Firestore 儲存更新方法
  Future<void> _saveTasks(List<dynamic> tasks) async {
    await _weekDocRef.update({'tasks': tasks}); //[cite: 4]
  }

  String _getPreviousWeekKey() {
    int prevWeek = currentWeek - 1; //[cite: 4]
    int prevMonth = currentMonth; //[cite: 4]
    int prevYear = currentYear; //[cite: 4]
    if (prevWeek < 1) { //[cite: 4]
      prevMonth -= 1; //[cite: 4]
      if (prevMonth < 1) { prevMonth = 12; prevYear -= 1; } //[cite: 4]
      prevWeek = 5; //[cite: 4]
    }
    return "$prevYear-$prevMonth-$prevWeek"; //[cite: 4]
  }

  void _changeWeek(int offset) {
    setState(() {
      currentWeek += offset; //[cite: 4]
      while (currentWeek < 1) { //[cite: 4]
        currentMonth -= 1; //[cite: 4]
        if (currentMonth < 1) { currentMonth = 12; currentYear -= 1; } //[cite: 4]
        currentWeek = 5;  //[cite: 4]
      }
      while (currentWeek > 5) { //[cite: 4]
        currentWeek = 1; currentMonth += 1; //[cite: 4]
        if (currentMonth > 12) { currentMonth = 1; currentYear += 1; } //[cite: 4]
      }
    });
  }

  Future<void> _copyFromPreviousWeek() async {
    String prevKey = _getPreviousWeekKey(); //[cite: 4]
    try {
      DocumentSnapshot prevSnapshot = await FirebaseFirestore.instance.collection('weeks').doc(prevKey).get(); //[cite: 4]
      if (!prevSnapshot.exists) return; //[cite: 4]

      final prevData = prevSnapshot.data() as Map<String, dynamic>; //[cite: 4]
      List<dynamic> prevTasks = prevData['tasks'] ?? []; //[cite: 4]
      if (prevTasks.isEmpty) return; //[cite: 4]

      List<Map<String, dynamic>> clonedTasks = prevTasks.map((t) {
        return {
          "taskL": t['taskL'] ?? "", "statusL": 0, "detailL": t['detailL'] ?? "", //[cite: 4]
          "taskR": t['taskR'] ?? "", "statusR": 0, "detailR": t['detailR'] ?? "", //[cite: 4]
        };
      }).toList(); //[cite: 4]

      await _weekDocRef.set({
        'tasks': clonedTasks, //[cite: 4]
        'bannerTitle': "$currentYear 年 $currentMonth 月 第 $currentWeek 週", //[cite: 4]
        'rewardText': prevData['rewardText'] ?? "尚未設定達成獎勵內容", //[cite: 4]
      }, SetOptions(merge: true)); //[cite: 4]
    } catch (e) {
      debugPrint("複製失敗: $e"); //[cite: 4]
    }
  }

  // 🎯 整合修改：全新設計的系統設定 Dialog
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // 確保在 Dialog 內切換開關時，彈窗與底欄都能即時重繪
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF2D3436), size: 22),
                SizedBox(width: 8),
                Text('系統設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顯示信仰專區開關列
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF636E72), size: 20),
                        SizedBox(width: 12),
                        Text('顯示信仰成長專區', style: TextStyle(fontSize: 14, color: Color(0xFF2D3436))),
                      ],
                    ),
                    Switch(
                      value: widget.showFaithTab,
                      activeColor: const Color(0xFF2D3436),
                      activeTrackColor: const Color(0xFFECECEC),
                      inactiveTrackColor: const Color(0xFFF1F2F6),
                      onChanged: (value) {
                        setDialogState(() {}); // 刷新彈窗內部 Switch UI
                        widget.onFaithTabToggle(value); // 觸發外部 Navigation 重新整理底欄
                      },
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFEFEFEF), height: 24),
                
                // 原有的安全登出按鈕
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx); // 先關閉設定 Dialog
                    _handleSignOut(); // 觸發原有的安全鎖死登出
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFFF7675), size: 20),
                        SizedBox(width: 12),
                        Text('安全登出帳號', style: TextStyle(fontSize: 14, color: Color(0xFFFF7675), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('關閉', style: TextStyle(color: Color(0xFFB2BEC3), fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🎯 原有的全畫面鎖死安全登出流程（完全保留）
  Future<void> _handleSignOut() async {
    bool? confirmSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF7675), size: 22),
            SizedBox(width: 8),
            Text('確定要登出嗎？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A3E3D))),
          ],
        ),
        content: const Text(
          '登出後將安全返回迎賓介面。\n下一週也要跟對方一起自律加油喔！🌸',
          style: TextStyle(fontSize: 14, color: Color(0xFF8A7E7D), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFFB2BEC3), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF7675)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('確定登出', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ); //[cite: 4]

    if (confirmSignOut == true) { //[cite: 4]
      if (!mounted) return; //[cite: 4]

      showDialog(
        context: context,
        barrierDismissible: false, //[cite: 4]
        builder: (context) => PopScope(
          canPop: false, //[cite: 4]
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26), //[cite: 4]
              decoration: BoxDecoration(
                color: Colors.white, //[cite: 4]
                borderRadius: BorderRadius.circular(24), //[cite: 4]
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7675).withOpacity(0.08), 
                    blurRadius: 24, 
                    offset: const Offset(0, 8),
                  ) //[cite: 4]
                ]
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7675)),
                      strokeWidth: 3,
                    ),
                  ), //[cite: 4]
                  SizedBox(height: 20), //[cite: 4]
                  Text(
                    '正在安全登出，稍等一下喔...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A3E3D),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                      fontFamily: 'sans-serif',
                    ),
                  ), //[cite: 4]
                ],
              ),
            ),
          ),
        ),
      ); //[cite: 4]

      try {
        await Future.delayed(const Duration(milliseconds: 800)); //[cite: 4]
        await AuthService().signOut(); //[cite: 4]
        if (mounted) {
          Navigator.pop(context); //[cite: 4]
        }
      } catch (e) {
        debugPrint("登出失敗: $e"); //[cite: 4]
        if (mounted) Navigator.pop(context); //[cite: 4]
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _weekDocRef.snapshots(), //[cite: 4]
      builder: (context, snapshot) {
        String bannerTitle = "$currentYear 年 $currentMonth 月 第 $currentWeek 週"; //[cite: 4]
        String rewardText = "尚未設定達成獎勵內容"; //[cite: 4]
        List<dynamic> tasks = []; //[cite: 4]

        if (snapshot.hasData && snapshot.data!.exists) { //[cite: 4]
          final data = snapshot.data!.data() as Map<String, dynamic>; //[cite: 4]
          bannerTitle = data['bannerTitle'] ?? bannerTitle; //[cite: 4]
          rewardText = data['rewardText'] ?? rewardText; //[cite: 4]
          tasks = data['tasks'] ?? []; //[cite: 4]
        }

        List<dynamic> validTasksL = tasks.where((t) => (t['taskL'] as String).isNotEmpty).toList(); //[cite: 4]
        List<dynamic> validTasksR = tasks.where((t) => (t['taskR'] as String).isNotEmpty).toList(); //[cite: 4]

        double rateL = validTasksL.isEmpty ? 0 : validTasksL.where((t) => t['statusL'] == 1).length / validTasksL.length; //[cite: 4]
        double rateR = validTasksR.isEmpty ? 0 : validTasksR.where((t) => t['statusR'] == 1).length / validTasksR.length; //[cite: 4]

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA), //[cite: 4]
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), //[cite: 4]
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(), // 🎯 引入更新為「設定」功能圖標的 Header
                  const SizedBox(height: 14), //[cite: 4]
                  _buildWeekNavigationRow(bannerTitle), //[cite: 4]
                  const SizedBox(height: 24), //[cite: 4]
                  if (tasks.isEmpty) ...[ //[cite: 4]
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _copyFromPreviousWeek, //[cite: 4]
                        icon: const Icon(Icons.copy_all_rounded, size: 16, color: Color(0xFF2D3436)), //[cite: 4]
                        label: const Text("複製前一週的本週任務", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))), //[cite: 4]
                      ),
                    ),
                    const SizedBox(height: 24), //[cite: 4]
                  ],
                  _buildUserTaskBlock(userL, tasks, validTasksL, rateL, true), //[cite: 4]
                  const SizedBox(height: 32), //[cite: 4]
                  _buildUserTaskBlock(userR, tasks, validTasksR, rateR, false), //[cite: 4]
                  const SizedBox(height: 40), //[cite: 4]
                  RewardCard(rewardText: rewardText, onTap: () => _showEditRewardDialog(rewardText)), //[cite: 4]
                  const SizedBox(height: 24), //[cite: 4]
                  _buildAddButton(tasks), //[cite: 4]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎯 整合修改：將原先獨立登出的按鈕，換成「設定」圖標
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("CURRENT PERFORMANCE", style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey.shade500, fontWeight: FontWeight.bold)), //[cite: 4]
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFFB2BEC3)), // 🎯 換成設定小齒輪
          onPressed: () => _showSettingsDialog(), // 🎯 點擊彈出綜合設定清單
        ),
      ],
    );
  }

  Widget _buildWeekNavigationRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () => _changeWeek(-1), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)), //[cite: 4]
        Expanded(
          child: GestureDetector(
            onTap: () => _showEditBannerDialog(title), //[cite: 4]
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))), //[cite: 4]
          ),
        ),
        IconButton(onPressed: () => _changeWeek(1), icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18)), //[cite: 4]
      ],
    );
  }

  Widget _buildUserTaskBlock(String name, List<dynamic> allTasks, List<dynamic> validTasks, double rate, bool isLeft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2D3436))), //[cite: 4]
            Text("${(rate * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 13, color: Colors.grey)), //[cite: 4]
          ],
        ),
        const SizedBox(height: 10), //[cite: 4]
        ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: rate, minHeight: 3, backgroundColor: const Color(0xFFECECEC), color: const Color(0xFF2ECC71))), //[cite: 4]
        const SizedBox(height: 16), //[cite: 4]
        if (validTasks.isEmpty) //[cite: 4]
          const Text("本週尚無安排挑戰任務。", style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)) //[cite: 4]
        else //[cite: 4]
          ...allTasks.asMap().entries.where((e) => (isLeft ? e.value['taskL'] : e.value['taskR']).toString().isNotEmpty).map((e) { //[cite: 4]
            final task = e.value; //[cite: 4]
            final index = e.key; //[cite: 4]
            final taskText = isLeft ? task['taskL'] : task['taskR']; //[cite: 4]
            final taskDetail = isLeft ? (task['detailL'] ?? "") : (task['detailR'] ?? ""); //[cite: 4]
            final currentStatus = TaskStatusExtension.fromInt(isLeft ? task['statusL'] : task['statusR']); //[cite: 4]

            return TaskCard(
              taskText: taskText, //[cite: 4]
              taskDetail: taskDetail, //[cite: 4]
              status: currentStatus, //[cite: 4]
              onStatusToggle: () {
                final nextStatus = currentStatus.next; //[cite: 4]
                if (isLeft) allTasks[index]['statusL'] = nextStatus.value; //[cite: 4]
                else allTasks[index]['statusR'] = nextStatus.value; //[cite: 4]
                _saveTasks(allTasks); //[cite: 4]
              },
              onTextTap: () => _showTaskDetailDialog(taskText, taskDetail), //[cite: 4]
              onProgress: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskTrackerScreen(
                    taskName: taskText, //[cite: 4]
                    docRef: _weekDocRef, //[cite: 4]
                    taskIndex: index,    //[cite: 4]
                    isLeft: isLeft,      //[cite: 4]
                  ),
                ),
              ),
              onEdit: () => _showEditTaskDialog(index, allTasks, isLeft), //[cite: 4]
              onDelete: () {
                allTasks.removeAt(index); //[cite: 4]
                _saveTasks(allTasks); //[cite: 4]
              },
            );
          }),
      ],
    );
  }

  Widget _buildAddButton(List<dynamic> tasks) {
    return OutlinedButton(
      onPressed: () => _showAddTaskRowDialog(tasks), //[cite: 4]
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), side: const BorderSide(color: Color(0xFFDCDCDC), width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), //[cite: 4]
      child: const Text("ADD NEW TASK", style: TextStyle(fontSize: 12, letterSpacing: 1, color: Color(0xFF636E72), fontWeight: FontWeight.bold)), //[cite: 4]
    );
  }

  void _showEditBannerDialog(String current) {
    final c = TextEditingController(text: current); //[cite: 4]
    showCustomPremiumDialog(context: context, title: "修改核心目標", icon: Icons.edit_note_rounded, content: buildDialogTextField(c, label: "本週對決核心主題"), onSave: () async { //[cite: 4]
      await _weekDocRef.set({'bannerTitle': c.text}, SetOptions(merge: true)); //[cite: 4]
      if (mounted) Navigator.pop(context); //[cite: 4]
    });
  }

  void _showEditRewardDialog(String current) {
    final c = TextEditingController(text: current); //[cite: 4]
    showCustomPremiumDialog(context: context, title: "修改本週達標獎勵", icon: Icons.stars_outlined, content: buildDialogTextField(c, label: "約定的懲罰或獎勵內容", maxLines: 2), onSave: () async { //[cite: 4]
      await _weekDocRef.set({'rewardText': c.text}, SetOptions(merge: true)); //[cite: 4]
      if (mounted) Navigator.pop(context); //[cite: 4]
    });
  }

  void _showEditTaskDialog(int index, List<dynamic> all, bool isLeft) {
    final currentTask = all[index]; //[cite: 4]
    final taskController = TextEditingController(text: isLeft ? currentTask['taskL'] : currentTask['taskR']); //[cite: 4]
    final detailController = TextEditingController(text: isLeft ? (currentTask['detailL'] ?? "") : (currentTask['detailR'] ?? "")); //[cite: 4]

    showCustomPremiumDialog(context: context, title: "調整任務與詳情", icon: Icons.tune_rounded, saveLabel: "UPDATE", content: Column(mainAxisSize: MainAxisSize.min, children: [buildDialogTextField(taskController, label: "挑戰"), buildDialogTextField(detailController, label: "任務詳細說明 (選填)", maxLines: 2)]), onSave: () { //[cite: 4]
      if (isLeft) {
        all[index]['taskL'] = taskController.text.trim(); //[cite: 4]
        all[index]['detailL'] = detailController.text.trim(); //[cite: 4]
      } else {
        all[index]['taskR'] = taskController.text.trim(); //[cite: 4]
        all[index]['detailR'] = detailController.text.trim(); //[cite: 4]
      }
      _saveTasks(all); //[cite: 4]
      if (mounted) Navigator.pop(context); //[cite: 4]
    });
  }

  void _showAddTaskRowDialog(List<dynamic> tasks) {
    final l = TextEditingController(); final detailL = TextEditingController(); //[cite: 4]
    final r = TextEditingController(); final detailR = TextEditingController(); //[cite: 4]

    showCustomPremiumDialog(context: context, title: "新增雙人對決任務", icon: Icons.playlist_add_rounded, saveLabel: "ADD", content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [buildDialogTextField(l, label: "$userL 的新挑戰"), buildDialogTextField(detailL, label: "$userL 的詳細說明", maxLines: 2), const SizedBox(height: 16), buildDialogTextField(r, label: "$userR 的新挑戰"), buildDialogTextField(detailR, label: "$userR 的詳細說明", maxLines: 2)])), onSave: () { //[cite: 4]
      if (l.text.trim().isNotEmpty || r.text.trim().isNotEmpty) { //[cite: 4]
        tasks.add({"taskL": l.text.trim(), "statusL": 0, "detailL": detailL.text.trim(), "taskR": r.text.trim(), "statusR": 0, "detailR": detailR.text.trim()}); //[cite: 4]
        _weekDocRef.set({'tasks': tasks}, SetOptions(merge: true)); //[cite: 4]
      }
      if (mounted) Navigator.pop(context); //[cite: 4]
    });
  }

  void _showTaskDetailDialog(String title, String detail) {
    showCustomPremiumDialog(context: context, title: "任務詳細說明", icon: Icons.assignment_outlined, saveLabel: "CLOSE", content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 14), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)), child: Text(detail.trim().isEmpty ? "目前此任務尚未填寫額外的細節說明。" : detail, style: const TextStyle(fontSize: 14, color: Color(0xFF636E72), height: 1.5)))]), onSave: () => Navigator.pop(context)); //[cite: 4]
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // 💡 引入通知服務
import 'task_tracker_screen.dart';
import '../models/task_status.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/task_card.dart';
import '../widgets/reward_card.dart';

class WeeklyDuelTable extends StatefulWidget {
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
  int currentYear = 2026;
  int currentMonth = 7;
  int currentWeek = 1;

  final String userL = "心柔";
  final String userR = "靖祐";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentYear = now.year;
    currentMonth = now.month;
    currentWeek = ((now.day - 1) / 7).floor() + 1;
  }

  String get _weekDocKey => "$currentYear-$currentMonth-$currentWeek";
  DocumentReference get _weekDocRef => FirebaseFirestore.instance.collection('weeks').doc(_weekDocKey);

  Future<void> _saveTasks(List<dynamic> tasks) async {
    await _weekDocRef.update({'tasks': tasks});
  }

  String _getPreviousWeekKey() {
    int prevWeek = currentWeek - 1;
    int prevMonth = currentMonth;
    int prevYear = currentYear;
    if (prevWeek < 1) {
      prevMonth -= 1;
      if (prevMonth < 1) { prevMonth = 12; prevYear -= 1; }
      prevWeek = 5;
    }
    return "$prevYear-$prevMonth-$prevWeek";
  }

  void _changeWeek(int offset) {
    setState(() {
      currentWeek += offset;
      while (currentWeek < 1) {
        currentMonth -= 1;
        if (currentMonth < 1) { currentMonth = 12; currentYear -= 1; }
        currentWeek = 5;
      }
      while (currentWeek > 5) {
        currentWeek = 1; currentMonth += 1;
        if (currentMonth > 12) { currentMonth = 1; currentYear += 1; }
      }
    });
  }

  Future<void> _copyFromPreviousWeek() async {
    String prevKey = _getPreviousWeekKey();
    try {
      DocumentSnapshot prevSnapshot = await FirebaseFirestore.instance.collection('weeks').doc(prevKey).get();
      if (!prevSnapshot.exists) return;

      final prevData = prevSnapshot.data() as Map<String, dynamic>;
      List<dynamic> prevTasks = prevData['tasks'] ?? [];
      if (prevTasks.isEmpty) return;

      List<Map<String, dynamic>> clonedTasks = prevTasks.map((t) {
        return {
          "taskL": t['taskL'] ?? "", "statusL": 0, "detailL": t['detailL'] ?? "",
          "taskR": t['taskR'] ?? "", "statusR": 0, "detailR": t['detailR'] ?? "",
        };
      }).toList();

      await _weekDocRef.set({
        'tasks': clonedTasks,
        'bannerTitle': "$currentYear 年 $currentMonth 月 第 $currentWeek 週",
        'rewardText': prevData['rewardText'] ?? "尚未設定達成獎勵內容",
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("複製失敗: $e");
    }
  }

  // 🎯 全新設計的系統設定 Dialog（含模擬發送測試通知）
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
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
                // 1. 顯示信仰專區開關列
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
                        setDialogState(() {});
                        widget.onFaithTabToggle(value);
                      },
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFEFEFEF), height: 20),

                // 💡 2. 模擬測試通知按鈕
                InkWell(
                  onTap: () async {
                    Navigator.pop(ctx); // 先關閉設定視窗

                    // 發送即時測試通知
                    await NotificationService().showImmediateTestNotification();

                    // 提示使用者
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('已觸發測試通知！請查看手機通知列 🔔'),
                          backgroundColor: const Color(0xFF6C5CE7),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: Color(0xFF6C5CE7), size: 20),
                        SizedBox(width: 12),
                        Text('發送測試通知 (模擬)', style: TextStyle(fontSize: 14, color: Color(0xFF2D3436), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFEFEFEF), height: 20),

                // 3. 安全登出按鈕
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSignOut();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
    );

    if (confirmSignOut == true) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7675).withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
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
                  ),
                  SizedBox(height: 20),
                  Text(
                    '正在安全登出，稍等一下喔...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A3E3D),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await Future.delayed(const Duration(milliseconds: 800));
        await AuthService().signOut();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("登出失敗: $e");
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _weekDocRef.snapshots(),
      builder: (context, snapshot) {
        String bannerTitle = "$currentYear 年 $currentMonth 月 第 $currentWeek 週";
        String rewardText = "尚未設定達成獎勵內容";
        List<dynamic> tasks = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          bannerTitle = data['bannerTitle'] ?? bannerTitle;
          rewardText = data['rewardText'] ?? rewardText;
          tasks = data['tasks'] ?? [];
        }

        List<dynamic> validTasksL = tasks.where((t) => (t['taskL'] as String).isNotEmpty).toList();
        List<dynamic> validTasksR = tasks.where((t) => (t['taskR'] as String).isNotEmpty).toList();

        double rateL = validTasksL.isEmpty ? 0 : validTasksL.where((t) => t['statusL'] == 1).length / validTasksL.length;
        double rateR = validTasksR.isEmpty ? 0 : validTasksR.where((t) => t['statusR'] == 1).length / validTasksR.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(),
                  const SizedBox(height: 14),
                  _buildWeekNavigationRow(bannerTitle),
                  const SizedBox(height: 24),
                  if (tasks.isEmpty) ...[
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _copyFromPreviousWeek,
                        icon: const Icon(Icons.copy_all_rounded, size: 16, color: Color(0xFF2D3436)),
                        label: const Text("複製前一週的本週任務", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildUserTaskBlock(userL, tasks, validTasksL, rateL, true),
                  const SizedBox(height: 32),
                  _buildUserTaskBlock(userR, tasks, validTasksR, rateR, false),
                  const SizedBox(height: 40),
                  RewardCard(rewardText: rewardText, onTap: () => _showEditRewardDialog(rewardText)),
                  const SizedBox(height: 24),
                  _buildAddButton(tasks),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("CURRENT PERFORMANCE", style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFFB2BEC3)),
          onPressed: () => _showSettingsDialog(),
        ),
      ],
    );
  }

  Widget _buildWeekNavigationRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () => _changeWeek(-1), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        Expanded(
          child: GestureDetector(
            onTap: () => _showEditBannerDialog(title),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
          ),
        ),
        IconButton(onPressed: () => _changeWeek(1), icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18)),
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
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2D3436))),
            Text("${(rate * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: rate, minHeight: 3, backgroundColor: const Color(0xFFECECEC), color: const Color(0xFF2ECC71))),
        const SizedBox(height: 16),
        if (validTasks.isEmpty)
          const Text("本週尚無安排挑戰任務。", style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...allTasks.asMap().entries.where((e) => (isLeft ? e.value['taskL'] : e.value['taskR']).toString().isNotEmpty).map((e) {
            final task = e.value;
            final index = e.key;
            final taskText = isLeft ? task['taskL'] : task['taskR'];
            final taskDetail = isLeft ? (task['detailL'] ?? "") : (task['detailR'] ?? "");
            final currentStatus = TaskStatusExtension.fromInt(isLeft ? task['statusL'] : task['statusR']);

            return TaskCard(
              taskText: taskText,
              taskDetail: taskDetail,
              status: currentStatus,
              onStatusToggle: () {
                final nextStatus = currentStatus.next;
                if (isLeft) allTasks[index]['statusL'] = nextStatus.value;
                else allTasks[index]['statusR'] = nextStatus.value;
                _saveTasks(allTasks);
              },
              onTextTap: () => _showTaskDetailDialog(taskText, taskDetail),
              onProgress: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskTrackerScreen(
                    taskName: taskText,
                    docRef: _weekDocRef,
                    taskIndex: index,
                    isLeft: isLeft,
                  ),
                ),
              ),
              onEdit: () => _showEditTaskDialog(index, allTasks, isLeft),
              onDelete: () {
                allTasks.removeAt(index);
                _saveTasks(allTasks);
              },
            );
          }),
      ],
    );
  }

  Widget _buildAddButton(List<dynamic> tasks) {
    return OutlinedButton(
      onPressed: () => _showAddTaskRowDialog(tasks),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), side: const BorderSide(color: Color(0xFFDCDCDC), width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: const Text("ADD NEW TASK", style: TextStyle(fontSize: 12, letterSpacing: 1, color: Color(0xFF636E72), fontWeight: FontWeight.bold)),
    );
  }

  void _showEditBannerDialog(String current) {
    final c = TextEditingController(text: current);
    showCustomPremiumDialog(context: context, title: "修改核心目標", icon: Icons.edit_note_rounded, content: buildDialogTextField(c, label: "本週對決核心主題"), onSave: () async {
      await _weekDocRef.set({'bannerTitle': c.text}, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    });
  }

  void _showEditRewardDialog(String current) {
    final c = TextEditingController(text: current);
    showCustomPremiumDialog(context: context, title: "修改本週達標獎勵", icon: Icons.stars_outlined, content: buildDialogTextField(c, label: "約定的懲罰或獎勵內容", maxLines: 2), onSave: () async {
      await _weekDocRef.set({'rewardText': c.text}, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    });
  }

  void _showEditTaskDialog(int index, List<dynamic> all, bool isLeft) {
    final currentTask = all[index];
    final taskController = TextEditingController(text: isLeft ? currentTask['taskL'] : currentTask['taskR']);
    final detailController = TextEditingController(text: isLeft ? (currentTask['detailL'] ?? "") : (currentTask['detailR'] ?? ""));

    showCustomPremiumDialog(context: context, title: "調整任務與詳情", icon: Icons.tune_rounded, saveLabel: "UPDATE", content: Column(mainAxisSize: MainAxisSize.min, children: [buildDialogTextField(taskController, label: "挑戰"), buildDialogTextField(detailController, label: "任務詳細說明 (選填)", maxLines: 2)]), onSave: () {
      if (isLeft) {
        all[index]['taskL'] = taskController.text.trim();
        all[index]['detailL'] = detailController.text.trim();
      } else {
        all[index]['taskR'] = taskController.text.trim();
        all[index]['detailR'] = detailController.text.trim();
      }
      _saveTasks(all);
      if (mounted) Navigator.pop(context);
    });
  }

  void _showAddTaskRowDialog(List<dynamic> tasks) {
    final l = TextEditingController(); final detailL = TextEditingController();
    final r = TextEditingController(); final detailR = TextEditingController();

    showCustomPremiumDialog(context: context, title: "新增雙人對決任務", icon: Icons.playlist_add_rounded, saveLabel: "ADD", content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [buildDialogTextField(l, label: "$userL 的新挑戰"), buildDialogTextField(detailL, label: "$userL 的詳細說明", maxLines: 2), const SizedBox(height: 16), buildDialogTextField(r, label: "$userR 的新挑戰"), buildDialogTextField(detailR, label: "$userR 的詳細說明", maxLines: 2)])), onSave: () {
      if (l.text.trim().isNotEmpty || r.text.trim().isNotEmpty) {
        tasks.add({"taskL": l.text.trim(), "statusL": 0, "detailL": detailL.text.trim(), "taskR": r.text.trim(), "statusR": 0, "detailR": detailR.text.trim()});
        _weekDocRef.set({'tasks': tasks}, SetOptions(merge: true));
      }
      if (mounted) Navigator.pop(context);
    });
  }

  void _showTaskDetailDialog(String title, String detail) {
    showCustomPremiumDialog(context: context, title: "任務詳細說明", icon: Icons.assignment_outlined, saveLabel: "CLOSE", content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 14), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)), child: Text(detail.trim().isEmpty ? "目前此任務尚未填寫額外的細節說明。" : detail, style: const TextStyle(fontSize: 14, color: Color(0xFF636E72), height: 1.5)))]), onSave: () => Navigator.pop(context));
  }
}
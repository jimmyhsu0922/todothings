import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyDuelTable extends StatefulWidget {
  const WeeklyDuelTable({super.key});
  @override
  State<WeeklyDuelTable> createState() => _WeeklyDuelTableState();
}

class _WeeklyDuelTableState extends State<WeeklyDuelTable> {
  // 📌 自動動態計算當前的年份、月份、與該月第幾週
  late int currentYear;
  late int currentMonth;
  late int currentWeek;

  final String userL = "心柔";
  final String userR = "靖祐";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentYear = now.year;
    currentMonth = now.month;
    // 計算當前是該月的第幾週 (以每7天為一週計算)
    currentWeek = ((now.day - 1) / 7).floor() + 1;
  }

  String get _weekDocKey => "$currentYear-$currentMonth-$currentWeek";
  DocumentReference get _weekDocRef => FirebaseFirestore.instance.collection('weeks').doc(_weekDocKey);

  // --- ✨ 高質感美化彈窗通用建構器 ---
  Widget _buildDialogHeader({required String title, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFB),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF636E72), size: 18),
          const SizedBox(width: 12),
          Text(
            title, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, {String? label, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: const Color(0xFF2D3436),
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D3436)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2D3436), width: 1.5)),
      ),
    );
  }

  Widget _buildDialogActions({required Function() onCancel, required Function() onSave, String saveLabel = "SAVE"}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFB),
        border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel, 
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3436),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onSave,
            child: Text(saveLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _weekDocRef.snapshots(),
      builder: (context, snapshot) {
        // 📌 最上層標題預設顯示動態年、月、第幾週
        String bannerTitle = "$currentYear 年 $currentMonth 月 第 $currentWeek 週";
        String rewardText = "尚未設定達成獎勵內容";
        List<dynamic> tasks = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          bannerTitle = data['bannerTitle'] ?? bannerTitle;
          rewardText = data['rewardText'] ?? rewardText;
          tasks = data['tasks'] ?? [];
        }

        return Container(
          color: const Color(0xFFF8F9FA), 
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CURRENT PERFORMANCE", style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showEditBannerDialog(bannerTitle),
                    // 📌 這裡幫你改成了 FontWeight.w700 質感粗體！
                    child: Text(bannerTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
                  ),
                  const SizedBox(height: 40),

                  // 先顯示 心柔 的區塊
                  _buildUserTaskBlock(userL, tasks, true),
                  const SizedBox(height: 44),

                  // 再顯示 靖祐 的區塊
                  _buildUserTaskBlock(userR, tasks, false),
                  const SizedBox(height: 52),

                  _buildRewardCard(rewardText),
                  const SizedBox(height: 28),
                  _buildAddButton(tasks),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserTaskBlock(String name, List<dynamic> tasks, bool isLeft) {
    double rate = 0;
    if (tasks.isNotEmpty) {
      int doneCount = tasks.where((t) => (isLeft ? t['statusL'] : t['statusR']) == 1).length;
      rate = doneCount / tasks.length;
    }

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
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: rate, minHeight: 3, backgroundColor: const Color(0xFFECECEC), color: const Color(0xFF2D3436)),
        ),
        const SizedBox(height: 20),
        if (tasks.isEmpty)
          const Text("No tasks assigned.", style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...tasks.asMap().entries.map((e) => _buildIndividualTaskRow(e.value, e.key, tasks, isLeft)),
      ],
    );
  }

  Widget _buildIndividualTaskRow(Map<String, dynamic> task, int index, List<dynamic> all, bool isLeft) {
    int status = isLeft ? task['statusL'] : task['statusR'];
    String taskText = isLeft ? task['taskL'] : task['taskR'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16), 
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1)))),
      child: Row(
        children: [
          _buildStatusBox(status, (next) {
            if (isLeft) all[index]['statusL'] = next;
            else all[index]['statusR'] = next;
            _weekDocRef.update({'tasks': all});
          }),
          const SizedBox(width: 18),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showEditTaskDialog(index, all, isLeft),
              child: Text(
                taskText,
                style: TextStyle(
                  fontSize: 15,
                  color: status == 1 ? Colors.grey.shade300 : const Color(0xFF636E72),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(int status, Function(int) onStatusChanged) {
    Widget innerWidget = const SizedBox.shrink();
    BoxDecoration decoration;

    if (status == 1) { 
      decoration = BoxDecoration(color: const Color(0xFF2D3436), borderRadius: BorderRadius.circular(8));
      innerWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 18);
    } else if (status == 2) { 
      decoration = BoxDecoration(color: const Color(0xFFE4C0C0), borderRadius: BorderRadius.circular(8));
      innerWidget = const Icon(Icons.close_rounded, color: Color(0xFFD63031), size: 18);
    } else { 
      decoration = BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDEDEDE), width: 1.2));
    }

    return GestureDetector(
      onTap: () {
        int nextStatus = (status + 1) % 3;
        onStatusChanged(nextStatus);
      },
      child: Container(
        width: 30, height: 30,
        decoration: decoration,
        child: Center(child: innerWidget),
      ),
    );
  }

  Widget _buildRewardCard(String text) {
    return GestureDetector(
      onTap: () => _showEditRewardDialog(text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("COMMITMENT", style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF2D3436), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(List<dynamic> tasks) {
    return OutlinedButton(
      onPressed: () => _showAddTaskRowDialog(tasks),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: Color(0xFFDCDCDC), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text("ADD NEW TASK", style: TextStyle(fontSize: 12, letterSpacing: 1, color: Color(0xFF636E72), fontWeight: FontWeight.bold)),
    );
  }

  // ---------------------------------------------------------------------------
  // ✨ 高級感工藝客製化彈窗 (Custom Professional Dialogs)
  // ---------------------------------------------------------------------------
  void _showEditBannerDialog(String current) {
    final c = TextEditingController(text: current);
    _showCustomPremiumDialog(
      title: "修改核心目標", 
      icon: Icons.edit_note_rounded,
      content: _buildDialogTextField(c, label: "本週對決核心主題"),
      onSave: () async {
        await _weekDocRef.set({'bannerTitle': c.text}, SetOptions(merge: true));
        if (mounted) Navigator.pop(context);
      }
    );
  }

  void _showEditRewardDialog(String current) {
    final c = TextEditingController(text: current);
    _showCustomPremiumDialog(
      title: "修改本週達標獎勵", 
      icon: Icons.stars_outlined,
      content: _buildDialogTextField(c, label: "約定的懲罰或獎勵內容", maxLines: 2),
      onSave: () async {
        await _weekDocRef.set({'rewardText': c.text}, SetOptions(merge: true));
        if (mounted) Navigator.pop(context);
      }
    );
  }

  void _showEditTaskDialog(int index, List<dynamic> all, bool isLeft) {
    final c = TextEditingController(text: isLeft ? all[index]['taskL'] : all[index]['taskR']);
    _showCustomPremiumDialog(
      title: "編輯個別任務", 
      icon: Icons.assignment_outlined,
      content: _buildDialogTextField(c, label: "任務名稱"),
      onSave: () async {
        if (isLeft) all[index]['taskL'] = c.text; else all[index]['taskR'] = c.text;
        await _weekDocRef.update({'tasks': all});
        if (mounted) Navigator.pop(context);
      }
    );
  }

  void _showAddTaskRowDialog(List<dynamic> tasks) {
    final l = TextEditingController();
    final r = TextEditingController();
    _showCustomPremiumDialog(
      title: "新增雙人對決任務",
      icon: Icons.playlist_add_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogTextField(l, label: "$userL 的新挑戰"),
          const SizedBox(height: 16),
          _buildDialogTextField(r, label: "$userR 的新挑戰"),
        ],
      ),
      saveLabel: "ADD",
      onSave: () async {
        tasks.add({
          "taskL": l.text.isEmpty ? "自主挑戰" : l.text, 
          "statusL": 0, "statusR": 0, 
          "taskR": r.text.isEmpty ? "自主挑戰" : r.text
        });
        await _weekDocRef.set({'tasks': tasks}, SetOptions(merge: true));
        if (mounted) Navigator.pop(context);
      }
    );
  }

  // 頂級彈窗框架容器
  void _showCustomPremiumDialog({
    required String title, 
    required IconData icon, 
    required Widget content, 
    required Function() onSave,
    String saveLabel = "SAVE"
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 32, offset: const Offset(0, 12))
              ]
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(title: title, icon: icon),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: content,
                ),
                _buildDialogActions(
                  onCancel: () => Navigator.pop(ctx), 
                  onSave: onSave,
                  saveLabel: saveLabel
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
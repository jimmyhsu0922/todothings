import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  int selectedYear = 2026;
  int selectedMonth = 7;
  final String userL = "心柔";
  final String userR = "靖祐";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MONTHLY ARCHIVE", style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // 📌 這裡也同步幫你改成了 FontWeight.w700 質感粗體！
                  Text("$selectedYear 年 $selectedMonth 月", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
                  const SizedBox(height: 20),
                  Row(children: [
                    _buildDrop(selectedYear, [2025, 2026, 2027], "年", (v) => setState(() => selectedYear = v!)),
                    const SizedBox(width: 12),
                    _buildDrop(selectedMonth, List.generate(12, (i) => i + 1), "月", (v) => setState(() => selectedMonth = v!)),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: List.generate(5, (index) => _buildWeekSection(index + 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrop(int val, List<int> items, String unit, Function(int?) onChg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFEFEFEF))),
      child: DropdownButton<int>(
        value: val, underline: const SizedBox(), icon: const Icon(Icons.keyboard_arrow_down, size: 14),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text("$i $unit", style: const TextStyle(fontSize: 14, color: Color(0xFF2D3436))))).toList(),
        onChanged: onChg,
      ),
    );
  }

  Widget _buildWeekSection(int week) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('weeks').doc("$selectedYear-$selectedMonth-$week").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> tasks = data['tasks'] ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEFEFEF))),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), color: const Color(0xFFFBFBFB),
              child: Text("WEEK 0$week", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF2D3436))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                // 📌 名字標頭字體放大至 14
                Expanded(child: Text(userL, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)))),
                const SizedBox(width: 68), // 配合方框放大的間距
                Expanded(child: Text(userR, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)))),
              ]),
            ),
            ...tasks.map((t) => _buildDuelRow(t)),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16), color: const Color(0xFFFBFBFB),
              child: Text("Reward: ${data['rewardText'] ?? 'N/A'}", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            )
          ]),
        );
      },
    );
  }

  Widget _buildDuelRow(Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 稍微拉大上下行距
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF9F9F9)))),
      child: Row(children: [
        // 📌 左任務改為置中 (TextAlign.center) 且放大至 14
        Expanded(child: Text(t['taskL'], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: t['statusL'] == 1 ? Colors.grey.shade300 : const Color(0xFF636E72)))),
        const SizedBox(width: 10),
        
        // 📌 靜態歷史方框放大
        _buildStaticStatusBox(t['statusL']), 
        const SizedBox(width: 8),
        _buildStaticStatusBox(t['statusR']),
        
        const SizedBox(width: 10),
        // 📌 右任務改為置中 (TextAlign.center) 且放大至 14
        Expanded(child: Text(t['taskR'], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: t['statusR'] == 1 ? Colors.grey.shade300 : const Color(0xFF636E72)))),
      ]),
    );
  }

  Widget _buildStaticStatusBox(int status) {
    Widget innerWidget = const SizedBox.shrink();
    BoxDecoration decoration;

    // 📌 歷史頁方框放大至 28x28，圓角 8
    if (status == 1) { 
      decoration = BoxDecoration(color: const Color(0xFF2D3436), borderRadius: BorderRadius.circular(8));
      innerWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (status == 2) { 
      decoration = BoxDecoration(color: const Color(0xFFE4C0C0), borderRadius: BorderRadius.circular(8));
      innerWidget = const Icon(Icons.close_rounded, color: Color(0xFFD63031), size: 16);
    } else { 
      decoration = BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2));
    }

    return Container(
      width: 28, height: 28, 
      decoration: decoration,
      child: Center(child: innerWidget),
    );
  }
}
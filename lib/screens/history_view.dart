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

        // 🎯 方案二核心：各自過濾並提取真正有內容的任務，移除空白佔位
        final validL = tasks.where((t) => (t['taskL'] ?? "").toString().trim().isNotEmpty).toList();
        final validR = tasks.where((t) => (t['taskR'] ?? "").toString().trim().isNotEmpty).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEFEFEF))),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), color: const Color(0xFFFBFBFB),
              child: Text("WEEK 0$week", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF2D3436))),
            ),

            // 🎯 獨立雙欄排版區塊
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: IntrinsicHeight( // 確保中間的分隔線能完美伸展到與最高的那一欄同高
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌸 左半邊欄位：心柔的獨立歷史挑戰
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Center(child: Text(userL, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)))),
                          const SizedBox(height: 12),
                          if (validL.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text("本週無挑戰", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                              ),
                            )
                          else
                            ...validL.map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t['taskL'], 
                                      textAlign: TextAlign.end, 
                                      style: TextStyle(fontSize: 14, color: t['statusL'] == 1 ? Colors.grey.shade300 : const Color(0xFF636E72)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildStaticStatusBox(t['statusL']),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),

                    // ｜ 中間優雅的分隔線
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      width: 1,
                      color: const Color(0xFFF1F2F6),
                    ),

                    // ⚡ 右半邊欄位：靖祐的獨立歷史挑戰
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Text(userR, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)))),
                          const SizedBox(height: 12),
                          if (validR.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text("本週無挑戰", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                              ),
                            )
                          else
                            ...validR.map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildStaticStatusBox(t['statusR']),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t['taskR'], 
                                      textAlign: TextAlign.start, 
                                      style: TextStyle(fontSize: 14, color: t['statusR'] == 1 ? Colors.grey.shade300 : const Color(0xFF636E72)),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(16), color: const Color(0xFFFBFBFB),
              child: Text("Reward: ${data['rewardText'] ?? 'N/A'}", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            )
          ]),
        );
      },
    );
  }

  Widget _buildStaticStatusBox(int status) {
    Widget innerWidget = const SizedBox.shrink();
    BoxDecoration decoration;

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
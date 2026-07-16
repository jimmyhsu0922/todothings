import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'devotional_model.dart';
import 'faith_widgets.dart';

class FaithGrowthView extends StatefulWidget {
  const FaithGrowthView({super.key});

  @override
  State<FaithGrowthView> createState() => _FaithGrowthViewState();
}

class _FaithGrowthViewState extends State<FaithGrowthView> {
  final DocumentReference _faithDocRef =
      FirebaseFirestore.instance.collection('faith').doc('timeline');

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // 目前切換的是哪個人的專屬視角 (true = 靖祐, false = 心柔)
  bool _isJingYouView = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 根據當前選擇的人，決定寫入 Firestore 的欄位名稱
  String get _currentRecordsKey => _isJingYouView ? 'records_jingyou' : 'records_xinrou';

  Future<void> _updateFirestoreRecords(List<DevotionalItem> items) async {
    final List<Map<String, dynamic>> serializedList =
        items.map((item) => item.toMap()).toList();
    
    await _faithDocRef.set({_currentRecordsKey: serializedList}, SetOptions(merge: true));
  }

  void _showEntryDialog({
    bool isEditing = false,
    int? index,
    DevotionalItem? item,
    List<DevotionalItem>? currentList,
  }) {
    if (currentList == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return DevotionalDialog(
          isEditing: isEditing,
          initialItem: item,
          onSave: (year, date, scripture, notes) {
            setState(() {
              if (isEditing && index != null) {
                currentList[index].year = year;
                currentList[index].date = date;
                currentList[index].scripture = scripture;
                currentList[index].notes = notes;
              } else {
                final colors = [
                  const Color(0xFFFF8A8A),
                  const Color(0xFF6C5CE7),
                  const Color(0xFF00CEC9),
                  const Color(0xFFFAB1A0),
                ];
                final icons = [
                  Icons.wb_sunny_rounded,
                  Icons.spa_rounded,
                  Icons.tungsten_rounded,
                  Icons.favorite_rounded,
                ];

                currentList.add(
                  DevotionalItem(
                    year: year,
                    date: date,
                    scripture: scripture,
                    notes: notes,
                    themeColor: colors[currentList.length % colors.length],
                    icon: icons[currentList.length % icons.length],
                  ),
                );
              }
            });
            _updateFirestoreRecords(currentList);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/faith_bg.JPG'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _faithDocRef.snapshots(),
            builder: (context, snapshot) {
              List<DevotionalItem> items = [];

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                
                List<dynamic> rawRecords = [];
                if (_isJingYouView) {
                  rawRecords = data['records_jingyou'] ?? data['records'] ?? [];
                } else {
                  rawRecords = data['records_xinrou'] ?? [];
                }

                items = rawRecords
                    .map((map) => DevotionalItem.fromMap(map as Map<String, dynamic>))
                    .toList();

                items.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 頂部標題與控制區域
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "SPIRITUAL PATH",
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 小巧切換鈕
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  _buildMiniSwitchButton(label: "靖", isTargetJingYou: true),
                                  _buildMiniSwitchButton(label: "柔", isTargetJingYou: false),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isJingYouView ? "靖祐的每日經文" : "心柔的每日經文",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showEntryDialog(
                                isEditing: false,
                                currentList: items,
                              ),
                              icon: const Icon(Icons.add_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                padding: const EdgeInsets.all(12),
                                elevation: 4,
                                shadowColor: const Color(0xFF6C5CE7).withOpacity(0.4),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 橫向滾動的時間線與道路
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              "點選右上角 + 新增${_isJingYouView ? '靖祐' : '心柔'}的第一筆靈修紀錄吧！🌟",
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                          )
                        : Stack(
                            children: [
                              // 💡 拿掉 key: UniqueKey() 避免重複銷毀與重置線條
                              TimelineRoadLayer(
                                itemCount: items.length,
                                scrollOffset: _scrollOffset,
                              ),
                              // 💡 拿掉 key: UniqueKey() 恢復流暢無阻的左右滾動！
                              ListView.builder(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return DevotionalCard(
                                    item: item,
                                    index: index,
                                    onEditTap: () => _showEntryDialog(
                                      isEditing: true,
                                      index: index,
                                      item: item,
                                      currentList: items,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSwitchButton({required String label, required bool isTargetJingYou}) {
    final bool isSelected = _isJingYouView == isTargetJingYou;
    
    return GestureDetector(
      onTap: () {
        if (_isJingYouView != isTargetJingYou) {
          setState(() {
            _isJingYouView = isTargetJingYou;
            _scrollOffset = 0.0;
          });
          // 💡 改用控制器直接將滾動位置重置回最左邊，不破壞元件狀態
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0.0);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF636E72),
          ),
        ),
      ),
    );
  }
}
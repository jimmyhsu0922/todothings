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

  bool _isJingYouView = true;
  bool _hasInitialScrolled = false;

  // 暫存目前的經文清單，供切換頁面或視角時重新定位使用
  List<DevotionalItem> _cachedItems = [];

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

  String get _currentRecordsKey => _isJingYouView ? 'records_jingyou' : 'records_xinrou';

  Future<void> _updateFirestoreRecords(List<DevotionalItem> items) async {
    final List<Map<String, dynamic>> serializedList =
    items.map((item) => item.toMap()).toList();

    await _faithDocRef.set({_currentRecordsKey: serializedList}, SetOptions(merge: true));
  }

  // 💡 自動計算並平滑捲動至最接近今天的卡片
  void _scrollToClosestToday(List<DevotionalItem> items) {
    if (items.isEmpty || !_scrollController.hasClients) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int closestIndex = 0;
    int minDifferenceInDays = 999999;

    for (int i = 0; i < items.length; i++) {
      final itemDate = items[i].parsedDate;
      final difference = itemDate.difference(today).inDays.abs();

      if (difference < minDifferenceInDays) {
        minDifferenceInDays = difference;
        closestIndex = i;
      }
    }

    _scrollToIndex(closestIndex);
  }

  // 💡 按指定 Index 自動捲動到該卡片
  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const double stepX = 312.0;
    final double targetOffset = index * stepX;
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double finalOffset = targetOffset.clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      finalOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  // 💡 經文目錄彈窗：在日期旁加入星星標記
  void _showScriptureListBottomSheet(List<DevotionalItem> items) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_isJingYouView ? '靖祐' : '心柔'}的經文目錄",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F2F6)),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                    child: Text("尚無靈修紀錄", style: TextStyle(color: Colors.grey)),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F2F6)),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: item.themeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${item.year}/${item.date}",
                                style: TextStyle(
                                  color: item.themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (item.hasHighlightedBorder) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFFB142),
                                ),
                              ],
                            ],
                          ),
                        ),
                        title: Text(
                          item.titleVerse,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _scrollToIndex(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                _cachedItems = items;

                // 💡 首次載入或切換頁面回來時，自動捲動至最接近今天的經文
                if (!_hasInitialScrolled && items.isNotEmpty) {
                  _hasInitialScrolled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToClosestToday(items);
                  });
                }
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
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  _buildMiniSwitchButton(
                                    label: "靖",
                                    isTargetJingYou: true,
                                  ),
                                  _buildMiniSwitchButton(
                                    label: "柔",
                                    isTargetJingYou: false,
                                  ),
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
                            // 💡 右上角按鈕組（回到今天 + 目錄清單 + 新增）
                            Row(
                              children: [
                                // 💡 新增手動「回到今天」的捷徑按鈕
                                IconButton(
                                  onPressed: () => _scrollToClosestToday(items),
                                  icon: const Icon(Icons.today_rounded, color: Color(0xFF6C5CE7)),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    elevation: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _showScriptureListBottomSheet(items),
                                  icon: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF6C5CE7)),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    elevation: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                ),
                              ],
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
                        TimelineRoadLayer(
                          itemCount: items.length,
                          scrollOffset: _scrollOffset,
                        ),
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
                              onColorChanged: (newColorIndex) {
                                setState(() {
                                  item.selectedColorIndex = newColorIndex;
                                });
                                _updateFirestoreRecords(items);
                              },
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

  Widget _buildMiniSwitchButton({
    required String label,
    required bool isTargetJingYou,
  }) {
    final bool isSelected = _isJingYouView == isTargetJingYou;

    return GestureDetector(
      onTap: () {
        if (_isJingYouView != isTargetJingYou) {
          setState(() {
            _isJingYouView = isTargetJingYou;
            _scrollOffset = 0.0;
            _hasInitialScrolled = false; // 重置狀態，切換視角時自動重新尋找最接近今天的經文
          });
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
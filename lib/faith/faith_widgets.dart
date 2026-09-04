import 'package:flutter/material.dart';
import 'devotional_model.dart';

// ==================== 1. 蜿蜒道路繪製背景 (支援滾動同步) ====================
class TimelineRoadLayer extends StatelessWidget {
  final int itemCount;
  final double scrollOffset;

  const TimelineRoadLayer({
    super.key,
    required this.itemCount,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: RoadPainter(
          itemCount: itemCount,
          scrollOffset: scrollOffset,
        ),
      ),
    );
  }
}

class RoadPainter extends CustomPainter {
  final int itemCount;
  final double scrollOffset;

  RoadPainter({
    required this.itemCount,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount == 0) return;

    final roadBackgroundPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final roadLinePaint = Paint()
      ..color = const Color(0xFFA29BFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // 💡 寬度恢復為 280，將繪圖間距精密調回：280 卡片寬 + 32 右邊距 = 312.0
    const double stepX = 312.0; 
    
    // 起點 startX 扣除 scrollOffset，與 ListView 滾動完全貼合
    final double startX = 60.0 - scrollOffset;

    for (int i = 0; i < itemCount; i++) {
      final double x = startX + (i * stepX);
      final double y = i % 2 == 0 ? 110.0 : 180.0;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final double prevX = startX + ((i - 1) * stepX);
        final double prevY = (i - 1) % 2 == 0 ? 110.0 : 180.0;
        
        path.cubicTo(
          prevX + stepX * 0.4, prevY,
          x - stepX * 0.4, y,
          x, y,
        );
      }
    }

    canvas.drawPath(path, roadBackgroundPaint);
    canvas.drawPath(path, roadLinePaint);

    final dotPaint = Paint()..color = const Color(0xFF6C5CE7);
    for (int i = 0; i < itemCount; i++) {
      final double x = startX + (i * stepX);
      final double y = i % 2 == 0 ? 110.0 : 180.0;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount || oldDelegate.scrollOffset != scrollOffset;
  }
}


// ==================== 2. 信仰成長經文卡片 (點擊切換外框顏色) ====================
class DevotionalCard extends StatefulWidget {
  final DevotionalItem item;
  final int index;
  final VoidCallback onEditTap;
  final Function(int newColorIndex) onColorChanged; // 💡 新增：外框改變回呼

  const DevotionalCard({
    super.key,
    required this.item,
    required this.index,
    required this.onEditTap,
    required this.onColorChanged,
  });

  @override
  State<DevotionalCard> createState() => _DevotionalCardState();
}

class _DevotionalCardState extends State<DevotionalCard> {
  final List<Color?> _borderColors = [
    null,                   // 0: 預設無外框
    const Color(0xFF6C5CE7), // 1: 紫色
    const Color(0xFFFF7675), // 2: 珊瑚紅
    const Color(0xFF00B894), // 3: 薄荷綠
  ];

  void _toggleBorderColor() {
    final nextIndex = (widget.item.selectedColorIndex + 1) % _borderColors.length;
    widget.onColorChanged(nextIndex); // 通知父元件更新
  }

  @override
  Widget build(BuildContext context) {
    final double topMargin = widget.index % 2 == 0 ? 30 : 100;
    final int colorIdx = widget.item.selectedColorIndex;
    final Color? activeBorderColor = _borderColors[colorIdx < _borderColors.length ? colorIdx : 0];
    final bool isHighlighted = activeBorderColor != null;

    return Container(
      margin: EdgeInsets.only(top: topMargin, right: 32),
      width: 280,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 點擊日期區域
            GestureDetector(
              onTap: widget.onEditTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.item.themeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.item.themeColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${widget.item.year}/${widget.item.date}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 卡片本體
            GestureDetector(
              onTap: _toggleBorderColor,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isHighlighted
                          ? activeBorderColor.withOpacity(0.25)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isHighlighted ? 18 : 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: activeBorderColor ?? const Color(0xFFF1F2F6),
                    width: isHighlighted ? 2.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(widget.item.icon, color: widget.item.themeColor, size: 22),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isHighlighted ? 10 : 6,
                          height: isHighlighted ? 10 : 6,
                          decoration: BoxDecoration(
                            color: activeBorderColor ?? widget.item.themeColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          widget.item.scripture,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3436),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (widget.item.notes.isNotEmpty) ...[
                      const Divider(height: 18, color: Color(0xFFF1F2F6)),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 110),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            widget.item.notes,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 3. 彈出新增或修改的對話框（支援年份選擇） ====================
class DevotionalDialog extends StatefulWidget {
  final bool isEditing;
  final DevotionalItem? initialItem;
  final Function(int year, String date, String scripture, String notes) onSave;

  const DevotionalDialog({
    super.key,
    required this.isEditing,
    this.initialItem,
    required this.onSave,
  });

  @override
  State<DevotionalDialog> createState() => _DevotionalDialogState();
}

class _DevotionalDialogState extends State<DevotionalDialog> {
  late int _selectedYear;
  late TextEditingController _dateController;
  late TextEditingController _scriptureController;
  late TextEditingController _notesController;

  // 生成供選擇的年份列表（今年前後5年）
  final List<int> _years = List.generate(11, (index) => (DateTime.now().year - 5) + index);

  @override
  void initState() {
    super.initState();
    _scriptureController = TextEditingController(text: widget.initialItem?.scripture ?? '');
    _notesController = TextEditingController(text: widget.initialItem?.notes ?? '');
    
    if (widget.isEditing && widget.initialItem != null) {
      _selectedYear = widget.initialItem!.year;
      _dateController = TextEditingController(text: widget.initialItem!.date);
    } else {
      final now = DateTime.now();
      _selectedYear = now.year;
      _dateController = TextEditingController(
        text: "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}",
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _scriptureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.isEditing ? "修改今日靈修" : "記錄今日靈修",
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 年份與日期選擇（並排顯示）
          // 💡 將原本橫向的 Row 改為縱向的 Column，徹底消滅寬度不足的問題！
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 年份下拉選單 (單獨一行，滿版)
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: "年份",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _years.map((int year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text("$year 年"),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                    });
                  }
                },
              ),
              
              // 上下輸入框中間的舒適間距
              const SizedBox(height: 16), 

              // 2. 日期輸入框 (單獨一行，滿版)
              TextFormField(
                controller: _dateController, // 👈 記得換成你原本的 Date Controller
                decoration: const InputDecoration(
                  labelText: "日期 (MM/DD)",
                  hintText: "07/16",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            TextField(
              controller: _scriptureController,
              decoration: const InputDecoration(
                labelText: "當天主題經文",
                hintText: "例如：詩篇 23:1...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "文字紀錄 / 心得",
                hintText: "寫下今天的領受與禱告...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("取消", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEditing ? const Color(0xFF00B894) : const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (_scriptureController.text.isNotEmpty) {
              widget.onSave(
                _selectedYear,
                _dateController.text,
                _scriptureController.text,
                _notesController.text,
              );
              Navigator.pop(context);
            }
          },
          child: Text(widget.isEditing ? "保存修改" : "新增"),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../models/task_status.dart';

class TaskCard extends StatelessWidget {
  final String taskText;
  final String taskDetail;
  final TaskStatus status;
  final VoidCallback onStatusToggle;
  final VoidCallback onTextTap;
  final VoidCallback onProgress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.taskText,
    required this.taskDetail,
    required this.status,
    required this.onStatusToggle,
    required this.onTextTap,
    required this.onProgress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 依據狀態決定打卡框的 UI 表現
    Widget statusWidget = const SizedBox.shrink();
    BoxDecoration statusDecoration;

    if (status == TaskStatus.completed) {
      statusDecoration = BoxDecoration(color: const Color(0xFF2D3436), borderRadius: BorderRadius.circular(6));
      statusWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
    } else if (status == TaskStatus.failed) {
      statusDecoration = BoxDecoration(color: const Color(0xFFE4C0C0), borderRadius: BorderRadius.circular(6));
      statusWidget = const Icon(Icons.close_rounded, color: Color(0xFFD63031), size: 14);
    } else {
      statusDecoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDEDEDE), width: 1.2),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF1F1F1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部：勾選狀態框 + 挑戰文字內容（點擊文字看詳情）
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onStatusToggle,
                  child: Container(
                    width: 22, height: 22,
                    decoration: statusDecoration,
                    child: Center(child: statusWidget),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTextTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: status == TaskStatus.completed ? Colors.grey.shade300 : const Color(0xFF2D3436),
                            decoration: status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (taskDetail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            taskDetail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            const SizedBox(height: 8),
            // 下半部獨立一列操作區：功能按鈕下放，任憑文字再長，也絕對不會被擠掉！
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE7F6),
                    foregroundColor: const Color(0xFF673AB7),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: onProgress,
                  icon: const Icon(Icons.equalizer_rounded, size: 14),
                  label: const Text("進度", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF636E72)),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFE74C3C)),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
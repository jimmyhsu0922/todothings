import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  final String titleText;
  final VoidCallback onTap;

  const StatusBanner({
    super.key,
    required this.titleText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // 點擊觸發編輯彈窗
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 14, color: Colors.grey), // 提示可編輯
          ],
        ),
      ),
    );
  }
}
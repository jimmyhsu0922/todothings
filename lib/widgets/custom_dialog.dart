import 'package:flutter/material.dart';

// 統一管理與建置全站高級彈窗，大幅刪除重複代碼
void showCustomPremiumDialog({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget content,
  required VoidCallback onSave,
  String saveLabel = "SAVE",
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
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 標題列
              Container(
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
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))),
                  ],
                ),
              ),
              // 內容區
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: content,
              ),
              // 按鈕操作列
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBFBFB),
                  border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
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
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// 萬用輸入欄位產生器
Widget buildDialogTextField(TextEditingController controller, {String? label, int maxLines = 1}) {
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
import 'package:flutter/material.dart';

class DevotionalItem {
  int year;
  String date;
  String scripture;
  String notes;
  final Color themeColor;
  final IconData icon;
  int selectedColorIndex; // 💡 新增：紀錄外框顏色 (0:無, 1:紫, 2:紅, 3:綠)

  DevotionalItem({
    required this.year,
    required this.date,
    required this.scripture,
    required this.notes,
    required this.themeColor,
    required this.icon,
    this.selectedColorIndex = 0, // 預設 0 (無特殊外框)
  });

  // 💡 判斷是否有開啟外框（用於目錄清單顯示星星）
  bool get hasHighlightedBorder => selectedColorIndex > 0;

  // 自動擷取第一行經節名稱
  String get titleVerse {
    if (scripture.isEmpty) return '無經節紀錄';
    final lines = scripture.trim().split('\n');
    return lines.first;
  }

  DateTime get parsedDate {
    try {
      final parts = date.split('/');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      return DateTime(year, month, day);
    } catch (e) {
      return DateTime(year, 1, 1);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'date': date,
      'scripture': scripture,
      'notes': notes,
      'colorValue': themeColor.value,
      'iconCodePoint': icon.codePoint,
      'selectedColorIndex': selectedColorIndex, // 💡 存入 Firestore
    };
  }

  factory DevotionalItem.fromMap(Map<String, dynamic> map) {
    return DevotionalItem(
      year: map['year'] ?? DateTime.now().year,
      date: map['date'] ?? '',
      scripture: map['scripture'] ?? '',
      notes: map['notes'] ?? '',
      themeColor: Color(map['colorValue'] ?? 0xFF6C5CE7),
      icon: IconData(
        map['iconCodePoint'] ?? 0xe5f2,
        fontFamily: 'MaterialIcons',
      ),
      selectedColorIndex: map['selectedColorIndex'] ?? 0, // 💡 從 Firestore 還原
    );
  }
}
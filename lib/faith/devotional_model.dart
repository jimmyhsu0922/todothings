import 'package:flutter/material.dart';

class DevotionalItem {
  int year; // 新增年份欄位
  String date; // 格式如 "07/13"
  String scripture;
  String notes;
  final Color themeColor;
  final IconData icon;

  DevotionalItem({
    required this.year,
    required this.date,
    required this.scripture,
    required this.notes,
    required this.themeColor,
    required this.icon,
  });

  // 輔助屬性：轉換成 DateTime 方便排序比較
  DateTime get parsedDate {
    try {
      final parts = date.split('/');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      return DateTime(year, month, day);
    } catch (e) {
      // 解析失敗時的防呆預設值
      return DateTime(year, 1, 1);
    }
  }

  // 將資料轉成能存入 Firestore 的 Map 格式
  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'date': date,
      'scripture': scripture,
      'notes': notes,
      'colorValue': themeColor.value,
      'iconCodePoint': icon.codePoint,
    };
  }

  // 從 Firestore 還原成 Flutter 物件
  factory DevotionalItem.fromMap(Map<String, dynamic> map) {
    return DevotionalItem(
      year: map['year'] ?? DateTime.now().year, // 若無則預設今年
      date: map['date'] ?? '',
      scripture: map['scripture'] ?? '',
      notes: map['notes'] ?? '',
      themeColor: Color(map['colorValue'] ?? 0xFF6C5CE7),
      icon: IconData(
        map['iconCodePoint'] ?? 0xe5f2,
        fontFamily: 'MaterialIcons',
      ),
    );
  }
}
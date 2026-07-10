enum TaskStatus { pending, completed, failed }

extension TaskStatusExtension on TaskStatus {
  // 將 Enum 轉換成 Firestore 儲存的整數 (0, 1, 2)
  int get value {
    switch (this) {
      case TaskStatus.pending: return 0;
      case TaskStatus.completed: return 1;
      case TaskStatus.failed: return 2;
    }
  }

  // 從 Firestore 的整數還原成 Enum
  static TaskStatus fromInt(int? val) {
    if (val == 1) return TaskStatus.completed;
    if (val == 2) return TaskStatus.failed;
    return TaskStatus.pending;
  }

  // 狀態循環切換：空白 -> 完成 -> 失敗 -> 空白
  TaskStatus get next {
    switch (this) {
      case TaskStatus.pending: return TaskStatus.completed;
      case TaskStatus.completed: return TaskStatus.failed;
      case TaskStatus.failed: return TaskStatus.pending;
    }
  }
}
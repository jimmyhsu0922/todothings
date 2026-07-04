// 定義單一行對決任務
class DuelTask {
  String taskL;
  String taskR;
  int statusL; // 0 = 空白, 1 = 勾, 2 = 叉
  int statusR;

  DuelTask({
    required this.taskL,
    required this.taskR,
    this.statusL = 0,
    this.statusR = 0,
  });
}

// 定義某一週的完整資料 (包含該週的自訂標題與獎勵)
class WeekData {
  String bannerTitle; // 例如 "1 ❌ 0 + ⚡ > 80 %"
  String rewardText;  // 例如 "本月完成獎勵(80%)：吃正老林羊肉爐"
  List<DuelTask> tasks;

  WeekData({
    required this.bannerTitle,
    required this.rewardText,
    required this.tasks,
  });
}
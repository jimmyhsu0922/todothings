# 📝 Todothings - 雙人每週代辦與成長追蹤 App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> *"凡管教的事，當時不覺得快樂，反覺得愁苦；後來卻為那經練過的人結出平安的果子，就是義。" — 希伯來書 12:11*

**Todothings** 是一款專為雙人（心柔 X 靖祐）設計的質感習慣養成、每週挑戰追蹤與靈修成長 App。透過雙欄對決、每日簽到追蹤、靈修時間線、歷史月度歸檔、定時推播提醒與獎勵機制，幫助雙方保持自律，共同成長！

---

## 🌟 核心功能亮點

* ⚔️ **雙人每週對決 (Weekly Duel Table)**
  * **雙欄同步追蹤**：左右獨立展示兩人的每週挑戰任務與完成進度條。
  * **快速複製前週任務**：支援一鍵繼承上一週的未完成或預設任務。
  * **對決目標與獎勵**：自由設定每週核心主題與達標懲罰/獎勵機制（Reward Card）。

* 📅 **每日簽到與進度追蹤 (Task Tracker)**
  * 點擊任務即可進入 7 天（週一至週日）圖形化簽到面板。
  * **三態循環切換**：`⚪ 未記錄` ➔ `🟢 已達成` ➔ `🔴 未達成`。

* 🌱 **信仰成長靈修時間線 (Spiritual Path Timeline)**
  * **雙人獨立靈修視角**：支援「靖祐」與「心柔」雙視角獨立記錄與閱讀切換。
  * **CustomPainter 蜿蜒小徑繪製**：搭配動態畫布（RoadPainter），隨橫向滾動自動連結各個靈修卡片。
  * **智慧導航與自動聚焦**：開啟頁面時自動定位並平滑捲動至「最接近今日」的經文卡片，並提供「回到今日」快速按鈕。
  * **經文目錄與高亮標記**：快速瀏覽歷史靈修經文目錄，卡片支援點擊循環切換多色外框（無/紫/紅/綠），重點經文會在目錄同步標記星號 ⭐。

* 🔔 **智慧定時推播提醒 (Notification Service)**
  * **時區精準推播**：綁定 `Asia/Taipei` 時區，每日早上 09:00 提醒專注待辦，晚上 22:00 提醒自我沉澱與靈修。
  * **自動防崩潰降級機制**：針對 Android 12+ 精準鬧鐘權限進行自動捕捉與安全降級（Exact Schedule -> Inexact Schedule Mode）。
  * **一鍵測試通知**：於設定視窗可發送即時測試推播，確認通知權限運作正常。

* 📚 **歷史月度歸檔 (Monthly Archive)**
  * 自動整理過往年份、月份與週別的挑戰紀錄。
  * 智慧過濾無效或空白佔位任務，提供極簡優雅的雙欄歷史回顧體驗。

* 🔐 **多元安全登入與驗證 (Auth Service)**
  * 支援 **Google 帳號快速登入**（適配 `google_sign_in` v7.2.0 新版驗證架構）與 **訪客體驗模式**。
  * 搭配質感 Loading 遮罩與自動狀態跳轉。

---

## 🛠️ 技術棧 (Tech Stack)

* **UI 框架**：[Flutter](https://flutter.dev/) (Dart)
* **後端與資料庫**：[Firebase Cloud Firestore](https://firebase.google.com/docs/firestore) (即時同步數據 StreamBuilder & SetOptions merge)
* **使用者驗證**：[Firebase Authentication](https://firebase.google.com/docs/auth) (Google Sign-In & Anonymous)
* **繪圖與繪製**：`CustomPainter` (Custom Path & Curve Bezier Road)
* **通知與時區處理**：[flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) & [timezone](https://pub.dev/packages/timezone)
* **架構與設計**：StatefulWidget / Responsive UI / Component-Driven Architecture

---

## 📂 資料庫架構 (Firestore Data Model)

### 1. 每週對決數據 (`weeks` Collection)
以 `YYYY-M-W`（例如 `2026-7-1`）作為 Document ID 進行結構化儲存：
```json
{
  "bannerTitle": "2026 年 7 月 第 1 週",
  "rewardText": "達標者可獲得大餐一份 🍕",
  "tasks": [
    {
      "taskL": "心柔的任務",
      "detailL": "任務細節說明",
      "statusL": 1,         // 0: pending(未完成), 1: completed(已完成), 2: failed(失敗)
      "historyL": [1, 0, 1, 1, 0, 0, 0], // 週一至週日簽到陣列
      "taskR": "靖祐的任務",
      "detailR": "任務細節說明",
      "statusR": 0,
      "historyR": [0, 0, 0, 0, 0, 0, 0]
    }
  ]
}
---
2. 靈修成長數據 (faith/timeline Document)
以 records_jingyou 與 records_xinrou 陣列分別儲存兩人的每日靈修卡片：
{
  "records_jingyou": [
    {
      "year": 2026,
      "date": "07/16",
      "scripture": "詩篇 23:1",
      "notes": "耶和華是我的牧者，我必不致缺乏。",
      "colorValue": 4285324519,
      "iconCodePoint": 58866,
      "selectedColorIndex": 1
    }
  ],
  "records_xinrou": []
}

🏗️ 專案結構與模組說明
lib/
├── models/             # 資料結構模型
│   ├── duel_task.dart             # 每週挑戰任務與週資料模型
│   ├── task_status.dart           # 任務狀態 Enum 與切換邏輯
│   └── devotional_model.dart      # 靈修卡片 DevotionalItem 資料模型
├── services/           # 核心服務邏輯
│   ├── auth_service.dart          # Google & 訪客身份驗證服務
│   └── notification_service.dart  # 本地推播、時區設定與定時提醒服務
├── faith/              # 信仰成長專區模組
│   ├── faith_growth_view.dart     # 靈修成長時間線主視圖 (雙人切換與自動定位)
│   ├── faith_widgets.dart         # CustomPainter 道路繪製 & 經文卡片 & 對話框
├── widgets/            # 可複用 UI 組件 (TaskCard, RewardCard, CustomDialog 等)
├── history_view.dart   # 歷史月度歸檔視圖
├── login_screen.dart   # 迎賓與登入畫面
├── main_navigation.dart# 主導航頁面 (BottomNavigationBar)
├── task_tracker_screen.dart # 7天每日圖形化簽到頁面
└── weekly_duel_table.dart   # 雙人對決主視圖

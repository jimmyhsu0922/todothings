import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // 1. 初始化時區資料
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    // 2. Android 初始化設定
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS 初始化設定
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // 4. Android 13+ 主動請求通知權限
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    // 💡 補強 1：Android 12+ 嘗試請求精準鬧鐘權限（避免 exactAllowWhileIdle 引發崩潰）
    try {
      await androidImplementation?.requestExactAlarmsPermission();
    } catch (e) {
      print("請求精準鬧鐘權限失敗/不支援: $e");
    }

    // 5. 設定每日定時通知（加上安全捕捉）
    await _scheduleDailyNotifications();
  }

  Future<void> _scheduleDailyNotifications() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      '每日定時提醒',
      channelDescription: '提醒完成每日代辦事項與靈修',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // 💡 補強 2：加上 try-catch 降級機制，如果不允許精準鬧鐘，自動切換為粗略計時 mode，絕不當機
    try {
      // 1. 台灣時間 09:00 通知
      await _notificationsPlugin.zonedSchedule(
        101,
        '☀️ 早安！美好的一天開始囉',
        '別忘了檢查今天的待辦事項，讓今天充滿成就感吧！加油💪',
        _nextInstanceOfTime(9, 0),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2. 台灣時間 22:00 通知
      await _notificationsPlugin.zonedSchedule(
        102,
        '🌙 辛苦了！今晚來點自我沉澱',
        '今天過得好嗎？回顧一下今天的待辦事項，寫下靈修心得，給自己讚美吧✨',
        _nextInstanceOfTime(22, 0),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("精準排程設定失敗，切換為非精準模式: $e");

      // 降級處理：使用 inexact 模式防崩潰
      await _notificationsPlugin.zonedSchedule(
        101,
        '☀️ 早安！美好的一天開始囉',
        '別忘了檢查今天的待辦事項，讓今天充滿成就感吧！加油💪',
        _nextInstanceOfTime(9, 0),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _notificationsPlugin.zonedSchedule(
        102,
        '🌙 辛苦了！今晚來點自我沉澱',
        '今天過得好嗎？回顧一下今天的待辦事項，寫下靈修心得，給自己讚美吧✨',
        _nextInstanceOfTime(22, 0),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation('Asia/Taipei'));
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.getLocation('Asia/Taipei'),
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
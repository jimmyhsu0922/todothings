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
    tz.setLocalLocation(tz.getLocation('Asia/Taipei')); // 設定預設時區為台灣

    // 2. Android 初始化設定
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS 初始化設定 (請求通知權限)
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

    // 4. Android 13 (API level 33) 以上主動請求通知權限
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 5. 設定每日定時通知
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

    // 💡 1. 台灣時間 早上 09:00 通知
    await _notificationsPlugin.zonedSchedule(
      101, // 唯一通知 ID
      '☀️ 早安！美好的一天開始囉',
      '別忘了檢查今天的待辦事項，讓今天充滿成就感吧！加油💪',
      _nextInstanceOfTime(9, 0),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每日重複發送
    );

    // 💡 2. 台灣時間 晚上 22:00 通知
    await _notificationsPlugin.zonedSchedule(
      102, // 唯一通知 ID
      '🌙 辛苦了！今晚來點自我沉澱',
      '今天過得好嗎？回顧一下今天的待辦事項，寫下靈修心得，給自己讚美吧✨',
      _nextInstanceOfTime(22, 0),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每日重複發送
    );
  }

  // 輔助函式：計算下一次指定時分的 tz.TZDateTime
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
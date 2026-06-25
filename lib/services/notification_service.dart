import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final itemId = response.payload;
    print('通知タップ: itemId=$itemId');
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'restock_channel',
          '補充リマインダー',
          channelDescription: '在庫の補充タイミングをお知らせします',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  int _notificationId(String itemId) => itemId.hashCode.abs();

  Future<void> scheduleRestockNotification({
    required String itemId,
    required String itemName,
    required DateTime notifyAt,
    bool enabled = true,
  }) async {
    final id = _notificationId(itemId);

    if (!enabled || notifyAt.isBefore(DateTime.now())) {
      await cancelNotification(itemId: itemId);
      return;
    }

    await _plugin.zonedSchedule(
      id,
      '補充のタイミングです 🛒',
      '$itemName の在庫がそろそろなくなりそうです',
      tz.TZDateTime.from(notifyAt, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: itemId,
    );
  }

  Future<void> cancelNotification({required String itemId}) async {
    await _plugin.cancel(_notificationId(itemId));
  }
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      0, // 通知ID（即時通知は固定で0でOK）
      title,
      body,
      _notificationDetails,
    );
  }

  Future<void> updateRestockNotification({
    required String itemId,
    required String itemName,
    required DateTime notifyAt,
    bool enabled = true,
  }) async {
    await scheduleRestockNotification(
      itemId: itemId,
      itemName: itemName,
      notifyAt: notifyAt,
      enabled: enabled,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
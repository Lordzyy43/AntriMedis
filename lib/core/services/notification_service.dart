import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showQueueNear({
    required String queueCode,
    required int remaining,
  }) async {
    const android = AndroidNotificationDetails(
      'queue_updates',
      'Queue updates',
      channelDescription: 'Notifications for AntriMedis queue progress',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      id: queueCode.hashCode,
      title: 'Antrean hampir dipanggil',
      body: 'Nomor $queueCode tersisa $remaining antrean lagi.',
      notificationDetails: details,
    );
  }

  Future<void> showQueueCalled({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'called'),
      title: 'Nomor antrean dipanggil',
      body: 'Nomor $queueCode sedang dipanggil. Silakan menuju poli.',
    );
  }

  Future<void> showQueueSkipped({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'skipped'),
      title: 'Antrean dilewati',
      body: 'Nomor $queueCode dilewati oleh petugas.',
    );
  }

  Future<void> showQueueCancelled({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'cancelled'),
      title: 'Antrean dibatalkan',
      body: 'Nomor $queueCode sudah dibatalkan.',
    );
  }

  Future<void> _showQueueNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'queue_updates',
      'Queue updates',
      channelDescription: 'Notifications for AntriMedis queue progress',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

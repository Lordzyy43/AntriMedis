import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _recentDedupKeys = {};

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_queueUpdatesChannel);
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
    await _showQueueNotification(
      id: queueCode.hashCode,
      title: 'Giliran hampir tiba',
      body: 'Nomor $queueCode tinggal $remaining antrean lagi. Mohon bersiap.',
      dedupKey: 'queue_near:$queueCode',
    );
  }

  Future<void> showRemoteMessage({
    required int id,
    required String title,
    required String body,
    String? dedupKey,
  }) async {
    await _showQueueNotification(
      id: id,
      title: title,
      body: body,
      dedupKey: dedupKey,
    );
  }

  Future<void> showQueueCalled({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'called'),
      title: 'Sedang dipanggil',
      body: 'Nomor $queueCode sedang dipanggil. Silakan menuju poli.',
      dedupKey: 'queue_called:$queueCode',
    );
  }

  Future<void> showQueueSkipped({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'skipped'),
      title: 'Antrean dilewati',
      body: 'Nomor $queueCode dilewati oleh petugas.',
      dedupKey: 'queue_skipped:$queueCode',
    );
  }

  Future<void> showQueueMissed({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'missed'),
      title: 'Terlewat',
      body:
          'Nomor $queueCode terlewat. Tunggu panggil ulang setelah antrean reguler selesai.',
      dedupKey: 'queue_missed:$queueCode',
    );
  }

  Future<void> showQueueCancelled({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'cancelled'),
      title: 'Antrean dibatalkan',
      body: 'Nomor $queueCode sudah dibatalkan.',
      dedupKey: 'queue_cancelled:$queueCode',
    );
  }

  Future<void> showQueueExpired({required String queueCode}) async {
    await _showQueueNotification(
      id: Object.hash(queueCode, 'expired'),
      title: 'Antrean kedaluwarsa',
      body: 'Nomor $queueCode tidak lagi aktif karena sesi layanan ditutup.',
      dedupKey: 'queue_expired:$queueCode',
    );
  }

  Future<void> _showQueueNotification({
    required int id,
    required String title,
    required String body,
    String? dedupKey,
  }) async {
    if (!_shouldShow(dedupKey ?? '$title:$body')) return;

    const android = _queueUpdatesDetails;
    const details = NotificationDetails(android: android);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  bool _shouldShow(String dedupKey) {
    final now = DateTime.now();
    _recentDedupKeys.removeWhere(
      (_, shownAt) => now.difference(shownAt) > const Duration(seconds: 20),
    );
    if (_recentDedupKeys.containsKey(dedupKey)) return false;

    _recentDedupKeys[dedupKey] = now;
    return true;
  }
}

const _queueUpdatesChannel = AndroidNotificationChannel(
  'queue_updates',
  'Pembaruan antrean',
  description: 'Notifikasi perkembangan antrean AntriMedis',
  importance: Importance.high,
);

const _queueUpdatesDetails = AndroidNotificationDetails(
  'queue_updates',
  'Pembaruan antrean',
  channelDescription: 'Notifikasi perkembangan antrean AntriMedis',
  importance: Importance.high,
  priority: Priority.high,
);

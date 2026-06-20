import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/notification_copy.dart';
import 'notification_tap_router.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _recentDedupKeys = {};

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          NotificationTapRouter.instance.handleLocalNotificationResponse,
    );
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
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    await NotificationTapRouter.instance.handleLaunchDetails(launchDetails);
  }

  Future<void> showQueueNear({
    required String queueCode,
    required int remaining,
  }) async {
    final values = {'queue_code': queueCode, 'remaining': remaining};
    await _showQueueNotification(
      id: queueCode.hashCode,
      title: renderLocalNotificationTitle('queue_near', values: values),
      body: renderLocalNotificationBody('queue_near', values: values),
      dedupKey: 'queue_near:$queueCode',
      payload: _payloadFor('queue_near', values),
    );
  }

  Future<void> showRemoteMessage({
    required int id,
    String? eventType,
    required String title,
    required String body,
    Map<String, Object?> values = const {},
    String? dedupKey,
  }) async {
    await _showQueueNotification(
      id: id,
      title: renderLocalNotificationTitle(
        eventType,
        values: values,
        fallbackTitle: title,
      ),
      body: renderLocalNotificationBody(
        eventType,
        values: values,
        fallbackBody: body,
      ),
      dedupKey: dedupKey,
      payload: _payloadFor(eventType, values),
    );
  }

  Future<void> showQueueCalled({required String queueCode}) async {
    final values = {'queue_code': queueCode};
    await _showQueueNotification(
      id: Object.hash(queueCode, 'called'),
      title: renderLocalNotificationTitle('queue_called', values: values),
      body: renderLocalNotificationBody('queue_called', values: values),
      dedupKey: 'queue_called:$queueCode',
      payload: _payloadFor('queue_called', values),
    );
  }

  Future<void> showQueueSkipped({required String queueCode}) async {
    final values = {'queue_code': queueCode};
    await _showQueueNotification(
      id: Object.hash(queueCode, 'skipped'),
      title: renderLocalNotificationTitle('queue_skipped', values: values),
      body: renderLocalNotificationBody('queue_skipped', values: values),
      dedupKey: 'queue_skipped:$queueCode',
      payload: _payloadFor('queue_skipped', values),
    );
  }

  Future<void> showQueueMissed({required String queueCode}) async {
    final values = {'queue_code': queueCode};
    await _showQueueNotification(
      id: Object.hash(queueCode, 'missed'),
      title: renderLocalNotificationTitle('queue_missed', values: values),
      body: renderLocalNotificationBody('queue_missed', values: values),
      dedupKey: 'queue_missed:$queueCode',
      payload: _payloadFor('queue_missed', values),
    );
  }

  Future<void> showQueueCancelled({required String queueCode}) async {
    final values = {'queue_code': queueCode};
    await _showQueueNotification(
      id: Object.hash(queueCode, 'cancelled'),
      title: renderLocalNotificationTitle('queue_cancelled', values: values),
      body: renderLocalNotificationBody('queue_cancelled', values: values),
      dedupKey: 'queue_cancelled:$queueCode',
      payload: _payloadFor('queue_cancelled', values),
    );
  }

  Future<void> showQueueExpired({required String queueCode}) async {
    final values = {'queue_code': queueCode};
    await _showQueueNotification(
      id: Object.hash(queueCode, 'expired'),
      title: renderLocalNotificationTitle('queue_expired', values: values),
      body: renderLocalNotificationBody('queue_expired', values: values),
      dedupKey: 'queue_expired:$queueCode',
      payload: _payloadFor('queue_expired', values),
    );
  }

  Future<void> _showQueueNotification({
    required int id,
    required String title,
    required String body,
    String? dedupKey,
    String? payload,
  }) async {
    if (!_shouldShow(dedupKey ?? '$title:$body')) return;

    const android = _queueUpdatesDetails;
    const details = NotificationDetails(android: android);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
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

  String _payloadFor(
    String? eventType,
    Map<String, Object?> values,
  ) {
    final data = <String, Object?>{
      'event_type': eventType,
      'route': notificationRouteForType(eventType),
      ...values,
    }..removeWhere((_, value) => value == null || value == '');
    return jsonEncode(data);
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

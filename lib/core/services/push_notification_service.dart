import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';
import 'notification_tap_router.dart';
import 'notification_service.dart';

class PushNotificationService {
  PushNotificationService({
    required SupabaseClient supabase,
    FirebaseMessaging? messaging,
  }) : _supabase = supabase,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  String? _activeUserId;

  static bool get isSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  Future<void> initialize() async {
    if (!isSupported) return;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedAppSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      NotificationTapRouter.instance.handleRemoteMessage,
    );
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      _syncTokenForActiveUser,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.notification(
          'Gagal menerima refresh token FCM.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(
        NotificationTapRouter.instance.handleRemoteMessage(initialMessage),
      );
    }
  }

  Future<void> syncForUser(User user) async {
    if (!isSupported) return;
    _activeUserId = user.id;

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.notification('Izin push notification ditolak user.');
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      AppLogger.notification('Token FCM belum tersedia.');
      return;
    }
    await _syncToken(token);
  }

  Future<void> deactivateForUser(User? user) async {
    if (!isSupported || user == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.rpc(
        'deactivate_fcm_token',
        params: {'p_fcm_token': token, 'p_seen_at': now},
      );
    } catch (error, stackTrace) {
      AppLogger.notification(
        'Gagal menonaktifkan token FCM.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (_activeUserId == user.id) _activeUserId = null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
  }

  Future<void> _syncTokenForActiveUser(String token) async {
    final userId = _activeUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _syncToken(token);
  }

  Future<void> _syncToken(String token) async {
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _supabase.rpc(
        'register_fcm_token',
        params: {
          'p_fcm_token': token,
          'p_platform': _platformName,
          'p_seen_at': now,
        },
      );
      AppLogger.notification('Token FCM berhasil disinkronkan.');
    } catch (error, stackTrace) {
      AppLogger.notification(
        'Gagal sinkron token FCM.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;

    final eventType = message.data['type']?.toString();
    final values = <String, Object?>{
      'queue_code': message.data['queue_code']?.toString(),
      'remaining': message.data['remaining']?.toString(),
      'ticket_id': message.data['ticket_id']?.toString(),
      'notification_id': message.data['notification_id']?.toString(),
      'route': message.data['route']?.toString(),
    }..removeWhere((_, value) => value == null || value == '');

    await NotificationService.instance.showRemoteMessage(
      id: message.messageId?.hashCode ?? Object.hash(title, body),
      eventType: eventType,
      title: title,
      body: body,
      values: values,
      dedupKey: _dedupKeyFor(message),
    );
  }

  String _dedupKeyFor(RemoteMessage message) {
    final type = message.data['type']?.toString();
    final queueCode = message.data['queue_code']?.toString();
    final ticketId = message.data['ticket_id']?.toString();
    final notificationId = message.data['notification_id']?.toString();

    if (type != null && queueCode != null) return '$type:$queueCode';
    if (type != null && ticketId != null) return '$type:$ticketId';
    if (notificationId != null) return 'notification:$notificationId';
    return message.messageId ??
        Object.hash(message.data, message.sentTime).toString();
  }

  String get _platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
  }
}

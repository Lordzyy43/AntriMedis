import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/notification_copy.dart';
import '../navigation/app_navigator.dart';
import '../../features/patient/presentation/pages/notifications_page.dart';
import '../../features/patient/presentation/pages/patient_home_page.dart';
import '../../features/patient/presentation/pages/queue_tracking_page.dart';

class NotificationTapRouter {
  NotificationTapRouter._();

  static final instance = NotificationTapRouter._();

  final List<Map<String, String?>> _pendingLaunches = [];
  final Map<String, DateTime> _recentLaunches = {};
  bool _flushScheduled = false;

  Future<void> handleRemoteMessage(RemoteMessage message) {
    return handleData(
      message.data.map((key, value) => MapEntry(key, value?.toString())),
    );
  }

  Future<void> handleLocalNotificationResponse(
    NotificationResponse response,
  ) {
    return handlePayload(response.payload);
  }

  Future<void> handleLaunchDetails(
    NotificationAppLaunchDetails? launchDetails,
  ) async {
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp != true || response == null) {
      return;
    }
    await handleLocalNotificationResponse(response);
  }

  Future<void> handlePayload(String? payload) async {
    final data = _decodePayload(payload);
    if (data.isEmpty) return;
    await handleData(data);
  }

  Future<void> handleData(Map<String, String?> data) async {
    final route = _resolveRoute(data);
    final launchKey = _launchKey(route, data);
    if (_isDuplicate(launchKey)) return;

    final state = appNavigatorKey.currentState;
    if (state == null) {
      _pendingLaunches.add({...data, 'route': route});
      _scheduleFlush();
      return;
    }

    await _openRoute(state.context, route, data);
  }

  void flushPending() {
    final state = appNavigatorKey.currentState;
    if (state == null || _pendingLaunches.isEmpty) return;

    final launches = List<Map<String, String?>>.from(_pendingLaunches);
    _pendingLaunches.clear();
    unawaited(_flushLaunches(state.context, launches));
  }

  Future<void> _flushLaunches(
    BuildContext context,
    List<Map<String, String?>> launches,
  ) async {
    for (final data in launches) {
      final route = _resolveRoute(data);
      await _openRoute(context, route, data);
    }
  }

  Future<void> _openRoute(
    BuildContext context,
    String route,
    Map<String, String?> data,
  ) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => _pageForRoute(route, data),
      ),
    );
  }

  Widget _pageForRoute(String route, Map<String, String?> data) {
    switch (route) {
      case 'queue_tracking':
        return const QueueTrackingPage();
      case 'home':
        return const PatientHomePage();
      case 'notifications':
      default:
        return const NotificationsPage();
    }
  }

  String _resolveRoute(Map<String, String?> data) {
    final explicitRoute = _cleanValue(data['route']);
    if (explicitRoute != null) return explicitRoute;

    final eventType = _cleanValue(data['event_type']) ?? _cleanValue(data['type']);
    return notificationRouteForType(eventType);
  }

  Map<String, String?> _decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return const {};
      return decoded.map((key, value) => MapEntry(key, value?.toString()));
    } catch (_) {
      return const {};
    }
  }

  String _launchKey(String route, Map<String, String?> data) {
    final notificationId = _cleanValue(data['notification_id']);
    if (notificationId != null) return 'notification:$notificationId';

    final ticketId = _cleanValue(data['ticket_id']);
    final queueCode = _cleanValue(data['queue_code']);
    if (ticketId != null) return '$route:ticket:$ticketId';
    if (queueCode != null) return '$route:queue:$queueCode';
    return '$route:${data.hashCode}';
  }

  bool _isDuplicate(String key) {
    final now = DateTime.now();
    _recentLaunches.removeWhere(
      (_, openedAt) => now.difference(openedAt) > const Duration(seconds: 5),
    );
    if (_recentLaunches.containsKey(key)) return true;
    _recentLaunches[key] = now;
    return false;
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushScheduled = false;
      flushPending();
    });
  }

  String? _cleanValue(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

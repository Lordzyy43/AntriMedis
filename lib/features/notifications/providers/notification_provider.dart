import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/patient_notification.dart';
import '../data/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;

  List<PatientNotification> _notifications = [];
  RealtimeChannel? _channel;
  bool _isLoading = false;
  String? _error;

  List<PatientNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _repository.fetchMyNotifications();
      _subscribe();
    } catch (_) {
      _error = 'Gagal memuat notifikasi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    _notifications = await _repository.fetchMyNotifications();
    _subscribe();
    notifyListeners();
  }

  void clear() {
    final channel = _channel;
    if (channel != null) {
      _repository.unsubscribe(channel);
    }
    _channel = null;
    _notifications = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _subscribe() {
    if (_channel != null) return;
    _channel = _repository.subscribeToMyNotifications(onChanged: _reloadSilent);
  }

  Future<void> _reloadSilent() async {
    try {
      _notifications = await _repository.fetchMyNotifications();
      _error = null;
      notifyListeners();
    } catch (_) {
      // Realtime notification refresh is best-effort.
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      _repository.unsubscribe(channel);
    }
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../data/models/patient_notification.dart';
import '../data/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;

  List<PatientNotification> _notifications = [];
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
    notifyListeners();
  }

  void clear() {
    _notifications = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

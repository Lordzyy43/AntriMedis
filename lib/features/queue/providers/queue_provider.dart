import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/notification_service.dart';
import '../data/models/queue_ticket_detail.dart';
import '../data/models/schedule_availability.dart';
import '../data/queue_repository.dart';

class QueueProvider extends ChangeNotifier {
  QueueProvider(this._repository);

  final QueueRepository _repository;

  List<ScheduleAvailability> _schedules = [];
  QueueTicketDetail? _activeTicket;
  RealtimeChannel? _channel;
  bool _isLoading = false;
  String? _error;
  String? _notifiedTicketId;
  String? _lastTicketStatus;

  List<ScheduleAvailability> get schedules => _schedules;
  QueueTicketDetail? get activeTicket => _activeTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHome() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchActiveTicket(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _activeTicket = results[1] as QueueTicketDetail?;
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _error = null;
    } catch (error) {
      _error = 'Gagal memuat data antrean.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTicket(ScheduleAvailability schedule) async {
    _setLoading(true);
    try {
      _activeTicket = await _repository.createTicket(schedule.queueSessionId);
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _error = null;
      return true;
    } on PostgrestException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'Gagal mengambil nomor antrean.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshActiveTicket() async {
    final ticketId = _activeTicket?.ticketId;
    if (ticketId == null) return;
    try {
      final previousStatus = _activeTicket?.status;
      _activeTicket = await _repository.fetchTicketDetail(ticketId);
      final ticket = _activeTicket;
      if (ticket != null) {
        await _maybeNotify(ticket, previousStatus ?? _lastTicketStatus);
        _lastTicketStatus = ticket.status;
      }
      notifyListeners();
    } catch (_) {
      // Realtime refresh failures are non-blocking; manual refresh still works.
    }
  }

  Future<void> clearForSignOut() async {
    final channel = _channel;
    if (channel != null) {
      await _repository.unsubscribe(channel);
    }
    _channel = null;
    _schedules = [];
    _activeTicket = null;
    _error = null;
    _lastTicketStatus = null;
    _notifiedTicketId = null;
    notifyListeners();
  }

  Future<void> _maybeNotify(
    QueueTicketDetail ticket,
    String? previousStatus,
  ) async {
    if (ticket.remainingBeforeMe <= 3 &&
        ticket.status == 'waiting' &&
        _notifiedTicketId != ticket.ticketId) {
      _notifiedTicketId = ticket.ticketId;
      await NotificationService.instance.showQueueNear(
        queueCode: ticket.queueCode,
        remaining: ticket.remainingBeforeMe,
      );
    }

    if (previousStatus == ticket.status) return;

    switch (ticket.status) {
      case 'called':
        await NotificationService.instance.showQueueCalled(
          queueCode: ticket.queueCode,
        );
      case 'skipped':
        await NotificationService.instance.showQueueSkipped(
          queueCode: ticket.queueCode,
        );
      case 'cancelled':
        await NotificationService.instance.showQueueCancelled(
          queueCode: ticket.queueCode,
        );
    }
  }

  void _subscribeActiveTicket() {
    final ticket = _activeTicket;
    final previous = _channel;
    if (previous != null) {
      _repository.unsubscribe(previous);
    }
    _channel = null;
    if (ticket == null || !ticket.isActive) return;
    _channel = _repository.subscribeToTicket(
      ticket: ticket,
      onChanged: refreshActiveTicket,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
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

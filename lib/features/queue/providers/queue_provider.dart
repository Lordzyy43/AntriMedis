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
  List<QueueTicketDetail> _tickets = [];
  QueueTicketDetail? _activeTicket;
  RealtimeChannel? _channel;
  bool _isLoading = false;
  String? _error;
  String? _notifiedTicketId;
  String? _lastTicketStatus;

  List<ScheduleAvailability> get schedules => _schedules;
  List<QueueTicketDetail> get tickets => _tickets;
  List<QueueTicketDetail> get historyTickets =>
      _tickets.where((ticket) => !ticket.isActive).toList();
  QueueTicketDetail? get activeTicket => _activeTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHome() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchActiveTicket(),
        _repository.fetchMyTickets(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _activeTicket = results[1] as QueueTicketDetail?;
      _tickets = results[2] as List<QueueTicketDetail>;
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
      _tickets = await _repository.fetchMyTickets();
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _error = null;
      return true;
    } on PostgrestException catch (error) {
      _error = _friendlyQueueError(error.message);
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
      _tickets = await _repository.fetchMyTickets();
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
    _tickets = [];
    _activeTicket = null;
    _error = null;
    _lastTicketStatus = null;
    _notifiedTicketId = null;
    notifyListeners();
  }

  Future<void> refreshTickets() async {
    try {
      _tickets = await _repository.fetchMyTickets();
      _activeTicket = await _repository.fetchActiveTicket();
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _error = null;
      notifyListeners();
    } catch (_) {
      _error = 'Gagal memuat data antrean.';
      notifyListeners();
    }
  }

  Future<bool> cancelActiveTicket() async {
    final ticket = _activeTicket;
    if (ticket == null || !ticket.canCancel) return false;

    _setLoading(true);
    try {
      await _repository.cancelTicket(ticket.ticketId);
      _activeTicket = null;
      _tickets = await _repository.fetchMyTickets();
      _subscribeActiveTicket();
      _error = null;
      return true;
    } on PostgrestException catch (error) {
      _error = _friendlyQueueError(error.message);
      return false;
    } catch (_) {
      _error = 'Gagal membatalkan antrean.';
      return false;
    } finally {
      _setLoading(false);
    }
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

  String _friendlyQueueError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already has active queue')) {
      return 'Anda sudah memiliki antrean aktif hari ini.';
    }
    if (lower.contains('quota is full')) {
      return 'Kuota antrean jadwal ini sudah penuh.';
    }
    if (lower.contains('session is closed')) {
      return 'Sesi antrean sudah ditutup oleh klinik.';
    }
    if (lower.contains('only waiting queue can be cancelled')) {
      return 'Antrean sudah diproses petugas sehingga tidak bisa dibatalkan dari aplikasi.';
    }
    if (lower.contains('invalid queue status transition')) {
      return 'Status antrean sudah berubah. Silakan muat ulang data.';
    }
    if (lower.contains('schedule is not open')) {
      return 'Jadwal praktik belum dibuka atau sudah ditutup.';
    }
    if (lower.contains('not found')) {
      return 'Data antrean tidak ditemukan. Silakan muat ulang.';
    }
    if (lower.contains('row-level security') ||
        lower.contains('violates row-level')) {
      return 'Akses data antrean ditolak oleh policy Supabase.';
    }
    return message;
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

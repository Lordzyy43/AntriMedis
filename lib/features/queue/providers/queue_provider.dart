import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/app_logger.dart';
import '../../../core/services/notification_service.dart';
import '../data/models/polyclinic_option.dart';
import '../data/models/queue_ticket_detail.dart';
import '../data/models/queue_ticket_timeline_item.dart';
import '../data/models/schedule_availability.dart';
import '../data/queue_repository.dart';

class QueueProvider extends ChangeNotifier {
  QueueProvider(this._repository);

  final QueueRepository _repository;

  List<ScheduleAvailability> _schedules = [];
  List<PolyclinicOption> _polyclinics = [];
  List<QueueTicketDetail> _tickets = [];
  QueueTicketDetail? _activeTicket;
  QueueTicketDetail? _recentResolvedTicket;
  RealtimeChannel? _activeTicketChannel;
  RealtimeChannel? _scheduleFeedChannel;
  Timer? _scheduleRefreshDebounce;
  Timer? _activeTicketPollTimer;
  Timer? _schedulePollTimer;
  bool _isLoading = false;
  bool _isRefreshingActiveTicket = false;
  bool _isRefreshingSchedules = false;
  String? _error;
  String? _lastNearNotificationKey;
  String? _lastNearVibrationKey;
  String? _lastTicketStatus;
  DateTime? _lastScheduleSyncedAt;

  List<ScheduleAvailability> get schedules => _schedules;
  List<PolyclinicOption> get polyclinics => _polyclinics;
  List<QueueTicketDetail> get tickets => _tickets;
  List<QueueTicketDetail> get historyTickets =>
      _tickets.where((ticket) => !ticket.isActive).toList();
  QueueTicketDetail? get activeTicket => _activeTicket;
  QueueTicketDetail? get trackingTicket =>
      _activeTicket ?? _recentResolvedTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isScheduleRealtimeActive => _scheduleFeedChannel != null;
  DateTime? get lastScheduleSyncedAt => _lastScheduleSyncedAt;

  Future<void> loadHome() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchPolyclinics(),
        _repository.fetchActiveTicket(),
        _repository.fetchMyTickets(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _polyclinics = results[1] as List<PolyclinicOption>;
      _activeTicket = results[2] as QueueTicketDetail?;
      _recentResolvedTicket = null;
      _tickets = results[3] as List<QueueTicketDetail>;
      _lastScheduleSyncedAt = DateTime.now();
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _subscribeScheduleFeed();
      _error = null;
    } catch (error, stackTrace) {
      AppLogger.queue('loadHome failed', error: error, stackTrace: stackTrace);
      _error = 'Gagal memuat data antrean.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTicket(ScheduleAvailability schedule) async {
    final queueSessionId = schedule.queueSessionId;
    if (!schedule.canTakeQueue || queueSessionId == null) {
      _error = schedule.availabilityReason;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _activeTicket = await _repository.createTicket(queueSessionId);
      _recentResolvedTicket = null;
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchPolyclinics(),
        _repository.fetchMyTickets(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _polyclinics = results[1] as List<PolyclinicOption>;
      _tickets = results[2] as List<QueueTicketDetail>;
      _lastScheduleSyncedAt = DateTime.now();
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _subscribeScheduleFeed();
      _error = null;
      return true;
    } on PostgrestException catch (error) {
      AppLogger.queue(
        'createTicket RPC rejected',
        error: error,
        context: {'queue_session_id': queueSessionId},
      );
      _error = _friendlyQueueError(error.message);
      return false;
    } catch (error, stackTrace) {
      AppLogger.queue(
        'createTicket failed',
        error: error,
        stackTrace: stackTrace,
        context: {'queue_session_id': queueSessionId},
      );
      _error = 'Gagal mengambil nomor antrean.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshActiveTicket() async {
    final ticketId = _activeTicket?.ticketId;
    if (ticketId == null) return;
    if (_isRefreshingActiveTicket) return;
    _isRefreshingActiveTicket = true;
    try {
      final previousStatus = _activeTicket?.status;
      final ticket = await _repository.fetchTicketDetail(ticketId);
      await _maybeNotify(ticket, previousStatus ?? _lastTicketStatus);
      _lastTicketStatus = ticket.status;
      if (ticket.isActive) {
        _activeTicket = ticket;
        _recentResolvedTicket = null;
      } else {
        _activeTicket = null;
        _recentResolvedTicket = ticket;
      }
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchMyTickets(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _tickets = results[1] as List<QueueTicketDetail>;
      _lastScheduleSyncedAt = DateTime.now();
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.queue(
        'active ticket realtime refresh failed',
        error: error,
        stackTrace: stackTrace,
        context: {'ticket_id': ticketId},
      );
      // Realtime refresh failures are non-blocking; manual refresh still works.
    } finally {
      _isRefreshingActiveTicket = false;
    }
  }

  Future<void> clearForSignOut() async {
    _scheduleRefreshDebounce?.cancel();
    _activeTicketPollTimer?.cancel();
    _schedulePollTimer?.cancel();
    final activeTicketChannel = _activeTicketChannel;
    if (activeTicketChannel != null) {
      await _repository.unsubscribe(activeTicketChannel);
    }
    final scheduleFeedChannel = _scheduleFeedChannel;
    if (scheduleFeedChannel != null) {
      await _repository.unsubscribe(scheduleFeedChannel);
    }
    _activeTicketChannel = null;
    _scheduleFeedChannel = null;
    _activeTicketPollTimer = null;
    _schedulePollTimer = null;
    _schedules = [];
    _polyclinics = [];
    _tickets = [];
    _activeTicket = null;
    _recentResolvedTicket = null;
    _error = null;
    _lastTicketStatus = null;
    _lastNearNotificationKey = null;
    _lastNearVibrationKey = null;
    _lastScheduleSyncedAt = null;
    _isRefreshingActiveTicket = false;
    _isRefreshingSchedules = false;
    notifyListeners();
  }

  Future<void> refreshTickets() async {
    try {
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchPolyclinics(),
        _repository.fetchMyTickets(),
        _repository.fetchActiveTicket(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _polyclinics = results[1] as List<PolyclinicOption>;
      _tickets = results[2] as List<QueueTicketDetail>;
      _activeTicket = results[3] as QueueTicketDetail?;
      _recentResolvedTicket = null;
      _lastScheduleSyncedAt = DateTime.now();
      _lastTicketStatus = _activeTicket?.status;
      _subscribeActiveTicket();
      _subscribeScheduleFeed();
      _error = null;
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.queue(
        'refreshTickets failed',
        error: error,
        stackTrace: stackTrace,
      );
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
      _recentResolvedTicket = null;
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchPolyclinics(),
        _repository.fetchMyTickets(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _polyclinics = results[1] as List<PolyclinicOption>;
      _tickets = results[2] as List<QueueTicketDetail>;
      _lastScheduleSyncedAt = DateTime.now();
      _subscribeActiveTicket();
      _subscribeScheduleFeed();
      _error = null;
      return true;
    } on PostgrestException catch (error) {
      AppLogger.queue(
        'cancelActiveTicket RPC rejected',
        error: error,
        context: {'ticket_id': ticket.ticketId},
      );
      _error = _friendlyQueueError(error.message);
      return false;
    } catch (error, stackTrace) {
      AppLogger.queue(
        'cancelActiveTicket failed',
        error: error,
        stackTrace: stackTrace,
        context: {'ticket_id': ticket.ticketId},
      );
      _error = 'Gagal membatalkan antrean.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<QueueTicketTimelineItem>> fetchTicketTimeline(String ticketId) {
    return _repository.fetchTicketTimeline(ticketId);
  }

  Future<QueueTicketDetail> fetchTicketDetail(String ticketId) {
    return _repository.fetchTicketDetail(ticketId);
  }

  RealtimeChannel subscribeToTicketEvents({
    required String ticketId,
    required void Function() onChanged,
  }) {
    return _repository.subscribeToTicketEvents(
      ticketId: ticketId,
      onChanged: onChanged,
    );
  }

  Future<void> unsubscribe(RealtimeChannel channel) {
    return _repository.unsubscribe(channel);
  }

  Future<void> refreshSchedules() async {
    if (_isRefreshingSchedules) return;
    _isRefreshingSchedules = true;
    try {
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchPolyclinics(),
      ]);
      _schedules = results[0] as List<ScheduleAvailability>;
      _polyclinics = results[1] as List<PolyclinicOption>;
      _lastScheduleSyncedAt = DateTime.now();
      _error = null;
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.queue(
        'schedule realtime refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      // Schedule realtime refresh is best-effort; manual refresh still reports errors.
    } finally {
      _isRefreshingSchedules = false;
    }
  }

  Future<void> _maybeNotify(
    QueueTicketDetail ticket,
    String? previousStatus,
  ) async {
    final nearKey = '${ticket.ticketId}:${ticket.remainingBeforeMe}';
    if (ticket.remainingBeforeMe > 0 &&
        ticket.remainingBeforeMe <= 3 &&
        ticket.status == 'waiting' &&
        _lastNearNotificationKey != nearKey) {
      _lastNearNotificationKey = nearKey;
      await _vibrateIfSupported(nearKey);
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
      case 'missed':
        await NotificationService.instance.showQueueMissed(
          queueCode: ticket.queueCode,
        );
      case 'cancelled':
        await NotificationService.instance.showQueueCancelled(
          queueCode: ticket.queueCode,
        );
      case 'expired':
        await NotificationService.instance.showQueueExpired(
          queueCode: ticket.queueCode,
        );
    }
  }

  Future<void> _vibrateIfSupported(String key) async {
    if (kIsWeb || _lastNearVibrationKey == key) return;

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      _lastNearVibrationKey = key;
      await HapticFeedback.mediumImpact();
    } catch (error, stackTrace) {
      AppLogger.queue(
        'queue vibration failed',
        error: error,
        stackTrace: stackTrace,
        context: {'key': key},
      );
    }
  }

  void _subscribeActiveTicket() {
    final ticket = _activeTicket;
    final previous = _activeTicketChannel;
    if (previous != null) {
      _repository.unsubscribe(previous);
    }
    _activeTicketChannel = null;
    _activeTicketPollTimer?.cancel();
    _activeTicketPollTimer = null;
    if (ticket == null || !ticket.isActive) return;
    _activeTicketChannel = _repository.subscribeToTicket(
      ticket: ticket,
      onChanged: refreshActiveTicket,
    );
    _activeTicketPollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refreshActiveTicket(),
    );
  }

  void _subscribeScheduleFeed() {
    if (_scheduleFeedChannel != null) {
      _startSchedulePollFallback();
      return;
    }
    _scheduleFeedChannel = _repository.subscribeToScheduleFeed(
      onChanged: _scheduleRealtimeChanged,
    );
    _startSchedulePollFallback();
  }

  void _startSchedulePollFallback() {
    _schedulePollTimer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => refreshSchedules(),
    );
  }

  void _scheduleRealtimeChanged() {
    _scheduleRefreshDebounce?.cancel();
    _scheduleRefreshDebounce = Timer(
      const Duration(milliseconds: 450),
      refreshSchedules,
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
    if (lower.contains('schedule date has passed') ||
        lower.contains('during schedule time')) {
      return 'Jam praktik sudah selesai. Antrean hanya bisa diambil pada hari layanan sebelum jam praktik berakhir.';
    }
    if (lower.contains('service date')) {
      return 'Antrean hanya bisa diambil pada tanggal layanan.';
    }
    if (lower.contains('has not started')) {
      return 'Jadwal praktik belum mulai. Nomor antrean hari ini tetap bisa diambil jika sesi sudah dibuka klinik.';
    }
    if (lower.contains('branch is not active') ||
        lower.contains('polyclinic is not active') ||
        lower.contains('doctor is not active')) {
      return 'Layanan ini sedang tidak aktif. Silakan pilih jadwal lain.';
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
      return 'Akses data antrean belum tersedia untuk akun ini. Silakan masuk ulang atau hubungi petugas.';
    }
    return message;
  }

  @override
  void dispose() {
    _scheduleRefreshDebounce?.cancel();
    _activeTicketPollTimer?.cancel();
    _schedulePollTimer?.cancel();
    final activeTicketChannel = _activeTicketChannel;
    if (activeTicketChannel != null) {
      _repository.unsubscribe(activeTicketChannel);
    }
    final scheduleFeedChannel = _scheduleFeedChannel;
    if (scheduleFeedChannel != null) {
      _repository.unsubscribe(scheduleFeedChannel);
    }
    super.dispose();
  }
}

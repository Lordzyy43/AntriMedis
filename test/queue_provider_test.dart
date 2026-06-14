import 'package:antrimedis/features/queue/data/models/polyclinic_option.dart';
import 'package:antrimedis/features/queue/data/models/queue_ticket_detail.dart';
import 'package:antrimedis/features/queue/data/models/schedule_availability.dart';
import 'package:antrimedis/features/queue/data/queue_repository.dart';
import 'package:antrimedis/features/queue/providers/queue_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'refreshActiveTicket clears realtime subscription when ticket resolves',
    () async {
      final activeTicket = _ticket(status: 'waiting');
      final resolvedTicket = _ticket(status: 'completed');
      final repository = _FakeQueueRepository(
        activeTicket: activeTicket,
        ticketDetail: resolvedTicket,
      );
      final provider = QueueProvider(repository);

      await provider.loadHome();

      expect(provider.activeTicket, activeTicket);
      expect(repository.subscribeCount, 1);

      await provider.refreshActiveTicket();

      expect(provider.activeTicket, isNull);
      expect(provider.trackingTicket, resolvedTicket);
      expect(repository.unsubscribeCount, 1);
      expect(repository.subscribeCount, 1);
    },
  );
}

class _FakeQueueRepository extends QueueRepository {
  _FakeQueueRepository({required this.activeTicket, required this.ticketDetail})
    : super(SupabaseClient('https://example.supabase.co', 'anon-key'));

  final QueueTicketDetail activeTicket;
  final QueueTicketDetail ticketDetail;
  final _channel = SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
  ).channel('fake-ticket');

  int subscribeCount = 0;
  int unsubscribeCount = 0;

  @override
  Future<List<ScheduleAvailability>> fetchSchedules() async => const [];

  @override
  Future<List<PolyclinicOption>> fetchPolyclinics() async => const [];

  @override
  Future<QueueTicketDetail?> fetchActiveTicket() async => activeTicket;

  @override
  Future<List<QueueTicketDetail>> fetchMyTickets({int limit = 30}) async => [
    ticketDetail,
  ];

  @override
  Future<QueueTicketDetail> fetchTicketDetail(String ticketId) async {
    expect(ticketId, activeTicket.ticketId);
    return ticketDetail;
  }

  @override
  RealtimeChannel subscribeToTicket({
    required QueueTicketDetail ticket,
    required void Function() onChanged,
  }) {
    subscribeCount += 1;
    return _channel;
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {
    expect(channel, _channel);
    unsubscribeCount += 1;
  }
}

QueueTicketDetail _ticket({required String status}) {
  final now = DateTime(2026, 6, 14, 9);
  return QueueTicketDetail(
    ticketId: 'ticket-1',
    queueSessionId: 'session-1',
    queueNumber: 5,
    queueCode: 'A005',
    status: status,
    statusReason: null,
    cancelReason: null,
    estimatedWaitMinutes: 20,
    remainingBeforeMeCount: 2,
    createdAt: now,
    calledAt: null,
    servingStartedAt: null,
    completedAt: status == 'completed' ? now : null,
    skippedAt: null,
    cancelledAt: null,
    expiredAt: null,
    currentNumber: 2,
    lastNumber: 5,
    scheduleDate: DateTime(2026, 6, 14),
    startTime: '09:00',
    endTime: '12:00',
    branchName: 'Cabang Utama',
    branchAddress: 'Jl. Sehat No. 1',
    polyclinicName: 'Umum',
    doctorName: 'dr. Antri',
    specialization: 'Dokter Umum',
  );
}

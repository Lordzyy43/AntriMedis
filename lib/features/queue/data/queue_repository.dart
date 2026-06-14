import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/app_logger.dart';
import 'models/polyclinic_option.dart';
import 'models/queue_ticket_detail.dart';
import 'models/queue_ticket_timeline_item.dart';
import 'models/schedule_availability.dart';

class QueueRepository {
  const QueueRepository(this._client);

  final SupabaseClient _client;

  Future<List<ScheduleAvailability>> fetchSchedules() async {
    final data = await _client
        .from('v_schedule_availability')
        .select()
        .eq('status', 'open')
        .eq('is_current_local_date', true)
        .order('start_time', ascending: true);

    return data
        .map<ScheduleAvailability>((row) => ScheduleAvailability.fromJson(row))
        .toList();
  }

  Future<List<PolyclinicOption>> fetchPolyclinics() async {
    final data = await _client
        .from('polyclinics')
        .select('id, name, is_active')
        .order('name', ascending: true);

    return data
        .map<PolyclinicOption>((row) => PolyclinicOption.fromJson(row))
        .toList();
  }

  Future<QueueTicketDetail?> fetchActiveTicket() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('v_queue_ticket_details')
        .select()
        .eq('patient_id', userId)
        .inFilter('status', ['waiting', 'called', 'serving', 'missed'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return QueueTicketDetail.fromJson(data);
  }

  Future<List<QueueTicketDetail>> fetchMyTickets({int limit = 30}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('v_queue_ticket_details')
        .select()
        .eq('patient_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return data
        .map<QueueTicketDetail>((row) => QueueTicketDetail.fromJson(row))
        .toList();
  }

  Future<QueueTicketDetail> createTicket(String queueSessionId) async {
    try {
      final ticket = await _client.rpc<Map<String, dynamic>>(
        'create_queue_ticket',
        params: {'p_queue_session_id': queueSessionId},
      );
      return fetchTicketDetail(ticket['id'] as String);
    } catch (error, stackTrace) {
      AppLogger.queue(
        'create_queue_ticket failed',
        error: error,
        stackTrace: stackTrace,
        context: {'queue_session_id': queueSessionId},
      );
      rethrow;
    }
  }

  Future<QueueTicketDetail> fetchTicketDetail(String ticketId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Unauthorized');
    }

    final data = await _client
        .from('v_queue_ticket_details')
        .select()
        .eq('ticket_id', ticketId)
        .eq('patient_id', userId)
        .single();

    return QueueTicketDetail.fromJson(data);
  }

  Future<List<QueueTicketTimelineItem>> fetchTicketTimeline(
    String ticketId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('v_queue_ticket_timeline')
        .select()
        .eq('queue_ticket_id', ticketId)
        .eq('patient_id', userId)
        .order('created_at', ascending: true);

    return data
        .map<QueueTicketTimelineItem>(
          (row) => QueueTicketTimelineItem.fromJson(row),
        )
        .toList();
  }

  Future<QueueTicketDetail> cancelTicket(String ticketId) async {
    try {
      final ticket = await _client.rpc<Map<String, dynamic>>(
        'cancel_my_ticket',
        params: {
          'p_ticket_id': ticketId,
          'p_message': 'Dibatalkan oleh pasien',
        },
      );
      return fetchTicketDetail(ticket['id'] as String);
    } catch (error, stackTrace) {
      AppLogger.queue(
        'cancel_my_ticket failed',
        error: error,
        stackTrace: stackTrace,
        context: {'ticket_id': ticketId},
      );
      rethrow;
    }
  }

  RealtimeChannel subscribeToTicket({
    required QueueTicketDetail ticket,
    required void Function() onChanged,
  }) {
    final channel = _client.channel('ticket:${ticket.ticketId}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: ticket.ticketId,
          ),
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: ticket.queueSessionId,
          ),
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'queue_ticket_id',
            value: ticket.ticketId,
          ),
          callback: (_) => onChanged(),
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToTicketEvents({
    required String ticketId,
    required void Function() onChanged,
  }) {
    final channel = _client.channel('ticket-events:$ticketId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: ticketId,
          ),
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'queue_ticket_id',
            value: ticketId,
          ),
          callback: (_) => onChanged(),
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToScheduleFeed({
    required void Function() onChanged,
  }) {
    final channel = _client.channel('patient:schedule-feed');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doctor_schedules',
          callback: (_) => onChanged(),
        )
        .subscribe();
    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel channel) {
    return _client.removeChannel(channel);
  }
}

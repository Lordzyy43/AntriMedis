import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/queue_ticket_detail.dart';
import 'models/schedule_availability.dart';

class QueueRepository {
  const QueueRepository(this._client);

  final SupabaseClient _client;

  Future<List<ScheduleAvailability>> fetchSchedules() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = await _client
        .from('v_schedule_availability')
        .select()
        .eq('status', 'open')
        .eq('schedule_date', today)
        .gt('remaining_quota', 0)
        .order('start_time', ascending: true);

    return data
        .map<ScheduleAvailability>((row) => ScheduleAvailability.fromJson(row))
        .toList();
  }

  Future<QueueTicketDetail?> fetchActiveTicket() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('v_queue_ticket_details')
        .select()
        .eq('patient_id', userId)
        .inFilter('status', ['waiting', 'called', 'serving'])
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
    final ticket = await _client.rpc<Map<String, dynamic>>(
      'create_queue_ticket',
      params: {'p_queue_session_id': queueSessionId},
    );
    return fetchTicketDetail(ticket['id'] as String);
  }

  Future<QueueTicketDetail> fetchTicketDetail(String ticketId) async {
    final data = await _client
        .from('v_queue_ticket_details')
        .select()
        .eq('ticket_id', ticketId)
        .single();

    return QueueTicketDetail.fromJson(data);
  }

  Future<QueueTicketDetail> cancelTicket(String ticketId) async {
    final ticket = await _client.rpc<Map<String, dynamic>>(
      'cancel_my_ticket',
      params: {'p_ticket_id': ticketId, 'p_message': 'Dibatalkan oleh pasien'},
    );
    return fetchTicketDetail(ticket['id'] as String);
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
        .subscribe();
    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel channel) {
    return _client.removeChannel(channel);
  }
}

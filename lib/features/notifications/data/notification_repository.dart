import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/patient_notification.dart';

class NotificationRepository {
  const NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<PatientNotification>> fetchMyNotifications({
    int limit = 40,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('notifications')
        .select('id, type, title, body, is_read, created_at, read_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return data
        .map<PatientNotification>((row) => PatientNotification.fromJson(row))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  RealtimeChannel subscribeToMyNotifications({
    required void Function() onChanged,
  }) {
    final userId = _client.auth.currentUser?.id;
    final channel = _client.channel('notifications:${userId ?? 'guest'}');
    if (userId == null) return channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
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

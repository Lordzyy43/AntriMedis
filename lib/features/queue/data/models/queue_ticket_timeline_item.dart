class QueueTicketTimelineItem {
  const QueueTicketTimelineItem({
    required this.eventId,
    required this.queueTicketId,
    required this.actorId,
    required this.actorName,
    required this.actorType,
    required this.previousStatus,
    required this.newStatus,
    required this.message,
    required this.createdAt,
  });

  final String eventId;
  final String queueTicketId;
  final String? actorId;
  final String? actorName;
  final String actorType;
  final String? previousStatus;
  final String newStatus;
  final String? message;
  final DateTime createdAt;

  factory QueueTicketTimelineItem.fromJson(Map<String, dynamic> json) {
    return QueueTicketTimelineItem(
      eventId: json['event_id'] as String,
      queueTicketId: json['queue_ticket_id'] as String,
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String?,
      actorType: json['actor_type'] as String? ?? 'system',
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

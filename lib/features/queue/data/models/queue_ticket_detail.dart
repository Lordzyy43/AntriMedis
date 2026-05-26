class QueueTicketDetail {
  const QueueTicketDetail({
    required this.ticketId,
    required this.queueSessionId,
    required this.queueNumber,
    required this.queueCode,
    required this.status,
    required this.estimatedWaitMinutes,
    required this.currentNumber,
    required this.lastNumber,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.branchName,
    required this.polyclinicName,
    required this.doctorName,
    required this.specialization,
  });

  final String ticketId;
  final String queueSessionId;
  final int queueNumber;
  final String queueCode;
  final String status;
  final int estimatedWaitMinutes;
  final int currentNumber;
  final int lastNumber;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final String branchName;
  final String polyclinicName;
  final String doctorName;
  final String? specialization;

  int get remainingBeforeMe {
    return (queueNumber - currentNumber - 1).clamp(0, queueNumber);
  }

  double get progress {
    if (queueNumber <= 0) return 0;
    return (currentNumber / queueNumber).clamp(0, 1).toDouble();
  }

  bool get isActive => ['waiting', 'called', 'serving'].contains(status);

  factory QueueTicketDetail.fromJson(Map<String, dynamic> json) {
    return QueueTicketDetail(
      ticketId: json['ticket_id'] as String,
      queueSessionId: json['queue_session_id'] as String,
      queueNumber: json['queue_number'] as int,
      queueCode: json['queue_code'] as String,
      status: json['status'] as String,
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int,
      currentNumber: json['current_number'] as int,
      lastNumber: json['last_number'] as int,
      scheduleDate: DateTime.parse(json['schedule_date'] as String),
      startTime: (json['start_time'] as String).substring(0, 5),
      endTime: (json['end_time'] as String).substring(0, 5),
      branchName: json['branch_name'] as String,
      polyclinicName: json['polyclinic_name'] as String,
      doctorName: json['doctor_name'] as String,
      specialization: json['specialization'] as String?,
    );
  }
}

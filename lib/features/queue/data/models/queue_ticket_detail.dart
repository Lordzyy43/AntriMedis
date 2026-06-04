class QueueTicketDetail {
  const QueueTicketDetail({
    required this.ticketId,
    required this.queueSessionId,
    required this.queueNumber,
    required this.queueCode,
    required this.status,
    required this.statusReason,
    required this.cancelReason,
    required this.estimatedWaitMinutes,
    required this.remainingBeforeMeCount,
    required this.createdAt,
    required this.calledAt,
    required this.servingStartedAt,
    required this.completedAt,
    required this.skippedAt,
    required this.cancelledAt,
    required this.expiredAt,
    required this.currentNumber,
    required this.lastNumber,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.branchName,
    required this.branchAddress,
    required this.polyclinicName,
    required this.doctorName,
    required this.specialization,
  });

  final String ticketId;
  final String queueSessionId;
  final int queueNumber;
  final String queueCode;
  final String status;
  final String? statusReason;
  final String? cancelReason;
  final int estimatedWaitMinutes;
  final int? remainingBeforeMeCount;
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? servingStartedAt;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;
  final int currentNumber;
  final int lastNumber;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final String branchName;
  final String? branchAddress;
  final String polyclinicName;
  final String doctorName;
  final String? specialization;

  int get remainingBeforeMe {
    final fromBackend = remainingBeforeMeCount;
    if (fromBackend != null) return fromBackend.clamp(0, queueNumber);
    return (queueNumber - currentNumber - 1).clamp(0, queueNumber);
  }

  double get progress {
    if (queueNumber <= 0) return 0;
    return (currentNumber / queueNumber).clamp(0, 1).toDouble();
  }

  bool get isActive =>
      ['waiting', 'called', 'serving', 'missed'].contains(status);
  bool get canCancel => status == 'waiting';
  String get waitEstimateLabel {
    if (status == 'called') return 'Dipanggil';
    if (status == 'serving') return 'Dilayani';
    if (status == 'missed') return 'Panggil ulang';
    if (estimatedWaitMinutes <= 0) return 'Segera';
    return '~ $estimatedWaitMinutes menit';
  }

  String get remainingBeforeMeLabel {
    if (status == 'called') return 'Giliran Anda';
    if (status == 'serving') return 'Dilayani';
    if (status == 'missed') return 'Menunggu panggil ulang';
    if (remainingBeforeMe <= 0) return 'Siap dipanggil';
    return '$remainingBeforeMe antrean lagi';
  }

  factory QueueTicketDetail.fromJson(Map<String, dynamic> json) {
    return QueueTicketDetail(
      ticketId: json['ticket_id'] as String,
      queueSessionId: json['queue_session_id'] as String,
      queueNumber: json['queue_number'] as int,
      queueCode: json['queue_code'] as String,
      status: json['status'] as String,
      statusReason: json['status_reason'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int,
      remainingBeforeMeCount: json['remaining_before_me'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      calledAt: _parseNullableDate(json['called_at']),
      servingStartedAt: _parseNullableDate(json['serving_started_at']),
      completedAt: _parseNullableDate(json['completed_at']),
      skippedAt: _parseNullableDate(json['skipped_at']),
      cancelledAt: _parseNullableDate(json['cancelled_at']),
      expiredAt: _parseNullableDate(json['expired_at']),
      currentNumber: json['current_number'] as int,
      lastNumber: json['last_number'] as int,
      scheduleDate: DateTime.parse(json['schedule_date'] as String),
      startTime: (json['start_time'] as String).substring(0, 5),
      endTime: (json['end_time'] as String).substring(0, 5),
      branchName: json['branch_name'] as String,
      branchAddress: json['branch_address'] as String?,
      polyclinicName: json['polyclinic_name'] as String,
      doctorName: json['doctor_name'] as String,
      specialization: json['specialization'] as String?,
    );
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

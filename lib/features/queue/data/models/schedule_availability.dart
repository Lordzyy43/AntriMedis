class ScheduleAvailability {
  const ScheduleAvailability({
    required this.scheduleId,
    required this.branchName,
    required this.polyclinicName,
    required this.queuePrefix,
    required this.doctorName,
    required this.specialization,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.quotaLimit,
    required this.averageServiceMinutes,
    required this.status,
    required this.queueSessionId,
    required this.currentNumber,
    required this.lastNumber,
    required this.totalTaken,
    required this.remainingQuota,
    required this.isTakeable,
    required this.availabilityReason,
    required this.operationalPhase,
  });

  final String scheduleId;
  final String branchName;
  final String polyclinicName;
  final String queuePrefix;
  final String doctorName;
  final String? specialization;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final int quotaLimit;
  final int averageServiceMinutes;
  final String status;
  final String? queueSessionId;
  final int currentNumber;
  final int lastNumber;
  final int totalTaken;
  final int remainingQuota;
  final bool isTakeable;
  final String availabilityReason;
  final String operationalPhase;

  bool get canTakeQueue => isTakeable && queueSessionId != null;

  int get usedQuota => totalTaken.clamp(0, quotaLimit);

  double get quotaUsageRatio {
    if (quotaLimit <= 0) return 0;
    return (usedQuota / quotaLimit).clamp(0, 1).toDouble();
  }

  bool get isFull => remainingQuota <= 0 || status == 'full';

  bool get hasStarted {
    if (operationalPhase == 'before_start') return false;
    return true;
  }

  bool get hasEnded => operationalPhase == 'ended';

  bool get isBeforeStart => !hasStarted;

  bool get isOperatingNow => hasStarted && !hasEnded;

  String get operationalPhaseLabel {
    if (hasEnded) return 'Selesai hari ini';
    if (isBeforeStart) return 'Belum mulai';
    return 'Sedang buka';
  }

  String get patientGuidance {
    if (canTakeQueue && isBeforeStart) {
      return 'Nomor bisa diambil sekarang. Pemanggilan dimulai pukul $startTime.';
    }
    if (canTakeQueue && isOperatingNow) {
      return 'Sesi sedang berjalan. Ambil nomor dan pantau giliran Anda.';
    }
    if (canTakeQueue) {
      return availabilityReason;
    }
    return availabilityReason;
  }

  String get currentQueueLabel {
    if (currentNumber <= 0) return '-';
    return '$queuePrefix${currentNumber.toString().padLeft(3, '0')}';
  }

  String get lastQueueLabel {
    if (lastNumber <= 0) return '-';
    return '$queuePrefix${lastNumber.toString().padLeft(3, '0')}';
  }

  factory ScheduleAvailability.fromJson(Map<String, dynamic> json) {
    return ScheduleAvailability(
      scheduleId: json['schedule_id'] as String,
      branchName: json['branch_name'] as String,
      polyclinicName: json['polyclinic_name'] as String,
      queuePrefix: json['queue_prefix'] as String,
      doctorName: json['doctor_name'] as String,
      specialization: json['specialization'] as String?,
      scheduleDate: DateTime.parse(json['schedule_date'] as String),
      startTime: (json['start_time'] as String).substring(0, 5),
      endTime: (json['end_time'] as String).substring(0, 5),
      quotaLimit: json['quota_limit'] as int,
      averageServiceMinutes: json['average_service_minutes'] as int,
      status: json['status'] as String,
      queueSessionId: json['queue_session_id'] as String?,
      currentNumber: json['current_number'] as int,
      lastNumber: json['last_number'] as int,
      totalTaken: json['total_taken'] as int,
      remainingQuota: json['remaining_quota'] as int,
      isTakeable: json['is_takeable'] as bool? ?? true,
      availabilityReason:
          json['availability_reason'] as String? ?? 'Siap diambil',
      operationalPhase: json['operational_phase'] as String? ?? 'operating',
    );
  }
}

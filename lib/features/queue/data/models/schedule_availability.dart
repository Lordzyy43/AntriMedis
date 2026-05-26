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
  final String queueSessionId;
  final int currentNumber;
  final int lastNumber;
  final int totalTaken;
  final int remainingQuota;

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
      queueSessionId: json['queue_session_id'] as String,
      currentNumber: json['current_number'] as int,
      lastNumber: json['last_number'] as int,
      totalTaken: json['total_taken'] as int,
      remainingQuota: json['remaining_quota'] as int,
    );
  }
}

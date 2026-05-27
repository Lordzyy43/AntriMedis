class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.birthDate,
    required this.gender,
    required this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? avatarUrl;

  bool get isComplete {
    return fullName.trim().length >= 3 &&
        (phoneNumber?.trim().isNotEmpty ?? false) &&
        (gender?.trim().isNotEmpty ?? false);
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final birthDateValue = json['birth_date'] as String?;
    return PatientProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      birthDate: birthDateValue == null ? null : DateTime.parse(birthDateValue),
      gender: json['gender'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

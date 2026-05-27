class ClinicBranchInfo {
  const ClinicBranchInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.phoneNumber,
    required this.openTime,
    required this.closeTime,
  });

  final String name;
  final String address;
  final String? city;
  final String? province;
  final String? phoneNumber;
  final String? openTime;
  final String? closeTime;

  String get operationalHours {
    if (openTime == null || closeTime == null) {
      return 'Jam buka mengikuti jadwal';
    }
    return '${openTime!.substring(0, 5)}-${closeTime!.substring(0, 5)}';
  }

  String get fullAddress {
    return [
      address,
      if (city != null && city!.isNotEmpty) city,
      if (province != null && province!.isNotEmpty) province,
    ].join(', ');
  }

  factory ClinicBranchInfo.fromJson(Map<String, dynamic> json) {
    return ClinicBranchInfo(
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String?,
      province: json['province'] as String?,
      phoneNumber: json['phone_number'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
    );
  }
}

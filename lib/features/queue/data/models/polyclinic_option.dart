class PolyclinicOption {
  const PolyclinicOption({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  factory PolyclinicOption.fromJson(Map<String, dynamic> json) {
    return PolyclinicOption(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

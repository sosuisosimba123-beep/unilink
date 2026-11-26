class UserModel {
  final String id;
  final String email;
  final String name;
  final String avatar;
  final String role; // 'student', 'lecturer', 'admin'
  final String programme;
  final String groupCode;
  final String registrationNumber;
  final String institution;
  final int year;
  final bool isOnCampus;
  final double latitude;
  final double longitude;
  final DateTime? created;
  final DateTime? updated;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatar,
    required this.role,
    required this.programme,
    required this.groupCode,
    required this.registrationNumber,
    required this.institution,
    required this.year,
    required this.isOnCampus,
    required this.latitude,
    required this.longitude,
    this.created,
    this.updated,
  });

  static double _parseDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    double parsed = 0.0;
    if (val is num) parsed = val.toDouble();
    if (val is String) parsed = double.tryParse(val) ?? fallback;
    if (parsed == 0.0) return fallback; // Treat 0,0 as uninitialized and fallback to campus center
    return parsed;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int parsedYear = 1;
    final y = json['year'];
    if (y is num) parsedYear = y.toInt();
    if (y is String) parsedYear = int.tryParse(y) ?? 1;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      role: json['role'] ?? 'student',
      programme: json['programme'] ?? '',
      groupCode: json['group_code'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      institution: json['institution'] ?? '',
      year: parsedYear,
      isOnCampus: json['is_on_campus'] ?? true,
      latitude: _parseDouble(json['latitude'], -3.3456),
      longitude: _parseDouble(json['longitude'], 37.3312),
      created: json['created'] != null ? DateTime.tryParse(json['created']) : null,
      updated: json['updated'] != null ? DateTime.tryParse(json['updated']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar': avatar,
        'role': role,
        'programme': programme,
        'group_code': groupCode,
        'registration_number': registrationNumber,
        'institution': institution,
        'year': year,
        'is_on_campus': isOnCampus,
        'latitude': latitude,
        'longitude': longitude,
      };

  bool get isStudent => role == 'student';
  bool get isLecturer => role == 'lecturer';
  bool get isAdmin => role == 'admin';
}

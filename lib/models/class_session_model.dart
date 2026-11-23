class ClassSessionModel {
  final String id;
  final String courseCode;
  final String lecturerName;
  final String secretKey;
  final bool isActive;
  final DateTime? created;
  final DateTime? updated;

  ClassSessionModel({
    required this.id,
    required this.courseCode,
    required this.lecturerName,
    required this.secretKey,
    required this.isActive,
    this.created,
    this.updated,
  });

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    return ClassSessionModel(
      id: json['id'] ?? '',
      courseCode: json['course_code'] ?? '',
      lecturerName: json['lecturer_name'] ?? '',
      secretKey: json['secret_key'] ?? '',
      isActive: json['is_active'] ?? false,
      created: json['created'] != null ? DateTime.tryParse(json['created']) : null,
      updated: json['updated'] != null ? DateTime.tryParse(json['updated']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_code': courseCode,
        'lecturer_name': lecturerName,
        'secret_key': secretKey,
        'is_active': isActive,
      };
}

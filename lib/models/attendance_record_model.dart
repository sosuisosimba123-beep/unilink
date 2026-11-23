class AttendanceRecordModel {
  final String id;
  final String sessionId;
  final String studentName;
  final String registrationNumber;
  final DateTime? scannedAt;
  final DateTime? created;

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentName,
    required this.registrationNumber,
    this.scannedAt,
    this.created,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      studentName: json['student_name'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      scannedAt: json['scanned_at'] != null ? DateTime.tryParse(json['scanned_at']) : null,
      created: json['created'] != null ? DateTime.tryParse(json['created']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'student_name': studentName,
        'registration_number': registrationNumber,
      };
}

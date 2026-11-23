class CourseModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String programmeCode;
  final int year;

  CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.programmeCode,
    required this.year,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    int parsedYear = 1;
    final y = json['year'];
    if (y is num) {
      parsedYear = y.toInt();
    } else if (y is String) {
      parsedYear = int.tryParse(y) ?? 1;
    }

    return CourseModel(
      id: json['id'] ?? '',
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      programmeCode: json['programme_code'] ?? '',
      year: parsedYear,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_code': courseCode,
        'course_name': courseName,
        'programme_code': programmeCode,
        'year': year,
      };
}

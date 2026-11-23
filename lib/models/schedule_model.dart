class ScheduleModel {
  final String id;
  final String userId;
  final String courseCode;
  final String courseName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String venue;
  final String instructor;

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.courseCode,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.instructor,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      venue: json['venue'] ?? '',
      instructor: json['instructor'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': userId,
        'course_code': courseCode,
        'course_name': courseName,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'venue': venue,
        'instructor': instructor,
      };
}

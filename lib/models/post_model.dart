import 'user_model.dart';
import 'course_model.dart';

class PostModel {
  final String id;
  final String title;
  final String content;
  final String image;
  final UserModel? author;
  final CourseModel? targetCourse;
  final DateTime? created;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.image,
    this.author,
    this.targetCourse,
    this.created,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    UserModel? authorModel;
    if (json['expand'] != null && json['expand']['author'] != null) {
      authorModel = UserModel.fromJson(json['expand']['author']);
    }

    CourseModel? courseModel;
    if (json['expand'] != null && json['expand']['target_course'] != null) {
      courseModel = CourseModel.fromJson(json['expand']['target_course']);
    }

    return PostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image'] ?? '',
      author: authorModel,
      targetCourse: courseModel,
      created: json['created'] != null ? DateTime.tryParse(json['created']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'image': image,
      };
}

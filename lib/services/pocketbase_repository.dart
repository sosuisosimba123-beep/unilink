import 'pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/post_model.dart';
import '../models/schedule_model.dart';
import '../models/support_ticket_model.dart';
import '../models/user_model.dart';
import '../models/class_session_model.dart';
import '../models/attendance_record_model.dart';
import '../models/course_model.dart';
import '../models/programme_model.dart';
import '../utils/name_matcher.dart';

class PocketBaseRepository {
  final PocketBase pb = pocketBaseService.pb;

  // 1. Fetch student's enrolled course IDs from 'student_enrollment'
  Future<List<String>> getEnrolledCourseIds(String userId) async {
    try {
      final records = await pb.collection('student_enrollment').getList(
        filter: 'student = "$userId"',
      );
      return records.items.map((r) => r.getStringValue('course')).toList();
    } catch (e) {
      return [];
    }
  }

  // 2. Fetch targeted posts (general posts + posts for enrolled courses)
  Future<List<PostModel>> getTargetedPosts(String? userId) async {
    try {
      String filter = 'target_course = ""';
      if (userId != null && userId.isNotEmpty) {
        final courseIds = await getEnrolledCourseIds(userId);
        if (courseIds.isNotEmpty) {
          final courseFilters = courseIds.map((id) => 'target_course = "$id"').join(' || ');
          filter = 'target_course = "" || $courseFilters';
        }
      }

      final records = await pb.collection('posts').getList(
        page: 1,
        perPage: 50,
        sort: '-created',
        filter: filter,
        expand: 'author,target_course',
      );
      return records.items.map((r) => PostModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 3. Fetch schedules filtered by group_code or user
  Future<List<ScheduleModel>> getSchedules({String? userId, String? groupCode}) async {
    try {
      String filter = '';
      final targetGroup = groupCode ?? pocketBaseService.currentUserModel?.groupCode;
      
      if (targetGroup != null && targetGroup.isNotEmpty) {
        filter = 'group_code = "$targetGroup"';
      } else if (userId != null && userId.isNotEmpty) {
        filter = 'user = "$userId"';
      }

      final records = await pb.collection('schedules').getList(
        page: 1,
        perPage: 200,
        sort: 'start_time',
        filter: filter,
      );
      return records.items.map((r) => ScheduleModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 4. Fetch schedules for a specific lecturer using intelligent fuzzy name matching
  Future<List<ScheduleModel>> getLecturerSchedules(String lecturerName) async {
    try {
      final records = await pb.collection('schedules').getList(
        page: 1,
        perPage: 500,
        sort: 'start_time',
      );

      final allSchedules = records.items.map((r) => ScheduleModel.fromJson(r.toJson())).toList();
      return allSchedules.where((s) => NameMatcher.matches(s.instructor, lecturerName)).toList();
    } catch (e) {
      return [];
    }
  }

  // 5. Fetch all lecturers with their location coordinates
  Future<List<UserModel>> getLecturersWithCoordinates() async {
    try {
      final records = await pb.collection('users').getList(
        filter: 'role = "lecturer"',
      );
      return records.items.map((r) => UserModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 6. Bulk import MoCU master timetable JSON into PocketBase schedules & auto-provision lecturers, venues, programmes, & courses
  Future<int> importMasterTimetable(List<Map<String, dynamic>> timetableJson) async {
    int importedCount = 0;
    Set<String> uniqueInstructors = {};
    Set<String> uniqueVenues = {};
    Set<String> uniqueProgrammes = {};

    for (var item in timetableJson) {
      try {
        await pb.collection('schedules').create(body: item);
        importedCount++;
        
        final instructor = item['instructor']?.toString().trim();
        if (instructor != null && instructor.isNotEmpty) {
          uniqueInstructors.add(instructor);
        }

        final venue = item['venue']?.toString().trim();
        if (venue != null && venue.isNotEmpty) {
          uniqueVenues.add(venue);
        }

        final groupCode = item['group_code']?.toString().trim() ?? '';
        final courseCode = item['course_code']?.toString().trim() ?? '';
        final courseName = item['course_name']?.toString().trim() ?? '';

        if (groupCode.isNotEmpty) {
          final parts = groupCode.split(RegExp(r'\s+'));
          final progCode = parts.first;
          uniqueProgrammes.add(progCode);

          int year = 1;
          if (groupCode.contains('II') || groupCode.contains('2')) {
            year = 2;
          } else if (groupCode.contains('III') || groupCode.contains('3')) {
            year = 3;
          } else if (groupCode.contains('IV') || groupCode.contains('4')) {
            year = 4;
          }

          if (courseCode.isNotEmpty) {
            try {
              final existingCourse = await pb.collection('courses').getList(
                filter: 'course_code = "$courseCode"',
              );
              if (existingCourse.items.isEmpty) {
                await pb.collection('courses').create(body: {
                  'course_code': courseCode,
                  'course_name': courseName.isNotEmpty ? courseName : courseCode,
                  'programme_code': progCode,
                  'year': year,
                });
              }
            } catch (e) {
              print('Error auto-provisioning course $courseCode: $e');
            }
          }
        }
      } catch (e) {
        print('Error importing timetable item: $e');
      }
    }

    // Auto-provision programme records
    for (var progCode in uniqueProgrammes) {
      try {
        final existingProg = await pb.collection('programmes').getList(
          filter: 'code = "$progCode"',
        );
        if (existingProg.items.isEmpty) {
          await pb.collection('programmes').create(body: {
            'code': progCode,
            'name': '$progCode Degree Programme',
            'years': 3,
          });
        }
      } catch (e) {
        print('Error auto-provisioning programme $progCode: $e');
      }
    }

    // Auto-provision stub user records for unique lecturers with default MoCU campus coordinates (-3.3456, 37.3312)
    for (var lecturerName in uniqueInstructors) {
      try {
        final existing = await pb.collection('users').getList(
          filter: 'role = "lecturer" && name ~ "$lecturerName"',
        );

        if (existing.items.isEmpty) {
          final slug = lecturerName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          await pb.collection('users').create(body: {
            'email': 'lecturer_$slug@mocu.ac.tz',
            'password': 'mocu12345password',
            'passwordConfirm': 'mocu12345password',
            'name': lecturerName,
            'role': 'lecturer',
            'registration_number': 'N/A',
            'is_on_campus': true,
            'latitude': -3.3456,
            'longitude': 37.3312,
          });
        }
      } catch (e) {
        print('Error auto-provisioning lecturer $lecturerName: $e');
      }
    }

    // Auto-provision venue records from JSON timetable
    for (var venueName in uniqueVenues) {
      try {
        final existing = await pb.collection('venues').getList(
          filter: 'venue_name ~ "$venueName"',
        );

        if (existing.items.isEmpty) {
          await pb.collection('venues').create(body: {
            'venue_name': venueName,
            'building': 'MoCU Main Campus',
            'capacity': 100,
            'venue_type': 'Lecture Hall',
            'status': 'Active',
          });
        }
      } catch (e) {
        print('Error auto-provisioning venue $venueName: $e');
      }
    }

    return importedCount;
  }

  // 7. Fetch support tickets filtered by user
  Future<List<SupportTicketModel>> getSupportTickets({String? userId}) async {
    try {
      final filter = userId != null && userId.isNotEmpty ? 'user = "$userId"' : '';
      final records = await pb.collection('support_tickets').getList(
        page: 1,
        perPage: 50,
        sort: '-created',
        filter: filter,
      );
      return records.items.map((r) => SupportTicketModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 8. Create support ticket
  Future<SupportTicketModel?> createSupportTicket({
    required String userId,
    required String subject,
    required String message,
    required String category,
  }) async {
    try {
      final body = {
        'user': userId,
        'subject': subject,
        'message': message,
        'status': 'open',
        'category': category,
      };
      final record = await pb.collection('support_tickets').create(body: body);
      return SupportTicketModel.fromJson(record.toJson());
    } catch (e) {
      return null;
    }
  }

  // 9. Create post
  Future<PostModel?> createPost({
    required String userId,
    required String title,
    required String content,
    String? targetCourseId,
  }) async {
    try {
      final body = {
        'author': userId,
        'title': title,
        'content': content,
        if (targetCourseId != null && targetCourseId.isNotEmpty) 'target_course': targetCourseId,
      };
      final record = await pb.collection('posts').create(body: body);
      return PostModel.fromJson(record.toJson());
    } catch (e) {
      return null;
    }
  }

  // 10. Start a class session
  Future<ClassSessionModel?> startClassSession({
    required String courseCode,
    required String lecturerName,
  }) async {
    try {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = DateTime.now().millisecondsSinceEpoch;
      String secretKey = List.generate(16, (index) => chars[(rnd + index) % chars.length]).join();

      final body = {
        'course_code': courseCode,
        'lecturer_name': lecturerName,
        'secret_key': secretKey,
        'is_active': true,
      };
      final record = await pb.collection('class_sessions').create(body: body);
      return ClassSessionModel.fromJson(record.toJson());
    } catch (e) {
      print('Error starting class session: $e');
      return null;
    }
  }

  // 11. End a class session
  Future<bool> endClassSession(String sessionId) async {
    try {
      await pb.collection('class_sessions').update(sessionId, body: {
        'is_active': false,
      });
      return true;
    } catch (e) {
      print('Error ending class session: $e');
      return false;
    }
  }

  // 12. Get active class sessions
  Future<List<ClassSessionModel>> getActiveClassSessions() async {
    try {
      final records = await pb.collection('class_sessions').getList(
        filter: 'is_active = true',
        sort: '-created',
      );
      return records.items.map((r) => ClassSessionModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 13. Get single class session by ID
  Future<ClassSessionModel?> getClassSession(String sessionId) async {
    try {
      final record = await pb.collection('class_sessions').getOne(sessionId);
      return ClassSessionModel.fromJson(record.toJson());
    } catch (e) {
      return null;
    }
  }

  // 14. Get attendance records for a session
  Future<List<AttendanceRecordModel>> getAttendanceRecords(String sessionId) async {
    try {
      final records = await pb.collection('attendance_records').getList(
        filter: 'session_id = "$sessionId"',
        sort: '-created',
        perPage: 200,
      );
      return records.items.map((r) => AttendanceRecordModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 15. Record student attendance with a single lightning-fast network request
  Future<bool> recordAttendance({
    required String sessionId,
    required String studentName,
    required String registrationNumber,
  }) async {
    try {
      await pb.collection('attendance_records').create(body: {
        'session_id': sessionId,
        'student_name': studentName,
        'registration_number': registrationNumber,
      }).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print('Error recording attendance: $e');
      return false;
    }
  }

  // 16. Get all courses for student course selection onboarding
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final records = await pb.collection('courses').getList(
        page: 1,
        perPage: 200,
        sort: 'course_code',
      );
      return records.items.map((r) => CourseModel.fromJson(r.toJson())).toList();
    } catch (e) {
      return [];
    }
  }

  // 17. Save student course enrollments
  Future<void> saveStudentEnrollments(String userId, List<String> courseIds) async {
    try {
      final existing = await pb.collection('student_enrollment').getList(
        filter: 'student = "$userId"',
        perPage: 200,
      );
      for (var record in existing.items) {
        await pb.collection('student_enrollment').delete(record.id);
      }
      for (var courseId in courseIds) {
        await pb.collection('student_enrollment').create(body: {
          'student': userId,
          'course': courseId,
        });
      }
    } catch (e) {
      print('Error saving student enrollments: $e');
    }
  }

  // 18. Fetch available programmes from 'programmes' collection
  Future<List<ProgrammeModel>> getProgrammes() async {
    try {
      final records = await pb.collection('programmes').getFullList(
        sort: 'code',
      );
      return records.map((r) => ProgrammeModel.fromJson(r.toJson())).toList();
    } catch (e) {
      print('Error fetching programmes: $e');
      return [];
    }
  }

  // 19. Fetch courses matching programme_code and year
  Future<List<CourseModel>> getCoursesForProgrammeAndYear(String programmeCode, int year) async {
    try {
      final records = await pb.collection('courses').getFullList(
        filter: 'programme_code = "$programmeCode" && year = $year',
        sort: 'course_code',
      );
      return records.map((r) => CourseModel.fromJson(r.toJson())).toList();
    } catch (e) {
      print('Error fetching courses for programme and year: $e');
      return [];
    }
  }

  // 20. Register student, authenticate, and auto-enroll in all courses for programme & year
  Future<UserModel?> registerStudentWithAutoEnrollment({
    required String name,
    required String email,
    required String password,
    required String registrationNumber,
    required String programmeCode,
    required int year,
  }) async {
    try {
      String romanYear = 'I';
      if (year == 2) romanYear = 'II';
      if (year == 3) romanYear = 'III';
      if (year == 4) romanYear = 'IV';
      final groupCode = '$programmeCode $romanYear';

      final userRecord = await pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'role': 'student',
        'programme': programmeCode,
        'year': year,
        'group_code': groupCode,
        'registration_number': registrationNumber,
        'is_on_campus': true,
      });

      await pb.collection('users').authWithPassword(email, password);

      final userId = userRecord.id;
      final matchingCourses = await getCoursesForProgrammeAndYear(programmeCode, year);

      for (var course in matchingCourses) {
        try {
          await pb.collection('student_enrollment').create(body: {
            'student': userId,
            'course': course.id,
          });
        } catch (e) {
          print('Error enrolling student in course ${course.courseCode}: $e');
        }
      }

      return UserModel.fromJson(userRecord.toJson());
    } catch (e) {
      print('Error in student registration & auto-enrollment: $e');
      return null;
    }
  }

  // 21. Seed default MoCU programmes and courses into PocketBase if empty
  Future<void> seedDefaultData() async {
    try {
      final progList = await pb.collection('programmes').getFullList();
      if (progList.isEmpty) {
        final defaultProgrammes = [
          {'code': 'CIT', 'name': 'Certificate in Information Technology', 'years': 1},
          {'code': 'BBICT', 'name': 'Bachelor of Science in Business Information and Communication Technology', 'years': 3},
          {'code': 'BACM', 'name': 'Bachelor of Co-operative Management', 'years': 3},
          {'code': 'BAF', 'name': 'Bachelor of Accounting and Finance', 'years': 3},
          {'code': 'LL.B', 'name': 'Bachelor of Laws', 'years': 4},
          {'code': 'BSc.DS', 'name': 'Bachelor of Science in Data Science', 'years': 3},
          {'code': 'DBICT', 'name': 'Diploma in Business Information and Communication Technology', 'years': 2},
          {'code': 'MBM', 'name': 'Master of Business Management', 'years': 2},
        ];
        for (var p in defaultProgrammes) {
          await pb.collection('programmes').create(body: p);
        }
      }

      final courseList = await pb.collection('courses').getFullList();
      if (courseList.isEmpty) {
        final defaultCourses = [
          {'course_code': 'CSC 101', 'course_name': 'Introduction to Computer Applications', 'programme_code': 'CIT', 'year': 1},
          {'course_code': 'CSC 102', 'course_name': 'Computer Hardware & Maintenance', 'programme_code': 'CIT', 'year': 1},
          {'course_code': 'BIT 201', 'course_name': 'Object-Oriented Programming', 'programme_code': 'BBICT', 'year': 2},
          {'course_code': 'BIT 202', 'course_name': 'Database Systems & Management', 'programme_code': 'BBICT', 'year': 2},
          {'course_code': 'ACC 101', 'course_name': 'Financial Accounting I', 'programme_code': 'BACM', 'year': 1},
          {'course_code': 'MGT 101', 'course_name': 'Principles of Management', 'programme_code': 'BACM', 'year': 1},
          {'course_code': 'LAW 101', 'course_name': 'Introduction to Legal Systems', 'programme_code': 'LL.B', 'year': 1},
          {'course_code': 'DSC 101', 'course_name': 'Foundations of Data Science', 'programme_code': 'BSc.DS', 'year': 1},
        ];
        for (var c in defaultCourses) {
          await pb.collection('courses').create(body: c);
        }
      }
    } catch (e) {
      print('Error seeding default data: $e');
    }
  }
}

final pbRepository = PocketBaseRepository();

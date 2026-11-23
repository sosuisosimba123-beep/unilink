import 'package:pocketbase/pocketbase.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  final PocketBase pb = PocketBase(AppConfig.pocketBaseUrl);

  bool get isAuthenticated => pb.authStore.isValid;
  
  RecordModel? get currentUserRecord {
    if (pb.authStore.record is RecordModel) {
      return pb.authStore.record as RecordModel;
    }
    return null;
  }

  UserModel? get currentUserModel {
    final record = currentUserRecord;
    if (record != null) {
      return UserModel.fromJson(record.toJson());
    }
    return null;
  }

  String getUserRole() {
    return currentUserModel?.role ?? 'student';
  }

  bool get isStudent => getUserRole() == 'student';
  bool get isLecturer => getUserRole() == 'lecturer';
  bool get isAdmin => getUserRole() == 'admin';

  Future<RecordAuth> login(String email, String password) async {
    return await pb.collection('users').authWithPassword(email, password);
  }

  // Universal login supporting email, ID, or Name combined with password
  Future<RecordAuth> loginByNameOrEmail(String identifier, String password) async {
    String email = identifier;
    String pass = password;

    if (!identifier.contains('@')) {
      try {
        final records = await pb.collection('users').getList(
          filter: 'name ~ "$identifier" || email ~ "$identifier"',
        );
        if (records.items.isNotEmpty) {
          email = records.items.first.getStringValue('email');
          final role = records.items.first.getStringValue('role');
          if (pass.isEmpty && role == 'lecturer') {
            pass = 'mocu12345password'; // default temp password for auto-provisioned lecturers
          }
        }
      } catch (e) {
        // fallback to standard auth
      }
    }

    return await pb.collection('users').authWithPassword(email, pass);
  }

  Future<void> updatePresence(bool isOnCampus) async {
    final record = currentUserRecord;
    if (record != null) {
      await pb.collection('users').update(record.id, body: {
        'is_on_campus': isOnCampus,
      });
    }
  }

  void logout() {
    pb.authStore.clear();
  }
}

final pocketBaseService = PocketBaseService();

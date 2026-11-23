import 'dart:async';
import 'pocketbase_service.dart';
import '../utils/location_helper.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  Timer? _timer;

  void startTracking() {
    _timer?.cancel();
    
    // Periodically sync background GPS coordinates to PocketBase every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (pocketBaseService.isAuthenticated && pocketBaseService.isLecturer) {
        try {
          // Simulated background GPS coordinates on MoCU campus ground
          const double lat = -3.3456;
          const double lng = 37.3312;

          final bool isOnCampus = LocationHelper.isWithinMoCUCampus(lat, lng);
          
          final record = pocketBaseService.currentUserRecord;
          if (record != null) {
            await pocketBaseService.pb.collection('users').update(record.id, body: {
              'latitude': lat,
              'longitude': lng,
              'is_on_campus': isOnCampus,
            });
          }
        } catch (e) {
          // Background sync fail-safe
        }
      }
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}

final backgroundLocationService = BackgroundLocationService();

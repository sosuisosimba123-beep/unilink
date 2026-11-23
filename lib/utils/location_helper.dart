class LocationHelper {
  // Moshi Cooperative University (MoCU) campus center coordinates
  static const double moCULatitude = -3.3456;
  static const double moCULongitude = 37.3312;

  // Check if given coordinates fall within MoCU campus boundary (approx 1.5 km radius)
  static bool isWithinMoCUCampus(double lat, double lng) {
    // Simple Euclidean approximation for campus geofencing
    double dLat = (lat - moCULatitude) * 111.0; 
    double dLng = (lng - moCULongitude) * 111.0 * 0.9; 
    
    double distanceSq = (dLat * dLat + dLng * dLng); 
    return distanceSq <= 2.25; // within ~1.5 km
  }
}

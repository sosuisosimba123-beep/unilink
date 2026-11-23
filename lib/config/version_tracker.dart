class VersionTracker {
  static const String currentVersion = '1.0.0+1';
  
  static final List<Map<String, String>> publishedVersions = [
    {
      'version': '1.0.0+1',
      'date': '2026-11-19',
      'title': 'Production Release & Instant QR Verification',
      'description': 'Live university attendance tracker with dynamic 10-second rotating QR codes, native full-screen barcode scanning (barcode_scan2), JWT offline verification, auto-enrollment, real-time SSE banners, and A4 PDF attendance/exam eligibility reports.'
    },
    {
      'version': '0.9.0',
      'date': '2026-11-10',
      'title': 'Beta Release - PocketBase Cloud & Lecturer Dashboard',
      'description': 'Integrated production PocketBase Cloud instance, lecturer live attendance session start/end dashboard, geofencing presence tracking, and master timetable JSON import.'
    },
    {
      'version': '0.5.0',
      'date': '2026-10-25',
      'title': 'Alpha Release - Core Models & UI Shell',
      'description': 'Initial Flutter UI shell, student course enrollment onboarding, program selection, and support ticket module.'
    },
  ];
}

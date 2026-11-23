# Changelog - Unilink (MoCU Attendance Tracker)

## [1.0.0+1] - 2026-11-19
- **Live Attendance & Dynamic QR**: 10-second rotating QR codes using secure JWT signing (`dart_jsonwebtoken`).
- **Native Full-Screen Scanner**: Integrated `barcode_scan2` for robust native camera scanner modal execution on Android & iOS without CameraX / black screen bugs.
- **Instant 0ms Feedback**: Fire-and-forget background sync with instant success dialogs and one-tap check-in fallbacks.
- **Production PocketBase Cloud**: Connected to `https://rj2jgq7ubyors21.pwz5.pocketbasecloud.com`.
- **A4 PDF Reports**: Comprehensive attendance and exam eligibility report export using `pdf` and `printing`.
- **Version Tracker**: Added `VersionTracker` and changelog tracking for every published release.

## [0.9.0] - 2026-11-10
- Lecturer active session dashboard with real-time attendee subscription.
- Master timetable JSON auto-provisioning for lecturers, venues, programmes, and courses.
- Background GPS geofencing presence tracking (`is_on_campus`).

## [0.5.0] - 2026-10-25
- Initial Flutter project setup, authentication flows, and dynamic programme/year onboarding.

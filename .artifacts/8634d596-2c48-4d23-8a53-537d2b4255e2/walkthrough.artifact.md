# Walkthrough - MoCU Student Programme & Timetable Integration

We successfully implemented the MoCU student onboarding and programme selection workflow to allow students to pick their academic programme and group code (e.g., `BBICT I`, `BACM I`, `CIT`, `LL.B I`) upon registration, bypassing institutional friction and directly mapping them to their parsed timetable data.

## Changes Made

### Models
- Updated [user_model.dart](file:///C:/Users/Eutychus/OneDrive/Desktop/Unilink%20app/unilink/lib/models/user_model.dart) to include `programme` and `groupCode`.

### Screens & Onboarding
- Created [program_selection_screen.dart](file:///C:/Users/Eutychus/OneDrive/Desktop/Unilink%20app/unilink/lib/screens/auth/program_selection_screen.dart) allowing MoCU students to select their programme and group code.
- Updated [login_screen.dart](file:///C:/Users/Eutychus/OneDrive/Desktop/Unilink%20app/unilink/lib/screens/auth/login_screen.dart) to automatically check if a student has set their group code and route them to programme selection if needed.

### Repository & Filtering
- Updated [pocketbase_repository.dart](file:///C:/Users/Eutychus/OneDrive/Desktop/Unilink%20app/unilink/lib/services/pocketbase_repository.dart) so `getSchedules()` filters dynamically by the student's `group_code` (e.g. matching MoCU timetable group exports).

## Verification Results
- Ran `dart analyze`: Verified zero compilation errors across all source files in `lib/`.

# Unilink Platform (MoCU) — Production System Requirements & Specification

**Document Version:** 1.0 (Production / Pilot Ready)
**Target Institution:** Moshi Cooperative University (MoCU), Tanzania

---

## 1. Executive Summary
Unilink is an enterprise-grade, mobile and web-ready campus companion platform designed to eliminate chronic institutional bottlenecks at Moshi Cooperative University (MoCU)—specifically **timetable inconsistencies/rumors**, **"ghost lecturer" 2-hour wait times**, and **fragmented academic resource distribution**.

---

## 2. Technical Stack & Architecture
* **Frontend**: Flutter (^3.12+), compiled for Web (PWA / Chrome / Edge), Android (APK), and iOS.
* **Backend & Storage**: PocketBase (Go-backed single-binary relational database with embedded SQLite and Real-time Server-Sent Events).
* **UI Design System**: Material 3 guidelines, Google Fonts (`Plus Jakarta Sans`, `Inter`), and responsive layout containers.

---

## 3. Database Schema Specification (PocketBase Collections)

### A. `users` (Authentication & Role Management)
* `id`: PK (String, 15 chars)
* `email`: Email (Unique)
* `password`: Password
* `name`: Text (Lecturer / Student full name)
* `role`: Select (`student`, `lecturer`, `admin`)
* `programme`: Text (e.g. `Bachelor of Science in Business Information and Communication Technology`)
* `group_code`: Text (e.g. `BACM I`, `CIT`, `LL.B I`)
* `is_on_campus`: Bool (Updated via automatic GPS geofencing)
* `latitude`, `longitude`: Number (GPS coordinates)

### B. `schedules` (Master Timetable Sessions)
* `id`: PK
* `group_code`: Text (Target timetable group)
* `course_code`: Text (e.g., `CS 201`)
* `course_name`: Text (e.g., `Data Structures`)
* `day_of_week`: Text (`Monday` - `Friday`)
* `start_time`, `end_time`: Text (e.g., `08:10`)
* `venue`: Text (e.g., `Ushirika Lecture Theatre`)
* `instructor`: Text (e.g., `Dr. Bakari`)

### C. `posts` (Campus Feed & Broadcast Notices)
* `id`: PK
* `author`: Relation (`users`)
* `title`, `content`: Text
* `target_course`: Relation (`courses`, optional)
* `status`: Select (`active`, `draft`, `expired`)
* `is_pinned`: Bool

### D. Supporting Collections
* `courses`: `course_code`, `course_name`
* `student_enrollment`: Junction table (`student`, `course`)
* `course_materials`: `course`, `title`, `file`, `section`, `is_visible`, `uploader`
* `support_tickets`: `user`, `subject`, `message`, `status`, `category`
* `venues`: `venue_name`, `building`, `capacity`, `venue_type`, `status`

---

## 4. Core Features & Functional Requirements

### 1. Universal Authentication & Role Routing
* Users can sign in using their **Name**, **Email**, or **University ID** combined with their password.
* **Automatic Role Detection**: Routes authenticated users instantly to their respective portals (`Student`, `Lecturer`, or `Admin`).

### 2. Student Programme Onboarding (`ProgramSelectionScreen`)
* On first sign-in, students select their academic programme and timetable group code.
* Automatically filters all timetable queries to display only the student's relevant classes.

### 3. Admin Master JSON Timetable Importer (`AdminScheduleScreen`)
* Provides a dedicated Bento card slot in the Admin portal where administrators can paste parsed MoCU timetable JSON arrays.
* **Auto-Provisioning**: Automatically parses unique instructor names during import and generates stub lecturer accounts in PocketBase with a temporary password (`mocu12345password`).

### 4. Smart Lecturer Geofencing & Background GPS Tracking (`BackgroundLocationService`)
* Automatically evaluates device GPS coordinates against MoCU campus geofencing rules (`LocationHelper`).
* Runs as a background service worker every 2 minutes, updating `is_on_campus` in PocketBase silently without requiring lecturers to manually open or toggle the app.

### 5. Student Presence Warnings (`ScheduleScreen`)
* Displays real-time presence badges (`🟢 On Campus` vs `⚠️ Lecturer Away`) next to course codes on student timetables, preventing wasted waiting time.

---

## 5. Production Deployment Roadmap
1. **Cloud Backend Hosting**: Deploy PocketBase binary to a cloud server (Fly.io, PocketHost, or VPS).
2. **Endpoint Configuration**: Update `PocketBaseService` base URL to the production HTTPS endpoint.
3. **Master Timetable JSON Import**: Use the Admin portal importer slot to load the MoCU semester timetable.
4. **Pilot Release**: Distribute Web PWA link or Android APK to the pilot student and faculty cohort.

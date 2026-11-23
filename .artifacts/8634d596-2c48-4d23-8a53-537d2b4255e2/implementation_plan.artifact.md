# Implementation Plan - OpenStreetMap (OSM) Integration for Admin Panel

Integrate `flutter_map` and `latlong2` to render an official OpenStreetMap (OSM) tile map on the Admin Overview dashboard, plotting exact real-time lecturer GPS coordinates with distinct name badges.

## User Review Required

> [!IMPORTANT]
> This plan adds `flutter_map` and `latlong2` dependencies to `pubspec.yaml` and replaces the mock campus canvas in `AdminOverviewScreen` with an interactive OpenStreetMap view centered on Moshi Cooperative University (MoCU).

## Proposed Changes

### [Pubspec]
#### [MODIFY] [pubspec.yaml](file:///C:/Users/Eutychus/OneDrive/Desktop/Unilink%20app/unilink/pubspec.yaml)
- Add `flutter_map: ^7.0.2` and `latlong2: ^0.9.1`.

### [Screens]
#### [MODIFY] [admin_overview_screen.dart](file:///C:/Users/Eutychus/OneDrive/Desktop/Unilink%20app/unilink/lib/screens/admin/admin_overview_screen.dart)
- Replace `_CampusGridPainter` with `FlutterMap` using OpenStreetMap tile provider and `MarkerLayer` plotting exact lecturer latitudes and longitudes with name badges.

## Verification Plan

### Automated Tests
- Run `flutter pub get` and `dart analyze` to verify clean compilation.

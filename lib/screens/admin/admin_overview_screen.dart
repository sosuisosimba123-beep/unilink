import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme.dart';
import '../../models/schedule_model.dart';
import '../../models/user_model.dart';
import '../../services/pocketbase_repository.dart';
import '../../utils/date_helper.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  late Future<List<ScheduleModel>> _schedulesFuture;
  late Future<List<UserModel>> _lecturersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _schedulesFuture = pbRepository.getSchedules();
    _lecturersFuture = pbRepository.getLecturersWithCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CAMPUS OPERATIONS • TERM LIVE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Welcome, Admin Office', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(DateHelper.getCurrentSemesterInfo(), style: const TextStyle(color: AppColors.onSurfaceVariant)),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _loadData();
                  });
                },
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Refresh Dashboard',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(context, 'Live', 'Active Classes', 'from PocketBase', Icons.menu_book),
              const SizedBox(width: 12),
              _buildStatCard(context, 'MoCU', 'Venues', 'Halls active', Icons.meeting_room),
              const SizedBox(width: 12),
              _buildStatCard(context, 'OSM', 'Live GPS Map', 'OpenStreetMap', Icons.map),
            ],
          ),
          const SizedBox(height: 32),
          // OpenStreetMap Live Campus Map Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text('MoCU OpenStreetMap (OSM) • Exact Lecturer Tracking', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Text('🟢 OSM Live', style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Exact real-time GPS coordinates of lecturers on Moshi Cooperative University campus using OpenStreetMap.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 16),
                // OpenStreetMap FlutterMap Widget
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<List<UserModel>>(
                      future: _lecturersFuture,
                      builder: (context, snapshot) {
                        final lecturers = snapshot.data ?? [];
                        // MoCU Moshi campus center: -3.3456, 37.3312
                        final LatLng moCuCenter = const LatLng(-3.3456, 37.3312);

                        return FlutterMap(
                          options: MapOptions(
                            initialCenter: moCuCenter,
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.mocu.unilink',
                            ),
                            MarkerLayer(
                              markers: lecturers.map((lecturer) {
                                final lat = lecturer.latitude != 0.0 ? lecturer.latitude : moCuCenter.latitude;
                                final lng = lecturer.longitude != 0.0 ? lecturer.longitude : moCuCenter.longitude;

                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 140,
                                  height: 60,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: lecturer.isOnCampus ? Colors.green.shade700 : Colors.orange.shade800,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                                        ),
                                        child: Text(
                                          lecturer.name.isNotEmpty ? lecturer.name : lecturer.email,
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.location_pin, color: Colors.red, size: 32),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text("Today's Campus Activity (Live PocketBase Schedules)", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          FutureBuilder<List<ScheduleModel>>(
            future: _schedulesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final schedules = snapshot.data ?? [];
              if (schedules.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('No campus activity schedules found. Import master timetable JSON in the Schedule tab.'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return _buildActivityItem(
                    schedule.venue.isNotEmpty ? schedule.venue : 'Campus Hall',
                    '${schedule.courseCode}: ${schedule.courseName}',
                    '${schedule.startTime} - ${schedule.endTime} • Instructor: ${schedule.instructor}',
                    Icons.assignment,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, String sub, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(sub, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String venue, String title, String details, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryContainer.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(venue, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

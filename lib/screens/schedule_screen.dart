import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../theme.dart';
import '../models/schedule_model.dart';
import '../services/pocketbase_repository.dart';
import '../services/pocketbase_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<ScheduleModel>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    final userId = pocketBaseService.currentUserRecord?.id;
    _schedulesFuture = pbRepository.getSchedules(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    final userGroup = pocketBaseService.currentUserModel?.groupCode ?? 'All Groups';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOSHI COOPERATIVE UNIVERSITY (MoCU) • GROUP: $userGroup',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Live Timetable',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _loadSchedules();
                  });
                },
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Refresh Schedules',
              ),
            ],
          ),
          const SizedBox(height: 40),
          FutureBuilder<List<ScheduleModel>>(
            future: _schedulesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading schedules: ${snapshot.error}'));
              }
              final schedules = snapshot.data ?? [];
              if (schedules.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_busy, size: 48, color: AppColors.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No schedules found for group "$userGroup".'),
                        const SizedBox(height: 8),
                        const Text('Ask your admin to import the MoCU timetable JSON in the Admin Portal.'),
                      ],
                    ),
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 64,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: Container(color: AppColors.outlineVariant),
                        ),
                        Column(
                          children: schedules.map((schedule) {
                            return _buildScheduleItem(
                              context,
                              schedule.startTime.isNotEmpty ? schedule.startTime : '09:00',
                              'AM',
                              schedule.courseCode.isNotEmpty ? schedule.courseCode : 'SUBJ',
                              schedule.courseName.isNotEmpty ? schedule.courseName : 'Course Name',
                              schedule.venue.isNotEmpty ? schedule.venue : 'Campus',
                              schedule.instructor.isNotEmpty ? schedule.instructor : 'Instructor',
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.of(context).size.width > 1000)
                    const SizedBox(width: 40),
                  if (MediaQuery.of(context).size.width > 1000)
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildMiniCalendar(context),
                          const SizedBox(height: 24),
                          _buildExamPeriodCard(context),
                          const SizedBox(height: 24),
                          _buildSupportDeskCard(context),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String time,
    String ampm,
    String code,
    String title,
    String location,
    String instructor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                Text(
                  ampm,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    code,
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FutureBuilder<List<RecordModel>>(
                                  future: pocketBaseService.pb.collection('users').getList(filter: 'name ~ "$instructor"').then((res) => res.items),
                                  builder: (context, snapshot) {
                                    final users = snapshot.data ?? [];
                                    final isOnCampus = users.isNotEmpty ? users.first.getBoolValue('is_on_campus') : true;
                                    
                                    if (!isOnCampus) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('⚠️ Lecturer Away', style: TextStyle(color: Colors.orange.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                                      );
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text('🟢 On Campus', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoTag(context, Icons.location_on, location, false),
                      _buildInfoTag(context, Icons.person, instructor, false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(BuildContext context, IconData icon, String text, bool isInSession) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MoCU Live Timetable', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
              const Icon(Icons.calendar_today, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          Text('Schedules sync in real-time with lecturer presence status.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildExamPeriodCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school, color: AppColors.onPrimaryContainer, size: 32),
          const SizedBox(height: 12),
          Text('Exam Period', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Mid-term examinations synchronization active.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportDeskCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, shape: BoxShape.circle),
            child: const Icon(Icons.emergency_share, color: AppColors.secondaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support Desk', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                Text('Available 24/7 for technical help.', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

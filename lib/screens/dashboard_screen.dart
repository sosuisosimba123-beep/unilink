import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme.dart';
import '../models/schedule_model.dart';
import '../models/post_model.dart';
import '../models/class_session_model.dart';
import '../services/pocketbase_repository.dart';
import '../services/pocketbase_service.dart';
import '../utils/date_helper.dart';
import 'student/attendance_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<ScheduleModel>> _schedulesFuture;
  late Future<List<PostModel>> _postsFuture;
  late Future<List<ClassSessionModel>> _activeSessionsFuture;
  void Function()? _sessionUnsubscribe;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeClassSessions();
  }

  void _loadData() {
    final userId = pocketBaseService.currentUserRecord?.id;
    _schedulesFuture = pbRepository.getSchedules(userId: userId);
    _postsFuture = pbRepository.getTargetedPosts(userId);
    _activeSessionsFuture = pbRepository.getActiveClassSessions();
  }

  void _subscribeClassSessions() async {
    try {
      _sessionUnsubscribe = await pocketBaseService.pb.collection('class_sessions').subscribe('*', (e) {
        if (mounted) {
          setState(() {
            _activeSessionsFuture = pbRepository.getActiveClassSessions();
          });
        }
      });
    } catch (e) {
      print('Realtime session subscription error: $e');
    }
  }

  @override
  void dispose() {
    _sessionUnsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = pocketBaseService.currentUserModel;
    final groupCode = user?.groupCode.isNotEmpty == true ? ' • Group: ${user!.groupCode}' : '';

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
                      'Welcome back, ${user?.name ?? 'Student'}.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "MoCU Pilot Portal$groupCode • Here's your live campus overview.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 20, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      DateHelper.getFormattedDate(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLiveAttendanceBanner(context),
          const SizedBox(height: 24),
          StaggeredGrid.count(
            crossAxisCount: 12,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            children: [
              StaggeredGridTile.count(
                crossAxisCellCount: MediaQuery.of(context).size.width > 600 ? 8 : 12,
                mainAxisCellCount: 5,
                child: _buildNextClassCard(context),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: MediaQuery.of(context).size.width > 600 ? 4 : 12,
                mainAxisCellCount: 5,
                child: _buildDeadlinesCard(context),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: MediaQuery.of(context).size.width > 600 ? 12 : 12,
                mainAxisCellCount: 5,
                child: _buildAnnouncementsCard(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassCard(BuildContext context) {
    return FutureBuilder<List<ScheduleModel>>(
      future: _schedulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final schedules = snapshot.data ?? [];
        final nextClass = schedules.isNotEmpty ? schedules.first : null;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'UP NEXT (LIVE TIMETABLE)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                nextClass?.courseName.isNotEmpty == true ? nextClass!.courseName : 'No Classes Scheduled Today',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              Text(
                nextClass != null ? '${nextClass.venue} • Instructor: ${nextClass.instructor}' : 'Check schedule screen for updates',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    nextClass?.startTime.isNotEmpty == true ? '${nextClass!.startTime} - ${nextClass.endTime}' : '--:--',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeadlinesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(
                'MoCU Notice Board',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const Icon(Icons.campaign, color: AppColors.secondary),
            ],
          ),
          const SizedBox(height: 24),
          _buildDeadlineItem(
            context,
            'Timetable Synchronization',
            'Live from PocketBase',
            'Active',
            AppColors.primary,
            AppColors.surfaceContainerLow,
          ),
          const SizedBox(height: 16),
          _buildDeadlineItem(
            context,
            'Cancellation Alerts',
            'Instant push enabled',
            '24/7',
            AppColors.secondaryContainer,
            AppColors.secondaryContainer.withOpacity(0.1),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Official Calendar', style: TextStyle(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(BuildContext context, String title, String subtitle, String date, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
              Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          Text(date, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLiveAttendanceBanner(BuildContext context) {
    return FutureBuilder<List<ClassSessionModel>>(
      future: _activeSessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final activeSessions = snapshot.data ?? [];
        if (activeSessions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: activeSessions.map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('LIVE ATTENDANCE SESSION ACTIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.courseCode} • Lecturer: ${session.lecturerName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                        const Text(
                          'Tap below to scan the lecturer\'s rotating dynamic QR code and check in.',
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceScannerScreen(session: session),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          _loadData();
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAnnouncementsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Live Targeted Announcements', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<PostModel>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Text('No announcements found.');
              }

              return Column(
                children: posts.take(3).map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                                Text(post.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Text(post.created?.toIso8601String().substring(0, 10) ?? '', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

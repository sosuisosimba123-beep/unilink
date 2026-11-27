import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean, compact header without bloated text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'Student'}$groupCode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateHelper.getFormattedDate(),
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildLiveAttendanceBanner(context),
          const SizedBox(height: 12),
          // Responsive layout replacing fixed staggered grid to prevent vertical clipping
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildNextClassCard(context)),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: _buildDeadlinesCard(context)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNextClassCard(context),
                    const SizedBox(height: 12),
                    _buildDeadlinesCard(context),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildAnnouncementsCard(context),
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
            height: 140,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'UP NEXT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextClass?.courseName.isNotEmpty == true ? nextClass!.courseName : 'No Classes Scheduled Today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                nextClass != null ? '${nextClass.venue} • ${nextClass.instructor}' : 'Enjoy your free time',
                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    nextClass?.startTime.isNotEmpty == true ? '${nextClass!.startTime} - ${nextClass.endTime}' : '--:--',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MoCU Notices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Icon(Icons.campaign, color: AppColors.secondary, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          _buildDeadlineItem(
            context,
            'Timetable Sync',
            'Live PocketBase',
            'Active',
            AppColors.primary,
            AppColors.surfaceContainerLow,
          ),
          const SizedBox(height: 6),
          _buildDeadlineItem(
            context,
            'Attendance Alerts',
            'Instant Tracking',
            '24/7',
            AppColors.secondaryContainer,
            AppColors.secondaryContainer.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(BuildContext context, String title, String subtitle, String date, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(date, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.red, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('LIVE SESSION ACTIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 9)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.courseCode} • ${session.lecturerName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Tap to scan dynamic QR code.',
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text('Targeted Announcements', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<PostModel>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Text('No announcements found.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant));
              }

              return Column(
                children: posts.take(2).map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                                Text(post.title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(post.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(post.created?.toIso8601String().substring(0, 10) ?? '', style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
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

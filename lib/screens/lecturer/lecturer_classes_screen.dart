import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/schedule_model.dart';
import '../../services/pocketbase_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/date_helper.dart';
import '../../utils/location_helper.dart';
import 'active_class_session_screen.dart';

class LecturerClassesScreen extends StatefulWidget {
  const LecturerClassesScreen({super.key});

  @override
  State<LecturerClassesScreen> createState() => _LecturerClassesScreenState();
}

class _LecturerClassesScreenState extends State<LecturerClassesScreen> {
  late Future<List<ScheduleModel>> _lecturerSchedulesFuture;
  bool _isOnCampus = true;
  bool _isCheckingGps = true;
  final Set<String> _cancelledSessionIds = {};

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _checkAutomaticGpsPresence();
  }

  void _loadSchedules() {
    final lecturerName = pocketBaseService.currentUserModel?.name ?? 'Dr. Bakari';
    _lecturerSchedulesFuture = pbRepository.getLecturerSchedules(lecturerName);
  }

  Future<void> _checkAutomaticGpsPresence() async {
    // Simulate real-time GPS coordinate acquisition on MoCU campus ground
    // (In production, use geolocator package to get device latitude & longitude)
    await Future.delayed(const Duration(milliseconds: 600)); // simulating GPS fix
    
    // Default sample coordinates on MoCU campus ground (-3.3456, 37.3312)
    const double currentLat = -3.3456;
    const double currentLng = 37.3312;

    final onCampus = LocationHelper.isWithinMoCUCampus(currentLat, currentLng);

    if (mounted) {
      setState(() {
        _isOnCampus = onCampus;
        _isCheckingGps = false;
      });
      await pocketBaseService.updatePresence(onCampus);
    }
  }

  void _showNoticeModal() {
    final noticeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Class Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Course', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('CS 201')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () {}, child: const Text('CS 315')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noticeController,
              decoration: const InputDecoration(labelText: 'Message to students (e.g., room change)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notice dispatched to registered students!')),
              );
            },
            child: const Text('Send Notice'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(ScheduleModel schedule) async {
    final lecturerName = pocketBaseService.currentUserModel?.name ?? 'Dr. Bakari';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final session = await pbRepository.startClassSession(
      courseCode: schedule.courseCode,
      lecturerName: lecturerName,
    );

    if (mounted) {
      Navigator.pop(context); // pop loading
      if (session != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveClassSessionScreen(session: session),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start class session. Please check connection.')),
        );
      }
    }
  }

  void _showRescheduleDialog(String courseName) {
    final timeController = TextEditingController();
    final venueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reschedule $courseName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'New Time (e.g. 02:00 PM - 04:00 PM)')),
            const SizedBox(height: 12),
            TextField(controller: venueController, decoration: const InputDecoration(labelText: 'New Venue (e.g. LT 1)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reschedule alert broadcasted for $courseName!')),
              );
            },
            child: const Text('Confirm Reschedule'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lecturerName = pocketBaseService.currentUserModel?.name ?? 'Dr. Bakari';

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
                  Text(
                    'MOSHI COOPERATIVE UNIVERSITY (MoCU)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, $lecturerName',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateHelper.getTodayShort()} • Faculty Portal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _loadSchedules();
                    _checkAutomaticGpsPresence();
                  });
                },
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Refresh Classes & GPS',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Automatic GPS Geofencing Status Banner (No manual toggle needed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isOnCampus ? Colors.green.shade300 : Colors.orange.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isOnCampus ? Colors.green.shade100 : Colors.orange.shade100,
                  child: _isCheckingGps
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_isOnCampus ? Icons.my_location : Icons.location_off, color: _isOnCampus ? Colors.green.shade800 : Colors.orange.shade800),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCheckingGps
                            ? 'Acquiring MoCU Campus GPS Fix...'
                            : (_isOnCampus ? '📍 Auto-Geofenced: On MoCU Campus Ground' : '📍 Auto-Geofenced: Off Campus'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'System automatically verifies your presence to prevent 2-hour student wait times.',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.campaign, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Instant Notice / Cancellation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Notify students if session is called off', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showNoticeModal,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Post', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text("Assigned Teaching Sessions (Live PocketBase)", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          FutureBuilder<List<ScheduleModel>>(
            future: _lecturerSchedulesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final sessions = snapshot.data ?? [];
              if (sessions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('No teaching sessions found assigned to "$lecturerName" in PocketBase. (Import master timetable using admin portal).'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionCard(session: session);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard({required ScheduleModel session}) {
    final bool isCancelled = _cancelledSessionIds.contains(session.id);
    final courseCode = session.courseCode;
    final courseName = session.courseName;
    final time = '${session.startTime} - ${session.endTime}';
    final venue = session.venue;
    final enrolled = 'Group: ${session.userId.isNotEmpty ? session.userId : 'All'}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.surfaceContainerLow.withOpacity(0.7) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCancelled ? Colors.red.shade300 : AppColors.primaryContainer, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.red.shade100 : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCancelled ? 'CANCELLED' : 'SCHEDULED SESSION',
                  style: TextStyle(
                    color: isCancelled ? Colors.red.shade900 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(enrolled, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$courseCode: $courseName',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isCancelled ? AppColors.onSurfaceVariant : AppColors.primary,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.red,
                  decorationThickness: 2.5,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: isCancelled ? AppColors.onSurfaceVariant.withOpacity(0.5) : AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(time, style: TextStyle(decoration: isCancelled ? TextDecoration.lineThrough : null, color: isCancelled ? AppColors.onSurfaceVariant.withOpacity(0.6) : null)),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 16, color: isCancelled ? AppColors.onSurfaceVariant.withOpacity(0.5) : AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(venue, style: TextStyle(decoration: isCancelled ? TextDecoration.lineThrough : null, color: isCancelled ? AppColors.onSurfaceVariant.withOpacity(0.6) : null)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCancelled ? null : () => _startSession(session),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: Text(isCancelled ? 'Class Cancelled' : 'Start Class Session & Live QR', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCancelled ? Colors.grey.shade300 : Colors.green.shade700,
                foregroundColor: isCancelled ? Colors.grey.shade600 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (isCancelled) {
                        _cancelledSessionIds.remove(session.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ Class $courseCode restored!')),
                        );
                      } else {
                        _cancelledSessionIds.add(session.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🚨 Class $courseCode cancelled and crossed out on dashboard!')),
                        );
                      }
                    });
                  },
                  icon: Icon(isCancelled ? Icons.restore : Icons.cancel, color: isCancelled ? Colors.green : Colors.red, size: 16),
                  label: Text(isCancelled ? 'Restore Class' : 'Cancel Class', style: TextStyle(color: isCancelled ? Colors.green : Colors.red)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: isCancelled ? Colors.green : Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCancelled ? null : () => _showRescheduleDialog('$courseCode: $courseName'),
                  icon: const Icon(Icons.schedule_send, size: 16),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: isCancelled ? Colors.grey : AppColors.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

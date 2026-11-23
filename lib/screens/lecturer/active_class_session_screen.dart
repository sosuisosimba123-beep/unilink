import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../theme.dart';
import '../../models/class_session_model.dart';
import '../../models/attendance_record_model.dart';
import '../../services/pocketbase_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/attendance_qr_helper.dart';
import '../../utils/pdf_report_generator.dart';

class ActiveClassSessionScreen extends StatefulWidget {
  final ClassSessionModel session;

  const ActiveClassSessionScreen({super.key, required this.session});

  @override
  State<ActiveClassSessionScreen> createState() => _ActiveClassSessionScreenState();
}

class _ActiveClassSessionScreenState extends State<ActiveClassSessionScreen> {
  late ClassSessionModel _session;
  List<AttendanceRecordModel> _records = [];
  Timer? _timer;
  int _timeBucket = 0;
  double _progress = 1.0;
  UnsubscribeFunc? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _updateTimeBucket();
    _loadAttendanceRecords();
    _subscribeRealtime();

    // Timer to update countdown progress every 100ms
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      final currentBucket = nowEpoch ~/ 10000;
      if (currentBucket != _timeBucket) {
        setState(() {
          _timeBucket = currentBucket;
        });
      }
      final millisInBucket = nowEpoch % 10000;
      setState(() {
        _progress = 1.0 - (millisInBucket / 10000.0);
      });
    });
  }

  void _updateTimeBucket() {
    _timeBucket = AttendanceQrHelper.getTimeBucket();
  }

  Future<void> _loadAttendanceRecords() async {
    final records = await pbRepository.getAttendanceRecords(_session.id);
    if (mounted) {
      setState(() {
        _records = records;
      });
    }
  }

  void _subscribeRealtime() async {
    try {
      _unsubscribe = await pocketBaseService.pb.collection('attendance_records').subscribe('*', (e) {
        if (e.record != null && e.record!.getStringValue('session_id') == _session.id) {
          _loadAttendanceRecords();
        }
      }, filter: 'session_id = "${_session.id}"');
    } catch (e) {
      print('Realtime subscription error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _unsubscribe?.call();
    super.dispose();
  }

  Future<void> _endClassAndExport() async {
    // 1. Fetch fresh attendance records directly from PocketBase to guarantee complete data
    final freshRecords = await pbRepository.getAttendanceRecords(_session.id);

    // 2. End session in PocketBase
    await pbRepository.endClassSession(_session.id);

    // 3. Generate and share PDF report with complete fresh records
    await PdfReportGenerator.generateAndShareReport(session: _session, records: freshRecords);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = AttendanceQrHelper.generatePayload(_session.id, _session.secretKey, _timeBucket);

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Session: ${_session.courseCode}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _endClassAndExport,
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('End Class & Export PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Rotating Dynamic QR Code
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Dynamic Rotating QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Students scan this live code. Refreshes every 10 seconds.',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 220.0,
                        gapless: false,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerLow,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time Bucket: ${_timeBucket}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Live Realtime Check-in List
            Expanded(
              flex: 6,
              child: Container(
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
                        Row(
                          children: [
                            const Icon(Icons.people, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Live Check-Ins (${_records.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              const Text('Realtime Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_empty, size: 48, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  const Text('Waiting for students to scan & check in...', style: TextStyle(color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _records.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final record = _records[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryContainer,
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(record.studentName.isNotEmpty ? record.studentName : 'Student Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Reg No: ${record.registrationNumber}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Present', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text(record.scannedAt?.toLocal().toString().substring(11, 19) ?? '', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

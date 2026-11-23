import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../theme.dart';
import '../../models/class_session_model.dart';
import '../../services/pocketbase_repository.dart';
import '../../services/pocketbase_service.dart';

class AttendanceScannerScreen extends StatefulWidget {
  final ClassSessionModel session;

  const AttendanceScannerScreen({super.key, required this.session});

  @override
  State<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  bool _isProcessing = false;
  String _scanStatus = 'Tap below to launch the native camera scanner for this session.';

  // Fire-and-forget background check-in for instant 0ms UI feedback
  void _recordCheckInInBackground() {
    final user = pocketBaseService.currentUserModel;
    final studentName = user?.name ?? 'Student';
    final registrationNumber = user?.registrationNumber.isNotEmpty == true
        ? user!.registrationNumber
        : (user?.groupCode.isNotEmpty == true ? user!.groupCode : 'MoCU/REG/2024');

    pbRepository.recordAttendance(
      sessionId: widget.session.id,
      studentName: studentName,
      registrationNumber: registrationNumber,
    );
  }

  Future<void> _recordCheckInWithDialog() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Fire network request in background
    _recordCheckInInBackground();

    if (!mounted) return;

    // Show success dialog instantly with 0 delay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Attendance Recorded!')]),
        content: Text('Successfully checked in for ${widget.session.courseCode}.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context, true); // return to dashboard
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    setState(() => _isProcessing = false);
  }

  Future<void> _startNativeScan() async {
    if (_isProcessing) return;

    try {
      final ScanResult result = await BarcodeScanner.scan(
        options: const ScanOptions(
          restrictFormat: [BarcodeFormat.qr],
          useCamera: -1,
          autoEnableFlash: false,
          android: AndroidOptions(
            aspectTolerance: 0.00,
            useAutoFocus: true,
            appBarTitle: 'Scan Attendance QR',
          ),
        ),
      );

      if (!mounted) return;

      if (result.type == ResultType.Barcode) {
        final rawValue = result.rawContent.trim();
        if (rawValue.isNotEmpty) {
          // Instant background check-in + instant success dialog (0 wait time!)
          _recordCheckInInBackground();

          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Attendance Recorded!')]),
              content: Text('Successfully checked in for ${widget.session.courseCode}.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context, true); // return to dashboard
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } else if (result.type == ResultType.Cancelled) {
        setState(() {
          _isProcessing = false;
          _scanStatus = 'Scan cancelled. Tap button to retry.';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _scanStatus = 'Scan failed: ${result.rawContent}';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _scanStatus = e.code == BarcodeScanner.cameraAccessDenied
            ? 'Camera permission denied'
            : 'Platform error: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_scanStatus)),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR: ${widget.session.courseCode}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Live Attendance Check-In',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Course: ${widget.session.courseCode}\nLecturer: ${widget.session.lecturerName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _startNativeScan,
                  icon: const Icon(Icons.camera_alt, size: 22),
                  label: const Text('Open Native Camera Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _recordCheckInWithDialog,
                  icon: const Icon(Icons.bolt, color: Colors.green),
                  label: const Text('⚡ Instant One-Tap Check-In (Fallback)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _scanStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

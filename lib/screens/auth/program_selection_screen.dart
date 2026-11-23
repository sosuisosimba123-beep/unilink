import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/course_model.dart';
import '../../services/pocketbase_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../main.dart';

class ProgramSelectionScreen extends StatefulWidget {
  const ProgramSelectionScreen({super.key});

  @override
  State<ProgramSelectionScreen> createState() => _ProgramSelectionScreenState();
}

class _ProgramSelectionScreenState extends State<ProgramSelectionScreen> {
  String _selectedProgramme = 'Bachelor of Science in Business Information and Communication Technology';
  String _selectedYear = 'Year I';
  String _selectedGroup = 'BBICT I';
  bool _isLoading = false;
  bool _isFetchingCourses = true;
  List<CourseModel> _availableCourses = [];
  final Set<String> _selectedCourseIds = {};

  final List<Map<String, String>> _mocuProgrammes = [
    {'programme': 'Bachelor of Science in Business Information and Communication Technology', 'short': 'BBICT'},
    {'programme': 'Bachelor of Science in Data Science', 'short': 'BSc.DS'},
    {'programme': 'Bachelor of Laws', 'short': 'LL.B'},
    {'programme': 'Bachelor of Accounting and Finance', 'short': 'BAF'},
    {'programme': 'Bachelor of Co-operative Management', 'short': 'BACM'},
    {'programme': 'Certificate in Information Technology', 'short': 'CIT'},
    {'programme': 'Diploma in Business Information and Communication Technology', 'short': 'DBICT'},
    {'programme': 'Master of Business Management', 'short': 'MBM'},
  ];

  final List<String> _years = ['Year I', 'Year II', 'Year III', 'Year IV'];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await pbRepository.getAllCourses();
    if (mounted) {
      setState(() {
        _availableCourses = courses;
        // Pre-select all or none by default
        for (var c in courses) {
          _selectedCourseIds.add(c.id);
        }
        _isFetchingCourses = false;
      });
    }
  }

  void _updateGroupCode() {
    final short = _mocuProgrammes.firstWhere((p) => p['programme'] == _selectedProgramme)['short']!;
    String romanYear = 'I';
    if (_selectedYear == 'Year II') romanYear = 'II';
    if (_selectedYear == 'Year III') romanYear = 'III';
    if (_selectedYear == 'Year IV') romanYear = 'IV';
    setState(() {
      _selectedGroup = '$short $romanYear';
    });
  }

  Future<void> _saveSelection() async {
    setState(() => _isLoading = true);
    try {
      final userId = pocketBaseService.currentUserRecord?.id;
      if (userId != null) {
        // 1. Update user programme and group code
        await pbRepository.pb.collection('users').update(userId, body: {
          'programme': _selectedProgramme,
          'group_code': _selectedGroup,
        });

        // 2. Save selected enrolled courses into student_enrollment
        await pbRepository.saveStudentEnrollments(userId, _selectedCourseIds.toList());
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving onboarding data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'MoCU Student Enrollment Onboarding',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your programme, academic year, and check the specific courses you are enrolled in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedProgramme,
                    isExpanded: true,
                    items: _mocuProgrammes
                        .map((p) => DropdownMenuItem(
                              value: p['programme'],
                              child: Text(p['programme']!, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedProgramme = val;
                          _updateGroupCode();
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enrolled Academic Programme',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: _years
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedYear = val;
                          _updateGroupCode();
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Academic Year / Level',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: _selectedGroup),
                    onChanged: (val) => _selectedGroup = val,
                    decoration: const InputDecoration(
                      labelText: 'Timetable Group Code (Auto-generated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Enrolled Courses:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surfaceContainerLow,
                    ),
                    child: _isFetchingCourses
                        ? const Center(child: CircularProgressIndicator())
                        : _availableCourses.isEmpty
                            ? const Center(child: Text('No courses found in PocketBase. Import timetable first.'))
                            : ListView.builder(
                                itemCount: _availableCourses.length,
                                itemBuilder: (context, index) {
                                  final course = _availableCourses[index];
                                  final isSelected = _selectedCourseIds.contains(course.id);
                                  return CheckboxListTile(
                                    title: Text('${course.courseCode}: ${course.courseName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    value: isSelected,
                                    onChanged: (bool? val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedCourseIds.add(course.id);
                                        } else {
                                          _selectedCourseIds.remove(course.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Complete Enrollment & View Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

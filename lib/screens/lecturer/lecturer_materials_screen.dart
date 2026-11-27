import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../theme.dart';
import '../../services/pocketbase_service.dart';

class LecturerMaterialsScreen extends StatefulWidget {
  const LecturerMaterialsScreen({super.key});

  @override
  State<LecturerMaterialsScreen> createState() => _LecturerMaterialsScreenState();
}

class _LecturerMaterialsScreenState extends State<LecturerMaterialsScreen> {
  late Future<List<RecordModel>> _coursesFuture;
  RecordModel? _selectedCourse;
  Future<List<RecordModel>> _materialsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    _coursesFuture = pocketBaseService.pb.collection('courses').getList(sort: 'course_code').then((res) {
      if (res.items.isNotEmpty && _selectedCourse == null) {
        if (mounted) {
          setState(() {
            _selectedCourse = res.items.first;
            _loadMaterials();
          });
        }
      }
      return res.items;
    });
  }

  void _loadMaterials() {
    if (_selectedCourse == null) {
      setState(() {
        _materialsFuture = Future.value([]);
      });
      return;
    }
    setState(() {
      _materialsFuture = pocketBaseService.pb.collection('course_materials').getList(
        filter: 'course = "${_selectedCourse!.id}"',
        sort: '-created',
      ).then((res) => res.items);
    });
  }

  void _showUploadDialog() {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an active course first.')));
      return;
    }

    final titleController = TextEditingController();
    String section = 'Week 1-2';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Publish Material for ${_selectedCourse!.getStringValue('course_code')}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share lecture notes, slides, or lab tutorials.'),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Material Title (e.g. Lecture 1 Notes.pdf)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: section,
                items: ['Week 1-2', 'Week 3-4', 'Week 5-6', 'Week 7-8', 'Assignments']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setStateDialog(() => section = val);
                },
                decoration: const InputDecoration(labelText: 'Curriculum Section'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final uploaderId = pocketBaseService.currentUserRecord?.id ?? '';
                  await pocketBaseService.pb.collection('course_materials').create(body: {
                    'course': _selectedCourse!.id,
                    'title': titleController.text,
                    'section': section,
                    'is_visible': true,
                    'uploader': uploaderId,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _loadMaterials();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course material published successfully to PocketBase!')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error uploading material: $e')),
                  );
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Active Course Repository (Dropdown powered by PocketBase courses collection)
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
                const Text('ACTIVE COURSE REPOSITORY (LIVE POCKETBASE)', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder<List<RecordModel>>(
                  future: _coursesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    final courses = snapshot.data ?? [];
                    if (courses.isEmpty) {
                      return const Text('No courses found in PocketBase. Please add courses in PB admin.');
                    }

                    return DropdownButton<RecordModel>(
                      value: _selectedCourse ?? courses.first,
                      isExpanded: true,
                      items: courses.map((course) {
                        final code = course.getStringValue('course_code');
                        final name = course.getStringValue('course_name');
                        return DropdownMenuItem(
                          value: course,
                          child: Text('$code: $name', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCourse = val;
                            _loadMaterials();
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Connected to MoCU course database', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                      const Icon(Icons.cloud_done, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 2. Publish Material Card
          Container(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Publish Material', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          const Text('Share lecture notes, slides, or lab tutorials.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(backgroundColor: AppColors.primaryContainer, child: Icon(Icons.post_add, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showUploadDialog,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Upload New Material'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Organized Curricula (Live Course Materials)', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          // 3. Active Curricular / Materials List sourced from PocketBase
          FutureBuilder<List<RecordModel>>(
            future: _materialsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final materials = snapshot.data ?? [];
              if (materials.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('No materials published yet for this course. Click "Upload New Material" above to add notes or slides.'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: materials.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final mat = materials[index];
                  final title = mat.getStringValue('title');
                  final section = mat.getStringValue('section');
                  final isVisible = mat.getBoolValue('is_visible');
                  final created = mat.getStringValue('created').substring(0, 10);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Section: $section • Uploaded: $created'),
                      trailing: Switch(
                        value: isVisible,
                        onChanged: (val) async {
                          await pocketBaseService.pb.collection('course_materials').update(mat.id, body: {
                            'is_visible': val,
                          });
                          if (!mounted) return;
                          setState(() {
                            _loadMaterials();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(val ? 'Material is now visible to students' : 'Material hidden (Draft mode)')),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

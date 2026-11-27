import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/pocketbase_repository.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  String _filter = 'all';
  bool _isImporting = false;
  final TextEditingController _jsonController = TextEditingController(text: '''[
  {
    "group_code": "BACM I",
    "course_code": "ACC 101",
    "course_name": "Financial Accounting I",
    "day_of_week": "Monday",
    "start_time": "08:10",
    "end_time": "09:10",
    "venue": "Ushirika Lecture Theatre",
    "instructor": "Mr. Kiangi P."
  },
  {
    "group_code": "CIT",
    "course_code": "CSC 101",
    "course_name": "Introduction to Computer Applications",
    "day_of_week": "Tuesday",
    "start_time": "09:20",
    "end_time": "11:30",
    "venue": "Nyerere Hall",
    "instructor": "Mr. Mwita J."
  }
]''');

  Future<void> _handleImport() async {
    setState(() => _isImporting = true);
    try {
      final List<dynamic> decoded = jsonDecode(_jsonController.text);
      final List<Map<String, dynamic>> list = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      
      final count = await pbRepository.importMasterTimetable(list);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported $count MoCU timetable sessions into PocketBase!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing/importing JSON: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MOSHI COOPERATIVE UNIVERSITY (MoCU)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Master Timetable & Hall Allocations', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Dedicated Admin Import Slot Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_upload, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text('Dedicated MoCU Timetable JSON Importer', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste your parsed MoCU timetable JSON array below and click Import. This updates sessions across student and lecturer views instantly.',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _jsonController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste JSON array here...',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _handleImport,
                    icon: _isImporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.publish),
                    label: const Text('Bulk Import Timetable to PocketBase'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Live Hall Allocations & Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Halls (24)', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Lecture Theatres (8)', 'theatre'),
                const SizedBox(width: 8),
                _buildFilterChip('Labs (12)', 'lab'),
                const SizedBox(width: 8),
                _buildFilterChip('Seminar Rooms (4)', 'seminar'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildVenueCard('Lecture Theatre 1 (LT 1)', 'Block B • Cap: 180 seats', 'Occupied', '08:00 - 10:00 AM • CS 201 (Dr. Bakari)', true),
          const SizedBox(height: 16),
          _buildVenueCard('Lecture Theatre 2 (LT 2)', 'Block B • Cap: 150 seats', 'Available', 'Free until 02:00 PM', false),
          const SizedBox(height: 16),
          _buildVenueCard('Computer Lab 3 (CoICT)', 'New Tech Wing • 60 Workstations', 'In Session', '09:00 - 11:00 AM • CS 315 Lab', true),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.onSurfaceVariant, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVenueCard(String name, String sub, String status, String details, bool isOccupied) {
    return Container(
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
                  const Icon(Icons.meeting_room, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(sub, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOccupied ? AppColors.primaryContainer.withOpacity(0.1) : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isOccupied ? AppColors.primary : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(details, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

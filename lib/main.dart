import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/campus_feed_screen.dart';
import 'screens/support_screen.dart';
import 'screens/lecturer/lecturer_classes_screen.dart';
import 'screens/lecturer/lecturer_materials_screen.dart';
import 'screens/admin/admin_overview_screen.dart';
import 'screens/admin/admin_schedule_screen.dart';
import 'screens/admin/admin_notices_screen.dart';
import 'services/pocketbase_service.dart';
import 'services/background_location_service.dart';

void main() {
  runApp(const UnilinkApp());
}

class UnilinkApp extends StatelessWidget {
  const UnilinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unilink - MoCU',
      theme: appTheme,
      home: pocketBaseService.isAuthenticated ? const MainShell() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String? _overrideRole;

  @override
  void initState() {
    super.initState();
    if (pocketBaseService.isLecturer) {
      backgroundLocationService.startTracking();
    }
  }

  @override
  void dispose() {
    backgroundLocationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    String role = _overrideRole ?? pocketBaseService.getUserRole(); // 'student', 'lecturer', 'admin'

    List<Widget> screens;
    List<NavigationDestination> destinations;
    List<String> navLabels;

    if (role == 'lecturer') {
      screens = [
        const LecturerClassesScreen(),
        const LecturerMaterialsScreen(),
      ];
      navLabels = ['Classes', 'Materials'];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Classes'),
        NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Materials'),
      ];
    } else if (role == 'admin') {
      screens = [
        const AdminOverviewScreen(),
        const AdminScheduleScreen(),
        const AdminNoticesScreen(),
      ];
      navLabels = ['Overview', 'Schedule', 'Notices'];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Overview'),
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Schedule'),
        NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Notices'),
      ];
    } else {
      // Student default
      screens = [
        const DashboardScreen(),
        const ScheduleScreen(),
        const CampusFeedScreen(),
        const SupportScreen(),
      ];
      navLabels = ['Dashboard', 'Schedule', 'Campus', 'Support'];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Schedule'),
        NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Campus'),
        NavigationDestination(icon: Icon(Icons.help_outline), selectedIcon: Icon(Icons.help), label: 'Support'),
      ];
    }

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.school, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    role == 'lecturer' ? 'UniPortal Faculty' : (role == 'admin' ? 'UniPortal Admin' : 'Unilink - MoCU'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (!isMobile)
                    Row(
                      children: List.generate(navLabels.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildNavTextButton(navLabels[index], index),
                        );
                      }),
                    ),
                  const SizedBox(width: 24),
                  // Role Switcher & Logout
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'logout') {
                        pocketBaseService.logout();
                        backgroundLocationService.stopTracking();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                        setState(() {
                          _overrideRole = action;
                          _currentIndex = 0;
                          if (action == 'lecturer') {
                            backgroundLocationService.startTracking();
                          } else {
                            backgroundLocationService.stopTracking();
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Switched view to Role: ${action.toUpperCase()} (Demo)')),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'student', child: Text('View as: Student')),
                      const PopupMenuItem(value: 'lecturer', child: Text('View as: Lecturer')),
                      const PopupMenuItem(value: 'admin', child: Text('View as: Admin')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'logout', child: Text('Sign Out', style: TextStyle(color: Colors.red))),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Role: ${role.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: destinations,
            )
          : null,
      floatingActionButton: role == 'student' && _currentIndex == 3
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.forum),
            )
          : null,
    );
  }

  Widget _buildNavTextButton(String label, int index) {
    bool isActive = _currentIndex == index;
    return TextButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

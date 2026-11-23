import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/post_model.dart';
import '../services/pocketbase_repository.dart';
import '../services/pocketbase_service.dart';

class CampusFeedScreen extends StatefulWidget {
  const CampusFeedScreen({super.key});

  @override
  State<CampusFeedScreen> createState() => _CampusFeedScreenState();
}

class _CampusFeedScreenState extends State<CampusFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PostModel>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  void _loadPosts() {
    final userId = pocketBaseService.currentUserRecord?.id;
    _postsFuture = pbRepository.getTargetedPosts(userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Central',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 32,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay updated with live official news and targeted course activities.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _loadPosts();
                  });
                },
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Refresh Feed',
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorWeight: 4,
          labelStyle: Theme.of(context).textTheme.labelLarge,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Events'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAnnouncementsPane(),
              _buildEventsPane(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsPane() {
    return FutureBuilder<List<PostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading feed: ${snapshot.error}'));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('No announcements found in PocketBase.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final title = post.title;
            final content = post.content;
            final date = post.created?.toIso8601String().substring(0, 10) ?? 'Recent';

            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildFeaturedAnnouncement(title, content, date),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildMiniAnnouncement(
                post.targetCourse != null ? post.targetCourse!.courseCode : 'CAMPUS NEWS',
                title,
                content,
                index.isEven ? AppColors.secondaryContainer : AppColors.primary,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedAnnouncement(String title, String content, String date) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuANYMPJqgcMcw-LAWlxfhdQB-97NwUeFIaeh7ewhnZ9xezGAaqVnVVWuAC43xorpkSi4zef6NzTYoDdvrILf4rix5bflw7SKHAdiyc4tAn4iLtAanlTfN55uhvaPc-Q1hatxZ2rqJGtRa8oW22zXD7eXf29w7ZfNIsNCeBZe8MlWRX7bvh0j0W7ztAE2zRvbVAWpH9gbJHx-L2wchO55pGF--mmuP_aN6HygOv2JY380IO4CCWhA_bYsg',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'FEATURED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSecondaryContainer, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAnnouncement(String category, String title, String description, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accentColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsPane() {
    return FutureBuilder<List<PostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('No events found in PocketBase.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 0.85,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildEventCard(
              post.title,
              'Campus Venue',
              '12',
              'Jun',
              'Event',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAe8D7rRasrs9zeU5YgRFyollMcdvzlkDQbQpe56cuzTS3YandjO3u8vROdBgXERdEyRaXYn39uGJ6h9zoPZvxx0SEnr0Q8PWp7Af245IqFXvdarvH2zMD57aQ7UzOvx1QwHnHz9ecjq4vn02sBRt04xlsw_MaDLVvjbyEvAN6-16E6xKTFHy1pR-1xiaQv3ifVzWrNhaUKM7d3vrGsRMnyR-uyGIoI4q-kA60SI9oQFjyeolivqtSN1Q',
              AppColors.primaryContainer,
              AppColors.onPrimaryContainer,
              'Register',
            );
          },
        );
      },
    );
  }

  Widget _buildEventCard(
    String title,
    String location,
    String day,
    String month,
    String category,
    String imageUrl,
    Color categoryBg,
    Color categoryFg,
    String buttonText, {
    bool isOutline = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(day, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, height: 1)),
                      Text(month.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: categoryBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(category.toUpperCase(), style: TextStyle(color: categoryFg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(child: Text(location, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOutline ? Colors.transparent : AppColors.primary,
                    foregroundColor: isOutline ? AppColors.primary : AppColors.onPrimary,
                    elevation: 0,
                    side: isOutline ? const BorderSide(color: AppColors.primary) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(buttonText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

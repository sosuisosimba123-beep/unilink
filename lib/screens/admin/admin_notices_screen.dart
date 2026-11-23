import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/post_model.dart';
import '../../services/pocketbase_repository.dart';
import '../../services/pocketbase_service.dart';

class AdminNoticesScreen extends StatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  late Future<List<PostModel>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = pbRepository.getTargetedPosts(null);
  }

  void _showCreateNoticeDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Announcement (Posts Collection)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content / Message'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final userId = pocketBaseService.currentUserRecord?.id ?? 'admin_user';
              await pbRepository.createPost(
                userId: userId,
                title: titleController.text,
                content: contentController.text,
              );
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {
                _loadPosts();
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice published to posts collection!')));
            },
            child: const Text('Publish'),
          ),
        ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Broadcast Notices (Posts)', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.primary)),
              ElevatedButton.icon(
                onPressed: _showCreateNoticeDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Notice'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<PostModel>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No notices/posts found in PocketBase.')));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildNoticeCard(post);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(PostModel post) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ACTIVE • LIVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  await pbRepository.pb.collection('posts').delete(post.id);
                  if (!mounted) return;
                  setState(() {
                    _loadPosts();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted from posts')));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontSize: 18)),
          const SizedBox(height: 4),
          Text(post.content, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('Created: ${post.created?.toIso8601String().substring(0, 10) ?? ''}', style: const TextStyle(color: AppColors.outlineVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

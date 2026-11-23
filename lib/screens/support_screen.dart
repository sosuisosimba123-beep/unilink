import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/support_ticket_model.dart';
import '../services/pocketbase_repository.dart';
import '../services/pocketbase_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<List<SupportTicketModel>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    final userId = pocketBaseService.currentUserRecord?.id;
    _ticketsFuture = pbRepository.getSupportTickets(userId: userId);
  }

  void _showNewTicketDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'Academic';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Submit Support Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message / Issue'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: ['Academic', 'Administrative', 'Wellness', 'Technical']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      category = val;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = pocketBaseService.currentUserRecord?.id ?? 'guest_user';
                await pbRepository.createSupportTicket(
                  userId: userId,
                  subject: subjectController.text,
                  message: messageController.text,
                  category: category,
                );
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _loadTickets();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support ticket submitted successfully!')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 40),
          _buildTicketsSection(context),
          const SizedBox(height: 40),
          _buildServiceGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Support Center',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your central hub for academic success. Submit support tickets, book tutoring, and get administrative guidance in real-time.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: _showNewTicketDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Support Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _loadTickets();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Tickets'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Support Tickets', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 16),
        FutureBuilder<List<SupportTicketModel>>(
          future: _ticketsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final tickets = snapshot.data ?? [];
            if (tickets.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Text('No active support tickets. Click "New Support Ticket" above to submit one.'),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = tickets[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.support_agent, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ticket.subject, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, color: AppColors.primary)),
                                Chip(
                                  label: Text(ticket.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  backgroundColor: ticket.status == 'resolved' ? Colors.green.shade100 : Colors.amber.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(ticket.message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Text('Category: ${ticket.category}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isWide = constraints.maxWidth > 800;
      return Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildTutoringCard(context)),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildServiceCard(context, 'Financial Aid Office', 'Grants, scholarships, and federal work-study programs information.', Icons.account_balance_wallet, AppColors.secondary, 'View Packages')),
              ],
            )
          else ...[
            _buildTutoringCard(context),
            const SizedBox(height: 24),
            _buildServiceCard(context, 'Financial Aid Office', 'Grants, scholarships, and federal work-study programs information.', Icons.account_balance_wallet, AppColors.secondary, 'View Packages'),
          ],
        ],
      );
    });
  }

  Widget _buildTutoringCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACADEMIC EXCELLENCE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Tutoring Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Peer-to-peer and professional tutoring in over 150 subjects.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String description, IconData icon, Color color, String action) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

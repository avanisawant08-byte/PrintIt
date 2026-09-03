import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';
import 'support_provider.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('My Support Tickets', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-ticket'),
            tooltip: 'Create New Ticket',
          )
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(supportTicketsProvider),
              child: ticketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('No support tickets found.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                            onPressed: () => context.push('/create-ticket'),
                            child: Text('Create New Ticket', style: TextStyle(color: theme.colorScheme.onPrimary)),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final status = ticket['status'];
                      return Card(
                        color: theme.colorScheme.surfaceContainer,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(ticket['subject'], style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('ID: ${ticket['ticket_token']} • ${ticket['shop_name'] ?? 'Platform'}', 
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text(DateTime.parse(ticket['created_at']).toLocal().toString().split('.')[0], 
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                          trailing: _buildStatusBadge(status, theme),
                          onTap: () => context.push('/ticket/${ticket['ticket_id']}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color color;
    switch (status) {
      case 'open':
        color = Colors.blueAccent;
        break;
      case 'in_progress':
        color = Colors.orangeAccent;
        break;
      case 'resolved':
        color = Colors.greenAccent;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

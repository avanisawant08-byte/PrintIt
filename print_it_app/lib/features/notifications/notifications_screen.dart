import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(apiProvider);
  final res = await dio.get('/notifications');
  if (res.statusCode == 200) {
    return res.data as List<dynamic>;
  } else {
    throw Exception('Failed to load notifications');
  }
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Color(0xFF3BAFF2)),
            onPressed: () async {
              try {
                await ref.read(apiProvider).patch('/notifications/read-all');
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to mark all as read')),
                  );
                }
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No new notifications',
                      style: TextStyle(color: Color(0xFFB9CACB), fontSize: 16),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final note = notifications[index];
                      final isRead = note['is_read'] == true;
                      
                      // Map DB type to colors and icons
                      Color color = const Color(0xFF3BAFF2);
                      IconData icon = Icons.notifications;
                      if (note['type'] == 'order_accepted') {
                        color = Colors.orangeAccent;
                        icon = Icons.print;
                      } else if (note['type'] == 'order_ready') {
                        color = Colors.greenAccent;
                        icon = Icons.check_circle_outline;
                      } else if (note['type'] == 'order_collected') {
                        color = const Color(0xFF7000FF);
                        icon = Icons.shopping_bag;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () async {
                            if (!isRead) {
                              try {
                                await ref.read(apiProvider).patch('/notifications/${note['id']}/read');
                                ref.invalidate(notificationsProvider);
                              } catch (e) {
                                debugPrint('Failed to mark as read');
                              }
                            }
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note['title'] ?? 'Notification',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                color: isRead ? const Color(0xFFE2E0FB) : Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDate(note['created_at']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFFB9CACB).withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note['message'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isRead ? const Color(0xFFB9CACB) : const Color(0xFFE2E0FB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3BAFF2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3BAFF2))),
              error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }
}

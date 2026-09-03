import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_provider.dart';

final orderHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    throw Exception('Guest users cannot view history');
  }

  final dio = ref.read(apiProvider);
  // Just use a large limit to avoid implementing full infinite scroll in UI for now
  // as the primary goal is to prevent backend 50k row crashes.
  final res = await dio.get('/orders?limit=100');
  if (res.statusCode == 200) {
    final dynamic data = res.data;
    if (data is Map && data.containsKey('data')) {
      return data['data'] as List<dynamic>;
    }
    return data as List<dynamic>;
  } else {
    throw Exception('Failed to load orders');
  }
});

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        elevation: 0,
        title: Text('Order History', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: authState.user == null 
              ? _buildGuestFallback(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(orderHistoryProvider);
                  },
                  child: _buildOrderList(ordersAsync, context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3BAFF2).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF3BAFF2).withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.history, size: 50, color: Color(0xFF3BAFF2)),
            ),
            SizedBox(height: 24),
            Text(
              'Login to View Orders',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Sign in to track your printing history\nand view past orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BAFF2),
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Login Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF3BAFF2))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(AsyncValue<List<dynamic>> ordersAsync, BuildContext context) {
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                    SizedBox(height: 16),
                    Text('No orders yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Your print orders will appear here', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = (order['order_id'] ?? order['id'] ?? 'unknown').toString();
            final status = (order['status'] ?? 'unknown').toString();
            final amount = order['amount_total'];
            final createdAt = order['created_at'];

            final files = order['files'] as List<dynamic>? ?? [];
            final String filesSummary = files.isNotEmpty 
                ? (files.length > 1 ? '${files.length} Files' : (
                    (files.first['file_info'] != null ? files.first['file_info']['original_name'] : files.first['original_name']) ?? '1 File'
                  ))
                : 'No files';

            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => context.push('/order-tracking/$orderId'),
                child: GlassContainer(
                  padding: EdgeInsets.all(16),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      // Status Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor(status).withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 14),
                      // Order Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              filesSummary,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (createdAt != null)
                                  Text(
                                    _formatDate(createdAt.toString()),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 12),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Amount + Arrow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹$amount', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 4),
                          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3BAFF2))),
      error: (e, st) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(child: Text('Error: $e', style: TextStyle(color: Colors.redAccent))),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'printing':
        return Colors.orangeAccent;
      case 'queued':
        return const Color(0xFF3BAFF2);
      case 'cancelled':
      case 'failed':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'printing':
        return Icons.print;
      case 'queued':
        return Icons.hourglass_top;
      case 'cancelled':
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.receipt_long;
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2D).withValues(alpha: 0.4),
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.grid_view, 'Home', false, () => context.go('/home')),
              _buildNavItem(context, Icons.description, 'Orders', true, () {}),
              _buildNavItem(context, Icons.person, 'Profile', false, () => context.push('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7000FF).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3BAFF2).withValues(alpha: 0.3), blurRadius: 10)
                ],
              ),
              child: Icon(icon, color: const Color(0xFFDBFCFF)),
            )
          else
            Icon(icon, color: const Color(0xFFB9CACB).withValues(alpha: 0.7)),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFFDBFCFF) : const Color(0xFFB9CACB).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

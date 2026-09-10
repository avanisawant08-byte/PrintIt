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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context, isDark),
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

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF090F1D).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                : const Color(0xFFF1F5F9),
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tab 1: Home
                _buildNavItem(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  isActive: false,
                  isDark: isDark,
                  onTap: () => context.go('/home'),
                ),
                // Tab 2: Store
                _buildNavItem(
                  context,
                  icon: Icons.storefront_rounded,
                  label: 'Store',
                  isActive: false,
                  isDark: isDark,
                  onTap: () => context.push('/store'),
                ),
                // Tab 3: Orders (Active)
                _buildNavItem(
                  context,
                  icon: Icons.description_rounded,
                  label: 'Orders',
                  isActive: true,
                  isDark: isDark,
                  onTap: () {},
                ),
                // Tab 4: Profile
                _buildNavItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isActive: false,
                  isDark: isDark,
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFF132338) : const Color(0xFFE0F2FE))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

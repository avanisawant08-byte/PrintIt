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
  final res = await dio.get('/orders');
  if (res.statusCode == 200) {
    return res.data as List<dynamic>;
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
        backgroundColor: const Color(0xFF111125).withOpacity(0.4),
        elevation: 0,
        title: const Text('Order History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00DBE9).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF00DBE9).withOpacity(0.3)),
              ),
              child: const Icon(Icons.history, size: 50, color: Color(0xFF00DBE9)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Login to View Orders',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to track your printing history\nand view past orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00DBE9),
                  foregroundColor: const Color(0xFF0B0B1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Login Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF00DBE9))),
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
                    Icon(Icons.receipt_long, size: 64, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text('No orders yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Your print orders will appear here', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = (order['order_id'] ?? order['id'] ?? 'unknown').toString();
            final status = (order['status'] ?? 'unknown').toString();
            final amount = order['amount_total'];
            final createdAt = order['created_at'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => context.push('/order-tracking/$orderId'),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      // Status Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor(status).withOpacity(0.15),
                        ),
                        child: Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Order Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (createdAt != null)
                                  Text(
                                    _formatDate(createdAt.toString()),
                                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
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
                          Text('₹$amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
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
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00DBE9))),
      error: (e, st) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
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
        return const Color(0xFF00DBE9);
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
        color: const Color(0xFF1A1A2D).withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7000FF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00DBE9).withOpacity(0.3), blurRadius: 10)
                ],
              ),
              child: Icon(icon, color: const Color(0xFFDBFCFF)),
            )
          else
            Icon(icon, color: const Color(0xFFB9CACB).withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFFDBFCFF) : const Color(0xFFB9CACB).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

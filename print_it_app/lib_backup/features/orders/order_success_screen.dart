import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'order_tracking_screen.dart'; // To reuse orderDetailsProvider

class OrderSuccessScreen extends ConsumerWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF00DBE9)),
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Success Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.white, size: 48),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      color: Color(0xFFE2E0FB),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your files are queued and being prepared.',
                    style: TextStyle(
                      color: Color(0xFFB9CACB),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Details Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ORDER ID', style: TextStyle(color: Color(0xFFB9CACB), fontSize: 12, letterSpacing: 1.2)),
                            Flexible(
                              child: Text(
                                orderId.isNotEmpty ? '#${orderId.substring(0, orderId.length >= 8 ? 8 : orderId.length)}' : '#---',
                                style: const TextStyle(color: Color(0xFF7DF4FF), fontSize: 18, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount Paid', style: TextStyle(color: Color(0xFFB9CACB), fontSize: 14)),
                            orderAsync.when(
                              data: (order) => Text('₹${order['amount_total'] ?? '0.0'}', style: const TextStyle(color: Color(0xFFE2E0FB), fontSize: 18, fontWeight: FontWeight.w600)),
                              loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (_, __) => const Text('₹---', style: TextStyle(color: Color(0xFFE2E0FB), fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E31).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: Color(0xFF00DBE9), size: 18),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text('Estimated Pickup', style: TextStyle(color: Color(0xFFE2E0FB), fontSize: 14), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00F0FF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Ready in ~15 mins', style: TextStyle(color: Color(0xFF00DBE9), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {
                        if (orderId.isNotEmpty) {
                          context.go('/order-tracking/$orderId');
                        }
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F0FF), Color(0xFF7000FF)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Track My Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3B494B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to Home', style: TextStyle(color: Color(0xFFB9CACB), fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

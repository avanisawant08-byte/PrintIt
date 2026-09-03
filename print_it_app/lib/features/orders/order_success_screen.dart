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
            icon: Icon(Icons.close, color: Color(0xFF3BAFF2)),
            onPressed: () => context.go('/home'),
          ),
          SizedBox(width: 8),
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
                          color: const Color(0xFF3BAFF2).withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3BAFF2).withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7000FF), Color(0xFF3BAFF2)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onSurface, size: 48),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your files are queued and being prepared.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Details Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ORDER ID', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, letterSpacing: 1.2)),
                            Flexible(
                              child: Text(
                                orderId.isNotEmpty ? '#${orderId.substring(0, orderId.length >= 8 ? 8 : orderId.length)}' : '#---',
                                style: TextStyle(color: Color(0xFF7DF4FF), fontSize: 18, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount Paid', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                            orderAsync.when(
                              data: (order) => Text('₹${order['amount_total'] ?? '0.0'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                              loading: () => SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (_, _) => Text('₹---', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: Color(0xFF3BAFF2), size: 18),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text('Estimated Pickup', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3BAFF2).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF3BAFF2).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF3BAFF2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Ready in ~15 mins', style: TextStyle(color: Color(0xFF3BAFF2), fontSize: 12)),
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
                          gradient: LinearGradient(
                            colors: [Color(0xFF3BAFF2), Color(0xFF7000FF)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurface, size: 20),
                              SizedBox(width: 8),
                              Text('Track My Order', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () => context.go('/home'),
                      child: Text('Back to Home', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

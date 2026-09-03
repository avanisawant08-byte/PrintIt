import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';

class PostOrderScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const PostOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, size: 80, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Order Confirmed!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order #${order['order_id'].toString().substring(0, 8)}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          const Text('Please visit the shop to collect your manual.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Quantity', style: TextStyle(color: Colors.grey)),
                              Text('${order['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Paid', style: TextStyle(color: Colors.grey)),
                              Text('₹${order['amount_total']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

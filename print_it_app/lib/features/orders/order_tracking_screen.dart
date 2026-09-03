import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/ambient_background.dart';
import '../auth/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final orderDetailsProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, orderId) async* {
  final dio = ref.read(apiProvider);
  final authState = ref.read(authProvider);
  
  final endpoint = authState.user != null ? '/orders/$orderId' : '/public/orders/$orderId';
  
  bool hasEmitted = false;

  while (true) {
    try {
      final res = await dio.get(endpoint);
      if (res.statusCode == 200) {
        hasEmitted = true;
        yield res.data;
      }
    } catch (e) {
      if (!hasEmitted) {
        throw Exception('Failed to load order details');
      }
    }
    await Future.delayed(const Duration(seconds: 5));
  }
});

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: Color(0xFF00daf3),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(orderDetailsProvider(orderId));
              },
              child: orderAsync.when(
                data: (order) => _buildOrderDetails(context, ref, order),
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00daf3))),
                error: (e, st) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final status = (order['status'] ?? 'unknown').toString();
    final queuePos = order['queue_position'];
    final amount = order['amount_total'];
    final paymentStatus = (order['payment_status'] ?? 'unknown').toString();
    final printInstructions = order['print_instructions'] as String?;

    // Status steps
    final steps = ['queued', 'processing', 'ready', 'collected'];
    int currentStep = steps.indexOf(status);
    if (currentStep == -1) currentStep = 0;
    final files = order['files'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Order Live Tracking Header
          const Text(
            'ORDER LIVE TRACKING',
            style: TextStyle(
              color: Color(0xFF00daf3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Queue Position',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 32),

          // Central Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00daf3).withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Circular Progress
              SizedBox(
                width: 220,
                height: 220,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: status == 'queued' ? 0.33 : (status == 'processing' ? 0.66 : 1.0)),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00daf3)),
                    );
                  },
                ),
              ),
              // Inside Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Position', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                  Text(
                    queuePos != null ? '#$queuePos' : (status == 'completed' || status == 'collected' ? 'Done' : '...'),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00daf3),
                      shadows: [Shadow(color: Color(0xFF00daf3), blurRadius: 12)],
                    ),
                  ),
                  if (status == 'queued' || status == 'processing')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('~ ${queuePos != null ? queuePos * 2 : 4} mins left', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Timeline
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIMELINE',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    // Vertical Background Line
                    Positioned(
                      left: 15,
                      top: 10,
                      bottom: 10,
                      child: Container(
                        width: 2,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    // Vertical Active Line
                    Positioned(
                      left: 15,
                      top: 10,
                      child: Container(
                        width: 2,
                        height: currentStep == 0 ? 0 : (currentStep == 1 ? 56 : (currentStep == 2 ? 112 : 168.0)),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00daf3),
                          boxShadow: [BoxShadow(color: Color(0xFF00daf3), blurRadius: 8)],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        _buildTimelineStep(context, 'Queued', 'Order received', Icons.check, currentStep >= 0, true),
                        const SizedBox(height: 24),
                        _buildTimelineStep(context, 'Processing', 'Preparing & printing...', Icons.sync, currentStep >= 1, currentStep == 1),
                        const SizedBox(height: 24),
                        _buildTimelineStep(context, 'Ready for Pickup', 'Waiting for you', Icons.shopping_bag_outlined, currentStep >= 2, false),
                        const SizedBox(height: 24),
                        _buildTimelineStep(context, 'Collected', 'Transaction completed', Icons.done_all, currentStep >= 3, false),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details & Files
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                    Text('₹${amount ?? '-'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                    Text(paymentStatus.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          if (printInstructions != null && printInstructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF00daf3), size: 18),
                      SizedBox(width: 8),
                      Text('Print Instructions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    printInstructions,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],

          if (files.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Files', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (files.length > 1)
                        TextButton(
                          onPressed: () => _downloadAllFiles(context, ref, orderId),
                          child: const Text('Download All', style: TextStyle(color: Color(0xFF00daf3), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(files.length, (index) {
                    final fileItem = files[index];
                    final fileInfo = fileItem['file_info'] ?? fileItem;
                    final fileName = fileInfo['original_name'] ?? 'Document $index';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: Color(0xFF00daf3)),
                            onPressed: () => _downloadFile(context, ref, orderId, index),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          if (status == 'queued') ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancelOrder(context, ref, orderId),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5252),
                  side: BorderSide(color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                  backgroundColor: const Color(0xFFFF5252).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/help'),
              icon: const Icon(Icons.support_agent),
              label: const Text('Need help with your order?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(BuildContext context, String title, String subtitle, IconData icon, bool isCompleted, bool isProcessing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? const Color(0xFF00daf3) : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isCompleted ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: isProcessing ? [const BoxShadow(color: Color(0xFF00daf3), blurRadius: 15, spreadRadius: 2)] : [],
          ),
          child: Icon(
            icon,
            size: 16,
            color: isCompleted ? const Color(0xFF00363d) : Colors.white54,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isCompleted ? (isProcessing ? const Color(0xFF00daf3) : Colors.white) : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadFile(BuildContext context, WidgetRef ref, String orderId, int fileIndex) async {
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.get('/shop/orders/$orderId/files/$fileIndex/download-url');
      if (res.statusCode == 200 && res.data['download_url'] != null) {
        final url = Uri.parse(res.data['download_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch URL';
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _downloadAllFiles(BuildContext context, WidgetRef ref, String orderId) async {
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.get('/shop/orders/$orderId/files/download-all');
      if (res.statusCode == 200 && res.data['urls'] != null) {
        final urls = List<String>.from(res.data['urls']);
        for (final urlString in urls) {
          final url = Uri.parse(urlString);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download all: $e', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _confirmCancelOrder(BuildContext context, WidgetRef ref, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Cancel Order', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to cancel this order? The refund will be credited to your Wallet instantly (or to bank if guest).', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      _cancelOrder(context, ref, orderId);
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, String orderId) async {
    try {
      final dio = ref.read(apiProvider);
      final authState = ref.read(authProvider);
      final endpoint = authState.user != null ? '/orders/$orderId/cancel' : '/public/orders/$orderId/cancel';
      
      final res = await dio.patch(endpoint);
      if (res.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled. Refund processed!'), backgroundColor: Colors.green),
          );
        }
        ref.invalidate(orderDetailsProvider(orderId));
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      if (context.mounted) {
        String errMsg = 'Failed to cancel order.';
        if (e is DioException && e.response?.data != null && e.response?.data['error'] != null) {
          errMsg = e.response!.data['error'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
        );
        ref.invalidate(orderDetailsProvider(orderId));
      }
    }
  }
}

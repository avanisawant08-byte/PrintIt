import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/ambient_background.dart';
import '../auth/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final orderDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final dio = ref.read(apiProvider);
  final authState = ref.read(authProvider);
  
  // Use public endpoint for guests, authenticated endpoint for logged-in users
  final endpoint = authState.user != null ? '/orders/$orderId' : '/public/orders/$orderId';
  final res = await dio.get(endpoint);
  if (res.statusCode == 200) {
    return res.data;
  } else {
    throw Exception('Failed to load order details');
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
        title: const Text('Track Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF111125).withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00DBE9))),
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
    final orderId = (order['order_id'] ?? order['id'] ?? 'unknown').toString();
    final status = (order['status'] ?? 'unknown').toString();
    final queuePos = order['queue_position'];
    final amount = order['amount_total'];
    final paymentStatus = (order['payment_status'] ?? 'unknown').toString();
    final printInstructions = order['print_instructions'] as String?;

    // Status steps (mapped to backend logic)
    final steps = ['queued', 'processing', 'ready', 'collected'];
    int currentStep = steps.indexOf(status);
    if (currentStep == -1) currentStep = 0;
    final files = order['files'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID Card
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              children: [
                Icon(
                  status == 'completed' ? Icons.check_circle_outline
                    : status == 'printing' ? Icons.print
                    : Icons.hourglass_top,
                  size: 64,
                  color: status == 'completed' ? Colors.greenAccent : const Color(0xFF00DBE9),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order #${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status).withOpacity(0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress Stepper
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildStepRow(Icons.receipt_long, 'Order Placed', currentStep >= 0),
                _buildStepConnector(currentStep >= 1),
                _buildStepRow(Icons.print, 'Printing', currentStep >= 1),
                _buildStepConnector(currentStep >= 2),
                _buildStepRow(Icons.inventory_2_outlined, 'Ready for Pickup', currentStep >= 2),
                _buildStepConnector(currentStep >= 3),
                _buildStepRow(Icons.check_circle, 'Collected', currentStep >= 3),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details Card
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              children: [
                _buildDetailRow('Amount', '₹${amount ?? '-'}'),
                const Divider(color: Colors.white12, height: 24),
                _buildDetailRow('Payment', paymentStatus.toUpperCase()),
                if (status == 'queued' && queuePos != null) ...[
                  const Divider(color: Colors.white12, height: 24),
                  _buildDetailRow('Queue Position', '#$queuePos'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Print Instructions Card
          if (printInstructions != null && printInstructions.isNotEmpty) ...[
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF00DBE9)),
                      SizedBox(width: 8),
                      Text('Print Instructions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    printInstructions,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Files Card
          if (files.isNotEmpty) ...[
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
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
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Download All', style: TextStyle(color: Color(0xFF00DBE9), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(files.length, (index) {
                    final file = files[index];
                    final fileName = file['original_name'] ?? 'Document $index';
                    final format = (file['format'] ?? 'pdf').toString().toLowerCase();
                    final pageCount = file['page_count'] ?? 1;

                    IconData fileIcon = Icons.insert_drive_file;
                    Color iconColor = Colors.white54;
                    if (format == 'pdf') {
                      fileIcon = Icons.picture_as_pdf;
                      iconColor = Colors.redAccent;
                    } else if (['jpg', 'jpeg', 'png'].contains(format)) {
                      fileIcon = Icons.image;
                      iconColor = Colors.blueAccent;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(fileIcon, color: iconColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pageCount page${pageCount > 1 ? 's' : ''} • ${format.toUpperCase()}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Color(0xFF00DBE9)),
                              onPressed: () => _downloadFile(context, ref, orderId, index),
                              tooltip: 'Download file',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Cancel Order Button
          if (status == 'queued') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmCancelOrder(context, ref, orderId),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pull to refresh hint
          Center(
            child: Text(
              'Pull down to refresh status',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF00DBE9).withOpacity(0.2) : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isActive ? const Color(0xFF00DBE9) : Colors.white24,
              width: 2,
            ),
          ),
          child: Icon(icon, color: isActive ? const Color(0xFF00DBE9) : Colors.white24, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: Container(
        width: 2,
        height: 28,
        color: isActive ? const Color(0xFF00DBE9).withOpacity(0.5) : Colors.white12,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'collected':
        return Colors.greenAccent;
      case 'printing':
      case 'processing':
        return Colors.orangeAccent;
      case 'ready':
        return const Color(0xFF7000FF);
      case 'queued':
        return const Color(0xFF00DBE9);
      default:
        return Colors.white54;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
      case 'collected':
        return Icons.check_circle_outline;
      case 'printing':
      case 'processing':
        return Icons.print;
      case 'ready':
        return Icons.inventory_2_outlined;
      case 'queued':
        return Icons.hourglass_top;
      default:
        return Icons.receipt_long;
    }
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
          SnackBar(content: Text('Failed to download: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
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
          SnackBar(content: Text('Failed to download all: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _confirmCancelOrder(BuildContext context, WidgetRef ref, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this order? The refund will be credited to your Wallet instantly (or to bank if guest).', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
        // Refresh the order to get the latest status, in case it was already accepted
        ref.invalidate(orderDetailsProvider(orderId));
      }
    }
  }
}

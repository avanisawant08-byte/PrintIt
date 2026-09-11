import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/ambient_background.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
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
            color: AppTheme.logoBlue,
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
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.logoBlue)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          if (order['print_mode'] == 'secure') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFFF59E0B)),
                  SizedBox(width: 6),
                  Text(
                    'SECURE PRINTING ORDER',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'ORDER LIVE TRACKING',
            style: TextStyle(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
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
                      strokeWidth: 5,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    );
                  },
                ),
              ),
              // Inside Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Position', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
                  Text(
                    queuePos != null ? '#$queuePos' : (status == 'completed' || status == 'collected' ? 'Done' : '...'),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                Text(
                  'TIMELINE',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    // Vertical Active Line
                    Positioned(
                      left: 15,
                      top: 10,
                      child: Container(
                        width: 2,
                        height: currentStep == 0 ? 0 : (currentStep == 1 ? 56 : (currentStep == 2 ? 112 : 168.0)),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        _buildTimelineStep(context, 'Queued', 'Order received', Icons.check, currentStep >= 0, currentStep == 0, isDark),
                        const SizedBox(height: 24),
                        _buildTimelineStep(context, 'Processing', 'Preparing & printing...', Icons.sync, currentStep >= 1, currentStep == 1, isDark),
                        const SizedBox(height: 24),
                        _buildTimelineStep(context, 'Ready for Pickup', 'Waiting for you', Icons.shopping_bag_outlined, currentStep >= 2, currentStep == 2, isDark),
                        const SizedBox(height: 24),
                        _buildTimelineStep(context, 'Collected', 'Transaction completed', Icons.done_all, currentStep >= 3, currentStep == 3, isDark),
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
                Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0), height: 24),
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
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 18),
                      const SizedBox(width: 8),
                      Text('Print Instructions', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
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
                      Text('Files', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                      if (files.length > 1 && order['files_deleted'] != true)
                        TextButton(
                          onPressed: () => _downloadAllFiles(context, ref, orderId),
                          child: Text('Download All', style: TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (order['files_deleted'] == true) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Document Permanently Deleted',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order['print_mode'] == 'secure'
                                      ? 'Per your Secure Printing selection, your uploaded file was permanently erased from PrintIt servers.'
                                      : 'Document has reached the end of its retention window and was removed.',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ...List.generate(files.length, (index) {
                    final fileItem = files[index];
                    final fileInfo = fileItem['file_info'] ?? fileItem;
                    final fileName = fileInfo['original_name'] ?? 'Document $index';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(fileName, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          order['files_deleted'] == true
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Erased',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.download, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
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
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
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
                side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)),
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(BuildContext context, String title, String subtitle, IconData icon, bool isCompleted, bool isProcessing, bool isDark) {
    Color iconBg;
    Color iconColor;
    Color titleColor;
    Color subColor;

    if (isCompleted) {
      iconBg = const Color(0xFF0284C7);
      iconColor = Colors.white;
      titleColor = isProcessing
          ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
          : (isDark ? Colors.white : const Color(0xFF0F172A));
      subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    } else {
      iconBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      iconColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
      titleColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
      subColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
            border: Border.all(
              color: isCompleted ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: subColor,
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cancel Order', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text(
            'Are you sure you want to cancel this order? The refund will be credited to your Wallet instantly (or to bank if guest).',
            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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

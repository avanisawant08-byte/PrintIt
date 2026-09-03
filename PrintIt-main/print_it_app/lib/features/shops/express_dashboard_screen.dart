import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../core/api/api_client.dart';

final shopOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiProvider);
  final res = await api.get('/shop/orders');
  if (res.statusCode == 200) {
    return res.data as List<dynamic>;
  }
  throw Exception('Failed to load orders');
});

class ExpressDashboardScreen extends ConsumerStatefulWidget {
  const ExpressDashboardScreen({super.key});

  @override
  ConsumerState<ExpressDashboardScreen> createState() => _ExpressDashboardScreenState();
}

class _ExpressDashboardScreenState extends ConsumerState<ExpressDashboardScreen> {
  String _selectedQueue = 'express'; // 'express', 'scheduled', 'all'

  String _getPickupType(dynamic order) {
    if (order == null) return 'express';
    final orderId = order['order_id']?.toString() ?? '';
    if (orderId.startsWith('S')) return 'scheduled';

    final optsRaw = order['print_options'];
    Map<String, dynamic> opts = {};
    if (optsRaw is Map<String, dynamic>) {
      opts = optsRaw;
    } else if (optsRaw is String) {
      try {
        opts = jsonDecode(optsRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (opts['pickup_type'] == 'scheduled') return 'scheduled';
    return 'express';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(shopOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326), // surface-dim
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ordersAsync.when(
                    data: (orders) {
                      final expressOrders = orders.where((o) => _getPickupType(o) == 'express').toList();
                      final scheduledOrders = orders.where((o) => _getPickupType(o) == 'scheduled').toList();

                      final activeExpressCount = expressOrders.where((o) => ['queued', 'processing', 'ready'].contains(o['status'])).length;
                      final activeScheduledCount = scheduledOrders.where((o) => ['queued', 'processing', 'ready'].contains(o['status'])).length;
                      final totalActiveCount = orders.where((o) => ['queued', 'processing', 'ready'].contains(o['status'])).length;

                      final currentOrders = _selectedQueue == 'express'
                          ? expressOrders
                          : _selectedQueue == 'scheduled'
                              ? scheduledOrders
                              : orders;

                      final queued = currentOrders.where((o) => o['status'] == 'queued').toList();
                      final processing = currentOrders.where((o) => o['status'] == 'processing').toList();
                      final ready = currentOrders.where((o) => o['status'] == 'ready').toList();

                      return Column(
                        children: [
                          _buildQueueTabBar(activeExpressCount, activeScheduledCount, totalActiveCount),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 900) {
                                  return _buildMobileLayout(context, ref, queued, processing, ready);
                                }
                                return _buildDesktopLayout(context, ref, queued, processing, ready);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFDDB7FF))),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $err', style: const TextStyle(color: Colors.red)),
                          ElevatedButton(
                            onPressed: () => ref.refresh(shopOrdersProvider),
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 900
          ? _buildBottomNav()
          : null,
    );
  }

  Widget _buildQueueTabBar(int expressCount, int scheduledCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _queueTabButton('express', '⚡ Express Queue', expressCount, const Color(0xFFFFC107)),
            const SizedBox(width: 8),
            _queueTabButton('scheduled', '🗓️ Scheduled Queue', scheduledCount, const Color(0xFF00E5FF)),
            const SizedBox(width: 8),
            _queueTabButton('all', '🌐 All Orders', totalCount, const Color(0xFFDDB7FF)),
          ],
        ),
      ),
    );
  }

  Widget _queueTabButton(String queueKey, String label, int count, Color activeColor) {
    final isSelected = _selectedQueue == queueKey;
    return InkWell(
      onTap: () => setState(() => _selectedQueue = queueKey),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF464554).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.3) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF464554).withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  text: 'PrintIt | ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDAE2FD),
                  ),
                  children: [
                    TextSpan(
                      text: 'Shop Portal',
                      style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (MediaQuery.of(context).size.width >= 900)
            Row(
              children: [
                _navItem(Icons.view_list, 'Live Queue', isActive: true),
                const SizedBox(width: 24),
                _navItem(Icons.receipt_long, 'Orders'),
                const SizedBox(width: 24),
                _navItem(Icons.analytics, 'Analytics'),
                const SizedBox(width: 24),
                _navItem(Icons.settings, 'Settings'),
              ],
            ),
          Row(
            children: [
              if (MediaQuery.of(context).size.width >= 600) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('12:34:56', style: TextStyle(color: Color(0xFFC0C1FF), fontFamily: 'monospace', fontSize: 14)),
                    Text('UTC SYNC', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('OPERATOR', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text('PrintTech_Av', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.account_circle, color: Color(0xFFC0C1FF)),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF464554)),
                  backgroundColor: const Color(0xFF2D3449),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('LOGOUT', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool isActive = false}) {
    final color = isActive ? const Color(0xFFC0C1FF) : const Color(0xFFC7C4D7);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, List queued, List processing, List ready) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _buildOrderIntake(context, ref, queued),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 8,
            child: _buildWorkflow(context, ref, processing, ready),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, List queued, List processing, List ready) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildOrderIntake(context, ref, queued),
        const SizedBox(height: 24),
        _buildWorkflow(context, ref, processing, ready, isMobile: true),
      ],
    );
  }

  Widget _buildOrderIntake(BuildContext context, WidgetRef ref, List queued) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bolt, color: Color(0xFFDDB7FF)),
            SizedBox(width: 8),
            Text('Express Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFDDB7FF))),
          ],
        ),
        const SizedBox(height: 16),
        if (queued.isEmpty)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF060E20).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF464554).withValues(alpha: 0.2), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.inventory_2, size: 48, color: Color(0xFFDDB7FF)),
                SizedBox(height: 8),
                Text('No new orders in queue', style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: queued.length,
            itemBuilder: (context, index) {
              return _buildExpressOrderCard(context, ref, queued[index], index);
            },
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFC7C4D7))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF222A3D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('${queued.length}', style: const TextStyle(color: Color(0xFFC7C4D7), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _parseOptions(dynamic optionsStr) {
    if (optionsStr == null) return {};
    if (optionsStr is Map<String, dynamic>) return optionsStr;
    try {
      return jsonDecode(optionsStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Widget _buildExpressOrderCard(BuildContext context, WidgetRef ref, dynamic order, int index) {
    final shortId = order['order_id'].toString().split('-').first;
    final amount = double.tryParse(order['amount_total'].toString()) ?? 0.0;
    
    // Parse print options
    Map<String, dynamic> opts = _parseOptions(order['print_options']);
    // Fallback to first file options if needed
    if (opts.isEmpty && order['files'] != null) {
      final files = (order['files'] is String) ? jsonDecode(order['files']) : order['files'];
      if (files is List && files.isNotEmpty && files[0]['print_options'] != null) {
        opts = _parseOptions(files[0]['print_options']);
      }
    }

    final isPaid = order['payment_status'] == 'captured';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFDDB7FF), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#$shortId', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3449),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Pos ${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFC0C1FF), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDB7FF).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFFDDB7FF).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PENDING PRINT', style: TextStyle(color: Color(0xFFDDB7FF), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _detailItem('Color', opts['color'] == 'color' ? 'Full Color' : 'B&W', icon: Icons.circle, iconColor: opts['color'] == 'color' ? Colors.orange : Colors.grey),
              _detailItem('Config', '${opts['size'] ?? 'A4'} · ${opts['sides'] ?? 'Single'}'),
              _detailItem('Copies', '${opts['copies'] ?? 1}'),
              _detailItem('Binding', opts['binding'] ?? 'None'),
              _detailItem('Phone', order['customer_phone'] ?? 'N/A', icon: Icons.call),
              _detailItem('Pickup', opts['pickup_type'] == 'scheduled' ? 'Scheduled' : 'Express', iconColor: const Color(0xFFDDB7FF)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(context, ref, order['order_id'], 'processing'),
                  icon: const Icon(Icons.print, color: Color(0xFF0D0096)),
                  label: const Text('PRINT & ACCEPT', style: TextStyle(color: Color(0xFF0D0096))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0C1FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: isPaid ? Colors.greenAccent : const Color(0xFFDDB7FF),
                  side: BorderSide(color: (isPaid ? Colors.greenAccent : const Color(0xFFDDB7FF)).withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isPaid ? 'PAID' : 'UNPAID'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String title, String value, {IconData? icon, Color? iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? const Color(0xFFC0C1FF)),
              const SizedBox(width: 4),
            ],
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkflow(BuildContext context, WidgetRef ref, List processing, List ready, {bool isMobile = false}) {
    final children = [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Processing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFC0C1FF))),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFFC7C4D7), size: 20),
                  onPressed: () => ref.refresh(shopOrdersProvider),
                ),
              ],
            ),
            const Divider(color: Color(0xFF464554)),
            const SizedBox(height: 16),
            if (processing.isEmpty)
               const Center(child: Padding(
                 padding: EdgeInsets.all(24.0),
                 child: Text('No active processing', style: TextStyle(color: Colors.white54)),
               ))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: processing.length,
                itemBuilder: (context, index) {
                  return _buildProcessingCard(context, ref, processing[index]);
                },
              ),
          ],
        ),
      ),
      if (!isMobile) const SizedBox(width: 24),
      if (isMobile) const SizedBox(height: 24),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ready for Pickup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF4CD7F6))),
            const Divider(color: Color(0xFF464554)),
            const SizedBox(height: 16),
            if (ready.isEmpty)
               const Center(child: Padding(
                 padding: EdgeInsets.all(24.0),
                 child: Text('No orders ready', style: TextStyle(color: Colors.white54)),
               ))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ready.length,
                itemBuilder: (context, index) {
                  return _buildReadyCard(context, ref, ready[index]);
                },
              ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF060E20).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF464554).withValues(alpha: 0.1), width: 2),
              ),
              child: const Center(
                child: Text('END OF LIST', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ];

    if (isMobile) {
      return Column(children: children);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildProcessingCard(BuildContext context, WidgetRef ref, dynamic order) {
    final shortId = order['order_id'].toString().split('-').first;
    
    // Attempt to get file name
    String fileName = 'Document.pdf';
    if (order['files'] != null) {
      final files = (order['files'] is String) ? jsonDecode(order['files']) : order['files'];
      if (files is List && files.isNotEmpty && files[0]['original_name'] != null) {
        fileName = files[0]['original_name'];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF464554).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#$shortId', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              const Text('Printing', style: TextStyle(color: Color(0xFFC0C1FF), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF222A3D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: Color(0xFFC0C1FF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    const Text('In Progress...', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, order['order_id'], 'ready'),
                icon: const Icon(Icons.check_box),
                label: const Text('MARK READY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.greenAccent,
                ),
              ),
              IconButton(
                onPressed: () => _updateStatus(context, ref, order['order_id'], 'cancelled'),
                icon: const Icon(Icons.cancel, color: Color(0xFFFFB4AB), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadyCard(BuildContext context, WidgetRef ref, dynamic order) {
    final shortId = order['order_id'].toString().split('-').first;
    final customerPhone = order['customer_phone'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CD7F6).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#$shortId', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  Text('Phone: $customerPhone', style: const TextStyle(color: Color(0xFFC7C4D7), fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CD7F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF4CD7F6), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(context, ref, order['order_id'], 'collected'),
              icon: const Icon(Icons.how_to_reg, color: Color(0xFF00424E)),
              label: const Text('MARK COLLECTED', style: TextStyle(color: Color(0xFF00424E))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03B5D3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String orderId, String newStatus) async {
    try {
      final api = ref.read(apiProvider);
      final res = await api.patch('/shop/orders/$orderId/status', data: {'status': newStatus});
      if (res.statusCode == 200) {
        ref.invalidate(shopOrdersProvider);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: ${res.statusCode}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF060E20),
        border: Border(top: BorderSide(color: const Color(0xFF464554).withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8083FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.view_list, color: Color(0xFF0D0096)),
                Text('Live Queue', style: TextStyle(color: Color(0xFF0D0096), fontSize: 12)),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF908FA0)),
              Text('Orders', style: TextStyle(color: Color(0xFF908FA0), fontSize: 12)),
            ],
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

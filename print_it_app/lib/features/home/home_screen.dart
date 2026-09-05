import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/ambient_background.dart';

import 'shop_provider.dart';
import '../orders/order_provider.dart';
import '../../core/api/api_client.dart';
import '../auth/auth_provider.dart';

final liveOrderProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final dio = ref.read(apiProvider);
  final authState = ref.read(authProvider);
  if (authState.user == null) {
    yield null;
    return;
  }

  while (true) {
    try {
      final res = await dio.get('/orders?limit=100');
      if (res.statusCode == 200) {
        final dynamic data = res.data;
        final orders = (data is Map && data.containsKey('data')) ? data['data'] as List<dynamic> : data as List<dynamic>;
        final active = orders.firstWhere(
          (o) => ['queued', 'processing', 'ready'].contains(o['status']),
          orElse: () => null,
        );
        yield active as Map<String, dynamic>?;
      }
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 10));
  }
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'Nearby';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = ref.watch(searchQueryProvider);
    final shopsAsyncValue = ref.watch(shopsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: isDark ? const Color(0xFFCBD5E1) : Colors.black,
                  size: 22,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggle(Theme.of(context).brightness);
                },
              ),
              title: Text(
                'PrintIt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDark ? 22 : 24,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? const Color(0xFFCBD5E1) : Colors.black,
                        size: 23,
                      ),
                      tooltip: 'Notifications',
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF22D3EE) : Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111928).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.80),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.8),
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.black,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFE2E8F0) : Colors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Find print shops near you...',
                                    hintStyle: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Filter Pills (Nearby, High Rated, Express)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterPill(
                                context,
                                label: 'Nearby',
                                icon: Icons.navigation_rounded,
                                isDark: isDark,
                                isActive: _selectedFilter == 'Nearby',
                                onTap: () => setState(() => _selectedFilter = 'Nearby'),
                              ),
                              const SizedBox(width: 10),
                              _buildFilterPill(
                                context,
                                label: 'High Rated',
                                icon: Icons.star_border_rounded,
                                isDark: isDark,
                                isActive: _selectedFilter == 'High Rated',
                                onTap: () => setState(() => _selectedFilter = 'High Rated'),
                              ),
                              const SizedBox(width: 10),
                              _buildFilterPill(
                                context,
                                label: 'Express',
                                icon: Icons.bolt_rounded,
                                isDark: isDark,
                                isActive: _selectedFilter == 'Express',
                                onTap: () => setState(() => _selectedFilter = 'Express'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Actions Grid (2 Cards: Scan QR, Shops)
                        Row(
                          children: [
                            // Card 1: Scan QR (First Position!)
                            Expanded(
                              child: _buildScanQrCard(context, isDark),
                            ),
                            const SizedBox(width: 14),
                            // Card 2: Shops (Second Position!)
                            Expanded(
                              child: _buildShopsCard(context, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Nearby Shops Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Nearby Shops',
                              style: TextStyle(
                                fontSize: isDark ? 20 : 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.push('/shop-list/all?name=All%20Shops');
                              },
                              child: Text(
                                'See All',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF22D3EE) : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: isDark ? null : TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Shops List
                shopsAsyncValue.when(
                  data: (shops) {
                    var filteredShops = shops.where((shop) {
                      final name = (shop['name'] ?? '').toString().toLowerCase();
                      final address = (shop['address'] ?? '').toString().toLowerCase();
                      final query = searchQuery.toLowerCase();
                      return name.contains(query) || address.contains(query);
                    }).toList();

                    if (_selectedFilter == 'High Rated') {
                      filteredShops.sort((a, b) {
                        final rA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
                        final rB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
                        return rB.compareTo(rA);
                      });
                    }

                    if (filteredShops.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text(
                              'No print shops found.',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final shop = filteredShops[index];
                            return _buildShopCard(context, ref, shop, isDark);
                          },
                          childCount: filteredShops.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
                    ),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          'Error loading shops: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for bottom dock
              ],
            ),
          ),
        ),
      ),

          // Live Order Floating Tab
          ref.watch(liveOrderProvider).when(
            data: (activeOrder) {
              if (activeOrder == null) return const SizedBox.shrink();
              final status = activeOrder['status'] as String;
              final orderId = activeOrder['order_id'] ?? activeOrder['id'];
              return Positioned(
                bottom: 96,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => context.push('/order-tracking/$orderId'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111928).withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF06B6D4).withValues(alpha: 0.5)
                            : const Color(0xFF0284C7).withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sync_rounded, color: Color(0xFF06B6D4), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'LIVE ORDER TRACKING',
                                style: TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${status.toUpperCase()}',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF06B6D4)),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  // Filter Pill Component
  Widget _buildFilterPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isDark,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadows;

    if (isActive) {
      if (isDark) {
        bgColor = const Color(0xFF008BA3);
        textColor = Colors.white;
        border = null;
        shadows = [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      } else {
        bgColor = const Color(0xFFC9EEFE);
        textColor = Colors.black;
        border = Border.all(color: const Color(0xFF7DD3FC), width: 1.2);
        shadows = [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
      }
    } else {
      if (isDark) {
        bgColor = const Color(0xFF141B2D);
        textColor = const Color(0xFFCBD5E1);
        border = Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5));
        shadows = null;
      } else {
        bgColor = Colors.white.withValues(alpha: 0.65);
        textColor = Colors.black;
        border = Border.all(color: const Color(0xFFE2E8F0));
        shadows = null;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: border,
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Action: Scan QR Card (Strictly matches Stitch designs)
  Widget _buildScanQrCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        context.push('/qr-scanner');
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF132C3F),
                          Color(0xFF0E2133),
                        ],
                      )
                    : null,
                color: isDark ? null : const Color(0xFFD1FAE5).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(isDark ? 22 : 26),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.25)
                      : const Color(0xFFA7F3D0),
                  width: isDark ? 1.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                        : const Color(0xFF059669).withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14B8A6).withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 30,
                    color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF047857),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan QR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action: Shops Card (Strictly matches Stitch designs)
  Widget _buildShopsCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        context.push('/shop-list/all?name=All%20Shops');
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2A1B4E),
                          Color(0xFF1D1438),
                        ],
                      )
                    : null,
                color: isDark ? null : const Color(0xFFEDE2FE).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(isDark ? 22 : 26),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFA855F7).withValues(alpha: 0.25)
                      : const Color(0xFFD9C4FD),
                  width: isDark ? 1.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                        : const Color(0xFF9333EA).withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFA855F7).withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 30,
                    color: isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shops',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Shop Card (Strictly matches Stitch designs for both Dark & Light)
  Widget _buildShopCard(BuildContext context, WidgetRef ref, Map<String, dynamic> shop, bool isDark) {
    final isOpen = shop['is_open'] ?? true;
    final rating = shop['rating']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF121929).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.75),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFF0C4A6E).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Shop Name & Verified / Rating Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop['name'] ?? 'Print Shop',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop['address'] ?? 'Pune',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Verified Badge (Stitch mint/teal badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF092D3B) : const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF06B6D4).withValues(alpha: 0.35)
                          : const Color(0xFF5EEAD4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF134E4A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Middle Row: Status & Hours & Optional Rating
            Row(
              children: [
                // Glowing dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? (isDark ? const Color(0xFF22D3EE) : const Color(0xFF10B981))
                        : Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isOpen
                            ? (isDark
                                ? const Color(0xFF22D3EE).withValues(alpha: 0.8)
                                : const Color(0xFF10B981).withValues(alpha: 0.6))
                            : Colors.redAccent.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOpen ? 'Open Now' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOpen
                        ? (isDark ? const Color(0xFF22D3EE) : const Color(0xFF047857))
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 6),
                Text('•', style: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.black38)),
                const SizedBox(width: 6),
                Text(
                  'Hours: ${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '18:00'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                if (rating != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),

            // Bottom CTA Button: Order Now
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: isDark
                      ? const Color(0xFF1798D1).withValues(alpha: 0.3)
                      : const Color(0xFF0284C7).withValues(alpha: 0.25),
                ),
                onPressed: () {
                  final shopId = (shop['shop_id'] ?? shop['id']).toString();
                  if (shopId.isNotEmpty) {
                    final priceBw = double.tryParse(shop['price_bw']?.toString() ?? '') ?? 0.10;
                    final priceColor = double.tryParse(shop['price_color']?.toString() ?? '') ?? 0.45;
                    final rules = shop['pricing_rules'] as List<dynamic>? ?? [];

                    ref.read(orderProvider.notifier).setShop(shopId, shop['name']?.toString() ?? '');
                    ref.read(orderProvider.notifier).setPrices(priceBw, priceColor, rules);
                    context.push('/upload-document/$shopId');
                  }
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF1798D1), Color(0xFF7154F8)]
                          : const [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Order Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Dock (Strictly matches Stitch design)
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
            // Tab 1: Home (Active)
            _buildNavItem(
              context,
              icon: Icons.grid_view_rounded,
              label: 'Home',
              isActive: true,
              isDark: isDark,
              onTap: () {},
            ),
            // Tab 2: Orders
            _buildNavItem(
              context,
              icon: Icons.description_outlined,
              label: 'Orders',
              isActive: false,
              isDark: isDark,
              onTap: () => context.push('/orders'),
            ),
            // Tab 3: Profile
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
    final activeColor = isDark ? const Color(0xFF22D3EE) : const Color(0xFF0284C7);
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
                  ? (isDark ? const Color(0xFF14324F) : const Color(0xFFE0F2FE))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: (isActive && isDark)
                  ? [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
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

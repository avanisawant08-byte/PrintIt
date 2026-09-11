import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).toggle(Theme.of(context).brightness);
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo_cropped.png',
                      height: 28,
                      width: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PrintIt',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDark ? 22 : 24,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
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
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
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
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedFilter = 'Nearby');
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildFilterPill(
                                context,
                                label: 'High Rated',
                                icon: Icons.star_border_rounded,
                                isDark: isDark,
                                isActive: _selectedFilter == 'High Rated',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedFilter = 'High Rated');
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildFilterPill(
                                context,
                                label: 'Express',
                                icon: Icons.bolt_rounded,
                                isDark: isDark,
                                isActive: _selectedFilter == 'Express',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedFilter = 'Express');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Actions Grid (2 Cards: Scan QR, Campus Store)
                        Row(
                          children: [
                            // Card 1: Scan QR (First Position!)
                            Expanded(
                              child: _buildScanQrCard(context, isDark),
                            ),
                            const SizedBox(width: 14),
                            // Card 2: Campus Store (Second Position!)
                            Expanded(
                              child: _buildStoreCard(context, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

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

          // Live Order Floating Tab (Apple-style Dynamic Island Live Activity Pill)
          ref.watch(liveOrderProvider).when(
            data: (activeOrder) {
              if (activeOrder == null) return const SizedBox.shrink();
              return Positioned(
                bottom: 96,
                left: 16,
                right: 16,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: RepaintBoundary(
                      child: _LiveOrderPill(
                        activeOrder: activeOrder,
                        isDark: isDark,
                      ),
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
        bgColor = const Color(0xFF0284C7);
        textColor = Colors.white;
        border = Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.0);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
        HapticFeedback.lightImpact();
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
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.35)
                      : const Color(0xFFA7F3D0),
                  width: isDark ? 1.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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

  // Quick Action: Campus Store Card (Replaces redundant shops card)
  Widget _buildStoreCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/store');
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
                          Color(0xFF0F2238),
                          Color(0xFF0A1829),
                        ],
                      )
                    : null,
                color: isDark ? null : const Color(0xFFE0F2FE).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(isDark ? 22 : 26),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFFBAE6FD),
                  width: isDark ? 1.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 30,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Store',
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
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0x150F172A),
              blurRadius: 20,
              offset: const Offset(0, 6),
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
                // Status indicator dot (No glow)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFF10B981) : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOpen ? 'Open Now' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOpen
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
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
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
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
            // Tab 2: Store
            _buildNavItem(
              context,
              icon: Icons.storefront_rounded,
              label: 'Store',
              isActive: false,
              isDark: isDark,
              onTap: () => context.push('/store'),
            ),
            // Tab 3: Orders
            _buildNavItem(
              context,
              icon: Icons.description_outlined,
              label: 'Orders',
              isActive: false,
              isDark: isDark,
              onTap: () => context.push('/orders'),
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

/// Apple-style Dynamic Island / Live Activity frosted glass pill with 60fps lightweight animations.
class _LiveOrderPill extends StatefulWidget {
  final Map<String, dynamic> activeOrder;
  final bool isDark;

  const _LiveOrderPill({
    required this.activeOrder,
    required this.isDark,
  });

  @override
  State<_LiveOrderPill> createState() => _LiveOrderPillState();
}

class _LiveOrderPillState extends State<_LiveOrderPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // Ultra lightweight 2.2-second smooth breath animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = widget.activeOrder;
    final isDark = widget.isDark;
    final status =
        (activeOrder['status'] ?? 'processing').toString().toLowerCase();
    final orderId =
        (activeOrder['order_id'] ?? activeOrder['id'] ?? '').toString();
    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    // Apple-style semantic color tokens & microcopy
    final Color accentColor;
    final IconData statusIcon;
    final String title;
    final String subtitle;

    switch (status) {
      case 'queued':
        accentColor = const Color(0xFFF59E0B); // Amber
        statusIcon = Icons.hourglass_top_rounded;
        title = 'Order in Queue';
        subtitle = 'Waiting for printer • Tap to track';
        break;
      case 'ready':
        accentColor = const Color(0xFF10B981); // Emerald
        statusIcon = Icons.check_circle_rounded;
        title = 'Ready for Pickup';
        subtitle = 'Order is ready • Tap for QR code';
        break;
      case 'processing':
      default:
        accentColor = const Color(0xFF0284C7); // Brand Sapphire Blue
        statusIcon = Icons.print_rounded;
        title = 'Printing in Progress';
        subtitle = 'Shop is printing • Tap to track';
        break;
    }

    final surfaceColor1 = isDark
        ? const Color(0xFF131C2E).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.90);
    final surfaceColor2 = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.80);
    final isInteractive = _isHovered || _isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => context.push('/order-tracking/$orderId'),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.40)
                      : const Color(0x180F172A),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                // Persistent ambient status aura - visible on smartphones without hover!
                BoxShadow(
                  color: accentColor.withValues(
                    alpha: isInteractive
                        ? (isDark ? 0.32 : 0.22)
                        : (isDark ? 0.18 : 0.12),
                  ),
                  blurRadius: isInteractive ? 26 : 20,
                  spreadRadius: isInteractive ? 1 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: dart_ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [surfaceColor1, surfaceColor2],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isInteractive
                          ? accentColor.withValues(alpha: isDark ? 0.55 : 0.45)
                          : accentColor.withValues(alpha: isDark ? 0.24 : 0.18),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status Icon Squircle
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color:
                              accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor
                                .withValues(alpha: isDark ? 0.30 : 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            statusIcon,
                            color: accentColor,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (shortId.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : const Color(0xFFE2E8F0),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      '#$shortId',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                // Pulsing live indicator dot (lightweight, isolated builder)
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseScale.value,
                                            child: Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: accentColor.withValues(
                                                    alpha: _pulseOpacity.value),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Sleek Apple-style Arrow Chip
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


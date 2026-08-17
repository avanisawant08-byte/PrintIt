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
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final shopsAsyncValue = ref.watch(shopsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PrintIt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark 
              ? Icons.light_mode 
              : Icons.dark_mode, 
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggle(Theme.of(context).brightness);
          },
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Box
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Icon(Icons.search, color: Colors.grey),
                              ),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  decoration: const InputDecoration(
                                    hintText: 'Find print shops near you...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip(context, 'Nearby', Icons.near_me, isActive: true),
                              SizedBox(width: 8),
                              _buildChip(context, 'High Rated', Icons.star_outline),
                              SizedBox(width: 8),
                              _buildChip(context, 'Express', Icons.bolt),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        // Grid Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionGridButton(
                                context,
                                'Upload',
                                Icons.upload_file,
                                const Color(0xFF0EA5E9), // sky-500
                                onTap: () {
                                  context.push('/express-pickup');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionGridButton(
                                context,
                                'Shops',
                                Icons.storefront,
                                const Color(0xFFA855F7), // purple-500
                                onTap: () {
                                  context.push('/shop-list/all?name=All%20Shops');
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby Shops',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'See All', 
                                style: TextStyle(
                                  color: Color(0xFF22D3EE), // cyan-400
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Shops List
                shopsAsyncValue.when(
                  data: (shops) {
                    final filteredShops = shops.where((shop) {
                      final name = (shop['name'] ?? '').toString().toLowerCase();
                      final address = (shop['address'] ?? '').toString().toLowerCase();
                      final query = searchQuery.toLowerCase();
                      return name.contains(query) || address.contains(query);
                    }).toList();

                    if (filteredShops.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text('No shops found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final shop = filteredShops[index];
                            return _buildShopCard(context, ref, shop);
                          },
                          childCount: filteredShops.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err', style: TextStyle(color: Colors.redAccent)))),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom nav spacer
              ],
            ),
          ),
          
          // Live Order Floating Tab
          ref.watch(liveOrderProvider).when(
            data: (activeOrder) {
              if (activeOrder == null) return const SizedBox.shrink();
              final status = activeOrder['status'] as String;
              final orderId = activeOrder['order_id'] ?? activeOrder['id'];
              return Positioned(
                bottom: 100, // Just above the bottom nav
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => context.push('/order-tracking/$orderId'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00daf3).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00daf3).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00daf3).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sync, color: Color(0xFF00daf3), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Live Order', style: TextStyle(color: Color(0xFF00daf3), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              Text('Status: ${status.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF00daf3)),
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0891B2).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? const Color(0xFF06B6D4).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? const Color(0xFF22D3EE) : Colors.grey[300],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFF22D3EE) : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGridButton(BuildContext context, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, WidgetRef ref, Map<String, dynamic> shop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop['name'] ?? 'Shop',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop['address'] ?? 'Address unavailable',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(
                        '4.9', // Hardcoded rating for now
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (shop['is_open'] ?? true) ? const Color(0xFF22D3EE) : const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  (shop['is_open'] ?? true) ? 'Open Now' : 'Closed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: (shop['is_open'] ?? true) ? const Color(0xFF22D3EE) : const Color(0xFFFF5252),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  'Hours: ${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '18:00'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                ),
                onPressed: () {
                  final shopId = shop['shop_id'] ?? shop['id'];
                  if (shopId != null) {
                    final priceBw = double.tryParse(shop['price_bw']?.toString() ?? '') ?? 0.10;
                    final priceColor = double.tryParse(shop['price_color']?.toString() ?? '') ?? 0.45;
                    final rules = shop['pricing_rules'] as List<dynamic>? ?? [];

                    ref.read(orderProvider.notifier).setShop(shop['shop_id']?.toString() ?? '', shop['name']?.toString() ?? '');
                    ref.read(orderProvider.notifier).setPrices(priceBw, priceColor, rules);
                    context.push('/upload-document/$shopId');
                  }
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Order Now',
                      style: TextStyle(
                        fontSize: 18,
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2A).withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(context, Icons.grid_view, 'Home', true, () {}),
                _buildNavItem(context, Icons.description_outlined, 'Orders', false, () => context.push('/orders')),
                _buildNavItem(context, Icons.person_outline, 'Profile', false, () => context.push('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4F46E5).withValues(alpha: 0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon, 
              color: isActive ? const Color(0xFF22D3EE) : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF22D3EE) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

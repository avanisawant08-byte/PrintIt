import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'browse_categories_screen.dart';

final shopDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, shopId) async {
  final apiClient = ref.watch(apiProvider);
  final response = await apiClient.get('/public/shops/$shopId');
  if (response.statusCode == 200) {
    return response.data;
  }
  throw Exception('Failed to load shop details');
});

final shopManualsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, shopId) async {
  final api = ref.read(apiProvider);
  final res = await api.get('/products');
  final allManuals = res.data as List<dynamic>;
  return allManuals.where((m) => m['shop_id'].toString() == shopId).toList();
});

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsyncValue = ref.watch(shopDetailProvider(shopId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: shopAsyncValue.when(
              data: (shop) {
                final capabilitiesAsyncValue = ref.watch(capabilitiesProvider);
                final manualsAsyncValue = ref.watch(shopManualsProvider(shopId));
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, shop),
                      const SizedBox(height: 24),
                      manualsAsyncValue.when(
                        data: (manuals) => _buildManualsSection(context, manuals),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const SizedBox(),
                      ),
                      const SizedBox(height: 24),
                      capabilitiesAsyncValue.when(
                        data: (masterCaps) => _buildProductsGrid(context, shop, masterCaps),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const SizedBox(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop['name'] ?? 'Shop Name',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                shop['address'] ?? 'Address unavailable',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (shop['phone'] != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                shop['phone'],
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: (shop['is_open'] ?? true) ? Color(0xFF3BAFF2) : Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              (shop['is_open'] ?? true) 
                  ? 'Open Now (${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '18:00'})'
                  : 'Closed (${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '18:00'})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: (shop['is_open'] ?? true) ? Color(0xFF3BAFF2) : Color(0xFFFF5252),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getIconForCapability(String id) {
    switch (id) {
      case 'books': return Icons.book;
      case 'spiral_binding': return Icons.library_books;
      case 'lamination': return Icons.layers;
      case 'large_format': return Icons.map;
      case 'id_cards': return Icons.badge;
      case 'notebooks': return Icons.import_contacts;
      case 'bulk_printing': return Icons.print;
      case 'same_day': return Icons.flash_on;
      default: return Icons.print;
    }
  }

  Widget _buildProductsGrid(BuildContext context, Map<String, dynamic> shop, List<dynamic> masterCaps) {
    final capabilities = shop['capabilities'] as List<dynamic>? ?? [];
    if (capabilities.isEmpty) return const SizedBox();

    // Filter master caps to only those the shop has
    final shopProducts = masterCaps.where((cap) => capabilities.contains(cap['id'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products & Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: shopProducts.length,
          itemBuilder: (context, index) {
            final product = shopProducts[index];
            return GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF3BAFF2).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCapability(product['id']),
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManualsSection(BuildContext context, List<dynamic> manuals) {
    if (manuals.isEmpty) return const SizedBox();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Manuals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: manuals.length,
          itemBuilder: (context, index) {
            final manual = manuals[index];
            final stock = manual['stock_count'] as int;
            final isOutOfStock = stock <= 0;

            return GestureDetector(
              onTap: () {
                context.push('/manual-detail', extra: manual);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              image: manual['cover_photo_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(manual['cover_photo_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: manual['cover_photo_url'] == null
                              ? const Icon(Icons.book, size: 48, color: Colors.grey)
                              : null,
                          ),
                          if (isOutOfStock)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Out of Stock',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                          else if (stock <= 5)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Only $stock left',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            manual['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            manual['branch'],
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${manual['price']}',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

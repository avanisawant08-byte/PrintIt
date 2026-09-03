import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../home/shop_provider.dart';
import 'order_provider.dart';

class SelectShopScreen extends ConsumerWidget {
  const SelectShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsyncValue = ref.watch(shopsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Select a Shop', style: TextStyle(color: Color(0xFFE2E0FB), fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF3BAFF2)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: shopsAsyncValue.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return Center(child: Text('No shops found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return _buildShopCard(context, ref, shop);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, WidgetRef ref, Map<String, dynamic> shop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shop['name'] ?? 'Print Shop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE2E0FB)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E31), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text(shop['rating']?.toString() ?? '4.5', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFFB9CACB), size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shop['address'] ?? 'Address unavailable',
                    style: TextStyle(color: Color(0xFFB9CACB), fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final shopId = shop['shop_id'] ?? shop['id'];
                  final priceBw = double.tryParse(shop['price_bw']?.toString() ?? '') ?? 0.10;
                  final priceColor = double.tryParse(shop['price_color']?.toString() ?? '') ?? 0.45;
                  final rules = shop['pricing_rules'] as List<dynamic>? ?? [];
                  
                  ref.read(orderProvider.notifier).setShop(shopId?.toString() ?? '', shop['name']?.toString() ?? '');
                  ref.read(orderProvider.notifier).setPrices(priceBw, priceColor, rules);
                  
                  context.push('/document-config');
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3BAFF2), Color(0xFF7000FF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('Select Shop', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

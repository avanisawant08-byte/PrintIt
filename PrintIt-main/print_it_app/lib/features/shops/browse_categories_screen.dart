import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

final capabilitiesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiProvider);
  final response = await apiClient.get('/public/capabilities');
  if (response.statusCode == 200) {
    return response.data;
  }
  throw Exception('Failed to load capabilities');
});

class BrowseCategoriesScreen extends ConsumerWidget {
  const BrowseCategoriesScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilitiesAsyncValue = ref.watch(capabilitiesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Browse Services',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: capabilitiesAsyncValue.when(
              data: (capabilities) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: capabilities.length,
                  itemBuilder: (context, index) {
                    final cap = capabilities[index];
                    return _buildCategoryCard(context, cap);
                  },
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

  Widget _buildCategoryCard(BuildContext context, dynamic cap) {
    return GestureDetector(
      onTap: () {
        context.push('/shop-list/${cap['id']}?name=${Uri.encodeComponent(cap['name'])}');
      },
      child: GlassContainer(
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
                _getIconForCapability(cap['id']),
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cap['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              cap['description'],
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
      ),
    );
  }
}

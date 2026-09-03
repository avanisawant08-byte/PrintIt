import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'browse_categories_screen.dart'; // To reuse capabilitiesProvider if possible, or define here

final shopCapabilitiesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final apiClient = ref.watch(apiProvider);
  final response = await apiClient.get('/shop/capabilities');
  if (response.statusCode == 200) {
    return List<String>.from(response.data);
  }
  throw Exception('Failed to load shop capabilities');
});

class ManageShopServicesScreen extends ConsumerWidget {
  const ManageShopServicesScreen({super.key});

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

  Future<void> _toggleCapability(BuildContext context, WidgetRef ref, String capabilityId, bool isCurrentlyActive) async {
    final apiClient = ref.read(apiProvider);
    try {
      if (isCurrentlyActive) {
        // Remove capability
        await apiClient.delete('/shop/capabilities/$capabilityId');
      } else {
        // Add capability
        await apiClient.post('/shop/capabilities', data: {'capability': capabilityId});
      }
      ref.invalidate(shopCapabilitiesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update service')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterCapabilitiesAsync = ref.watch(capabilitiesProvider);
    final shopCapabilitiesAsync = ref.watch(shopCapabilitiesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Manage Services',
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
            child: masterCapabilitiesAsync.when(
              data: (masterCaps) {
                return shopCapabilitiesAsync.when(
                  data: (activeCaps) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: masterCaps.length,
                      itemBuilder: (context, index) {
                        final cap = masterCaps[index];
                        final isActive = activeCaps.contains(cap['id']);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isActive ? Color(0xFF3BAFF2).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconForCapability(cap['id']),
                                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cap['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cap['description'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeThumbColor: Theme.of(context).colorScheme.primary,
                                  onChanged: (val) {
                                    _toggleCapability(context, ref, cap['id'], isActive);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.redAccent))),
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
}

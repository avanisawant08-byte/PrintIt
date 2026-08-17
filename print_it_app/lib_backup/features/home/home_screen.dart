import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_provider.dart';
import 'shop_provider.dart';
import '../orders/order_provider.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsyncValue = ref.watch(shopsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111125).withValues(alpha: 0.4),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
            // We use simple blur via backdrop filter in flexible space if needed
            // Or just rely on flutter's AppBar transparency
          ),
        ),
        title: const Text(
          'PrintIt',
          style: TextStyle(
            color: Color(0xFF7DF4FF), // primary-fixed
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFFDBFCFF)),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          if (authState.user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white54),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Box
                        GlassContainer(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: 12,
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Color(0xFFB9CACB)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(color: Color(0xFFE2E0FB)),
                                  decoration: InputDecoration(
                                    hintText: 'Find print shops near you...',
                                    hintStyle: TextStyle(color: const Color(0xFFB9CACB).withValues(alpha: 0.5)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip(context, 'Nearby', Icons.near_me, isActive: true),
                              const SizedBox(width: 8),
                              _buildChip(context, 'High Rated', Icons.star_outline),
                              const SizedBox(width: 8),
                              _buildChip(context, 'Express', Icons.bolt),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Quick Actions
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            _buildQuickAction(
                              context, 'Upload', Icons.upload, const Color(0xFF00F0FF).withValues(alpha: 0.2), const Color(0xFFDBFCFF),
                              onTap: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'jpg', 'png'],
                                  withData: true,
                                );

                                if (result != null) {
                                  final file = result.files.first;
                                  int pages = 1;
                                  
                                  if (file.extension?.toLowerCase() == 'pdf') {
                                    try {
                                      List<int>? bytes = file.bytes;
                                      if (bytes == null && file.path != null) {
                                        bytes = await File(file.path!).readAsBytes();
                                      }
                                      
                                      if (bytes != null) {
                                        final PdfDocument document = PdfDocument(inputBytes: bytes);
                                        pages = document.pages.count;
                                        document.dispose();
                                      }
                                    } catch (e) {
                                      debugPrint('Error parsing PDF: \$e');
                                    }
                                  }

                                  ref.read(orderProvider.notifier).setPages(pages);
                                  ref.read(orderProvider.notifier).setFile(file);
                                  
                                  if (context.mounted) {
                                    context.push('/select-shop');
                                  }
                                }
                              },
                            ),
                            _buildQuickAction(context, 'Nearby', Icons.map, const Color(0xFF7000FF).withValues(alpha: 0.3), const Color(0xFFD1BCFF)),
                            _buildQuickAction(context, 'Track', Icons.track_changes, const Color(0xFF333348), const Color(0xFF7DF4FF)),
                            _buildQuickAction(context, 'History', Icons.history, const Color(0xFF1A1A2D).withValues(alpha: 0.4), const Color(0xFFB9CACB)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Nearby Shops',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFE2E0FB),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See All', style: TextStyle(color: Color(0xFFDBFCFF))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Shops List
                shopsAsyncValue.when(
                  data: (shops) {
                    if (shops.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Text('No shops found.', style: TextStyle(color: Colors.white70)),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final shop = shops[index];
                            return _buildShopCard(context, ref, shop);
                          },
                          childCount: shops.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)))),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom nav spacer
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00F0FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isActive ? const Color(0xFFDBFCFF) : const Color(0xFFB9CACB)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFFDBFCFF) : const Color(0xFFB9CACB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color bgColor, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 0,
                )
              ],
            ),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE2E0FB),
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
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7DF4FF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 24) return const SizedBox();
                          return Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFFB9CACB)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop['address'] ?? 'Address unavailable',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFB9CACB),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28283C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFFFB4AB)),
                      const SizedBox(width: 4),
                      const Text(
                        '4.9', // Hardcoded rating for now
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE2E0FB),
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
                    color: (shop['is_open'] ?? true) ? const Color(0xFF00F0FF) : const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ((shop['is_open'] ?? true) ? const Color(0xFF00F0FF) : const Color(0xFFFF5252)).withValues(alpha: 0.8),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (shop['is_open'] ?? true) 
                        ? 'Open Now • Hours: ${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '18:00'}'
                        : 'Closed • Hours: ${shop['opening_time'] ?? '09:00'} - ${shop['closing_time'] ?? '18:00'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: (shop['is_open'] ?? true) ? const Color(0xFF00F0FF) : const Color(0xFFFF5252),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF7000FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
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
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Order Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
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
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2D).withValues(alpha: 0.4),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.grid_view, 'Home', true, () {}),
              _buildNavItem(context, Icons.description, 'Orders', false, () => context.push('/orders')),
              _buildNavItem(context, Icons.person, 'Profile', false, () => context.push('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7000FF).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00DBE9).withValues(alpha: 0.3), blurRadius: 10)
                ],
              ),
              child: Icon(icon, color: const Color(0xFFDBFCFF)),
            )
          else
            Icon(icon, color: const Color(0xFFB9CACB).withValues(alpha: 0.7)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFFDBFCFF) : const Color(0xFFB9CACB).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

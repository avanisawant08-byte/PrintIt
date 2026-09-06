import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import 'store_models.dart';
import 'store_cart_provider.dart';
import 'store_cart_sheet.dart';

const Color emerald = Color(0xFF10B981);

final productShopsProvider = FutureProvider.autoDispose.family<List<ShopStockListing>, String>((ref, productId) async {
  final api = ref.read(apiProvider);
  final res = await api.get('/store/products/$productId/shops');
  final List<dynamic> data = res.data is List ? res.data : (res.data['shops'] ?? []);
  return data.map((json) => ShopStockListing.fromJson(json)).toList();
});

final shopRecommendationsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, shopId) async {
  final api = ref.read(apiProvider);
  final res = await api.get('/store/shops/$shopId/products');
  return res.data is List ? res.data : (res.data['products'] ?? []);
});

class StoreProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final CatalogProduct? product;

  const StoreProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  ConsumerState<StoreProductDetailScreen> createState() => _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends ConsumerState<StoreProductDetailScreen> {
  CatalogProduct? _product;
  bool _isLoadingProduct = false;
  String? _activeShopIdForSuggestions;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product == null) {
      _fetchProductDetails();
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() => _isLoadingProduct = true);
    try {
      final api = ref.read(apiProvider);
      final res = await api.get('/store/products/${widget.productId}');
      if (mounted) {
        setState(() {
          _product = CatalogProduct.fromJson(res.data);
          _isLoadingProduct = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  void _handleAddToCart({
    required ShopStockListing shop,
    required CatalogProduct product,
    int quantity = 1,
  }) {
    final cartItem = StoreCartItem(
      productId: product.productId,
      inventoryId: shop.inventoryId,
      title: product.title,
      category: product.category,
      coverPhotoUrl: product.coverPhotoUrl,
      unitPrice: shop.price,
      quantity: quantity,
      maxStock: shop.stockCount,
    );

    final cartShop = StoreCartShop(
      shopId: shop.shopId,
      shopName: shop.shopName,
      shopCode: shop.shopCode,
      address: shop.address,
    );

    final result = ref.read(storeCartProvider.notifier).addToCart(
      shop: cartShop,
      item: cartItem,
      addQuantity: quantity,
    );

    if (result.status == CartAddStatus.success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF0F172A),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: emerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added to cart (${shop.shopName})',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const StoreCartSheet(),
              );
            },
          ),
        ),
      );
    } else if (result.status == CartAddStatus.shopConflict) {
      _showShopConflictDialog(
        existingShop: result.existingShopName ?? 'another shop',
        newShop: cartShop,
        newItem: cartItem,
      );
    } else if (result.status == CartAddStatus.outOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item is currently out of stock at this shop')),
      );
    }
  }

  void _showShopConflictDialog({
    required String existingShop,
    required StoreCartShop newShop,
    required StoreCartItem newItem,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Replace Cart Items?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Your store cart currently contains items from "$existingShop".\n\nTo ensure convenient in-store counter pickup, each order can only be placed with one shop at a time.\n\nReplace your cart with items from "${newShop.shopName}"?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Existing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(storeCartProvider.notifier).replaceCartWithItem(
                shop: newShop,
                item: newItem,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cart updated with items from ${newShop.shopName}'),
                ),
              );
            },
            child: const Text('Replace Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shopsAsync = ref.watch(productShopsProvider(widget.productId));
    final cartState = ref.watch(storeCartProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF090F1D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: Text(
          _product?.title ?? 'Product Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_bag_outlined, color: isDark ? Colors.white : Colors.black87),
                if (cartState.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cartState.totalItemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const StoreCartSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: _isLoadingProduct
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _product == null
                    ? const Center(child: Text('Product not found'))
                    : CustomScrollView(
                        slivers: [
                          // Master Product Info Card
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildMasterProductHeader(context, _product!, isDark, theme),
                            ),
                          ),

                          // Section Header: "Available at these shops"
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Icon(Icons.storefront_rounded, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Available at these Shops',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Shops Stock Listings
                          shopsAsync.when(
                            loading: () => const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: CircularProgressIndicator.adaptive()),
                              ),
                            ),
                            error: (err, _) => SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Failed to load shop stock', style: TextStyle(color: theme.colorScheme.error)),
                              ),
                            ),
                            data: (shops) {
                              if (shops.isEmpty) {
                                return SliverToBoxAdapter(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Currently out of stock across all registered campus shops.',
                                        style: TextStyle(fontSize: 13, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // Set default active shop for suggestions if not yet set
                              if (_activeShopIdForSuggestions == null && shops.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _activeShopIdForSuggestions = shops.first.shopId;
                                    });
                                  }
                                });
                              }

                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final shop = shops[index];
                                    return _buildShopStockCard(context, shop, _product!, cartState, isDark, theme);
                                  },
                                  childCount: shops.length,
                                ),
                              );
                            },
                          ),

                          // Cross-Selling: "More from this shop" Section
                          if (_activeShopIdForSuggestions != null)
                            SliverToBoxAdapter(
                              child: _buildShopRecommendations(
                                context,
                                _activeShopIdForSuggestions!,
                                isDark,
                                theme,
                              ),
                            ),

                          // Bottom spacing for cart bar
                          SliverToBoxAdapter(
                            child: SizedBox(height: cartState.isNotEmpty ? 100 : 40),
                          ),
                        ],
                      ),
          ),

          // Floating Cart Bar at bottom
          if (cartState.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const StoreCartSheet(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${cartState.totalItemCount} in Cart (${cartState.shop?.shopName})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${cartState.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMasterProductHeader(
    BuildContext context,
    CatalogProduct product,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Photo
              Container(
                width: 90,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: product.coverPhotoUrl != null && product.coverPhotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          product.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.book, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.branch ?? "General"} • ${product.courseType ?? "Degree"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    if (product.subject != null && product.subject!.isNotEmpty)
                      Text(
                        'Subject: ${product.subject}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    if (product.author != null && product.author!.isNotEmpty)
                      Text(
                        'Author: ${product.author}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              product.description!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShopStockCard(
    BuildContext context,
    ShopStockListing shop,
    CatalogProduct product,
    StoreCartState cartState,
    bool isDark,
    ThemeData theme,
  ) {
    final isOutOfStock = shop.stockCount <= 0;
    final isLowStock = !isOutOfStock && shop.stockCount <= 3;
    final inCartItem = cartState.shop?.shopId == shop.shopId ? cartState.findItem(shop.inventoryId) : null;
    final isInCart = inCartItem != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInCart
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Shop info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shop.shopName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (shop.shopCode != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shop.shopCode!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (shop.address != null)
                  Text(
                    shop.address!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                // Stock pill
                if (isOutOfStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Out of Stock',
                      style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Only ${shop.stockCount} left',
                      style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${shop.stockCount} copies in stock',
                      style: const TextStyle(fontSize: 10, color: emerald, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Price & Add to Cart button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${shop.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              if (isOutOfStock)
                FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(80, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sold Out', style: TextStyle(fontSize: 11)),
                )
              else if (isInCart)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: isDark ? Colors.white70 : Colors.black87,
                      onPressed: () {
                        ref.read(storeCartProvider.notifier).decrementQuantity(shop.inventoryId);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${inCartItem.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: theme.colorScheme.primary,
                      onPressed: inCartItem.quantity < shop.stockCount
                          ? () {
                              ref.read(storeCartProvider.notifier).incrementQuantity(shop.inventoryId);
                            }
                          : null,
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeShopIdForSuggestions = shop.shopId;
                    });
                    _handleAddToCart(shop: shop, product: product);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(90, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                  label: const Text('Add to Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopRecommendations(
    BuildContext context,
    String shopId,
    bool isDark,
    ThemeData theme,
  ) {
    final recommendationsAsync = ref.watch(shopRecommendationsProvider(shopId));

    return recommendationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        // Exclude current product
        final otherItems = items.where((it) => it['product_id'] != widget.productId).toList();
        if (otherItems.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'More from this Shop',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: otherItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final it = otherItems[index];
                  final price = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
                  final stock = int.tryParse(it['stock_count']?.toString() ?? '0') ?? 0;

                  return Container(
                    width: 170,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it['title'] ?? 'Title',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${it['category'] ?? "Item"} • ${it['branch'] ?? ""}',
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (stock > 0)
                              GestureDetector(
                                onTap: () {
                                  final recShop = ShopStockListing(
                                    inventoryId: it['inventory_id'],
                                    shopId: shopId,
                                    shopName: it['shop_name'] ?? 'Print Shop',
                                    shopCode: it['shop_code'],
                                    price: price,
                                    stockCount: stock,
                                    isAvailable: true,
                                  );
                                  final recProd = CatalogProduct(
                                    productId: it['product_id'],
                                    title: it['title'],
                                    category: it['category'] ?? 'Other',
                                    minPrice: price,
                                    maxPrice: price,
                                    shopsCount: 1,
                                    totalStock: stock,
                                  );
                                  _handleAddToCart(shop: recShop, product: recProd);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 12, color: theme.colorScheme.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

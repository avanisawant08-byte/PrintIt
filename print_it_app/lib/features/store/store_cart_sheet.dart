import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../wallet/wallet_provider.dart';
import 'store_models.dart';
import 'store_cart_provider.dart';
import 'store_product_detail_screen.dart';

class StoreCartSheet extends ConsumerStatefulWidget {
  const StoreCartSheet({super.key});

  @override
  ConsumerState<StoreCartSheet> createState() => _StoreCartSheetState();
}

class _StoreCartSheetState extends ConsumerState<StoreCartSheet> {
  String _paymentMethod = 'wallet'; // 'wallet' | 'razorpay'
  bool _isPlacingOrder = false;

  static const Color emerald = Color(0xFF10B981);

  Future<void> _handleCheckout(StoreCartState cartState) async {
    if (cartState.isEmpty || cartState.shop == null) return;

    setState(() => _isPlacingOrder = true);

    try {
      final api = ref.read(apiProvider);

      final payload = {
        'shop_id': cartState.shop!.shopId,
        'items': cartState.items.map((i) => i.toJson()).toList(),
        'payment_method': _paymentMethod,
        'payment_details': {
          'channel': _paymentMethod == 'wallet' ? 'in_app_wallet' : 'online_upi',
        },
      };

      final res = await api.post('/store/orders', data: payload);

      if (res.statusCode == 201 && res.data['success'] == true) {
        final orderData = res.data['order'];
        final pickupCode = res.data['pickup_code']?.toString() ?? orderData['pickup_code']?.toString() ?? '----';

        // Clear cart
        ref.read(storeCartProvider.notifier).clearCart();
        // Refresh wallet
        ref.invalidate(walletProvider);

        if (mounted) {
          Navigator.of(context).pop(); // close sheet
          _showPickupSuccessDialog(orderData, pickupCode);
        }
      } else {
        throw Exception(res.data['error'] ?? 'Order checkout failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showPickupSuccessDialog(Map<String, dynamic> order, String pickupCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: emerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: emerald, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your items are reserved at ${order['shop_name'] ?? 'the shop'}.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 4-Digit Pickup Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR 4-DIGIT PICKUP CODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickupCode,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Show this code at the shop counter',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/store/orders');
                },
                child: const Text('View My Store Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(storeCartProvider);
    final walletAsync = ref.watch(walletProvider);

    final walletBalance = walletAsync.when(
      data: (data) => double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0,
      loading: () => 0.0,
      error: (_, _) => 0.0,
    );

    final isWalletInsufficient = _paymentMethod == 'wallet' && walletBalance < cartState.grandTotal;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Shop info & Clear
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cartState.shop?.shopName ?? 'Store Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (cartState.shop?.shopCode != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cartState.shop!.shopCode!,
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
                      if (cartState.shop?.address != null)
                        Text(
                          cartState.shop!.address!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (cartState.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(storeCartProvider.notifier).clearCart();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content body
          Expanded(
            child: cartState.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 56, color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 12),
                        Text(
                          'Your store cart is empty',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add books or manuals from campus shops',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Cart Items List
                      ...cartState.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.coverPhotoUrl != null && item.coverPhotoUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.coverPhotoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(Icons.book, size: 24, color: Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.book, size: 24, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${item.unitPrice.toStringAsFixed(0)} each',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    onPressed: () {
                                      ref.read(storeCartProvider.notifier).decrementQuantity(item.inventoryId);
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    color: theme.colorScheme.primary,
                                    onPressed: item.quantity < item.maxStock
                                        ? () {
                                            ref.read(storeCartProvider.notifier).incrementQuantity(item.inventoryId);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      // Cross-Selling Inside Cart: "More in stock at this shop"
                      if (cartState.shop != null)
                        _buildCartRecommendations(cartState.shop!.shopId, cartState, isDark, theme),

                      const SizedBox(height: 16),

                      // Payment Method Selector
                      Text(
                        'PAYMENT METHOD (100% PREPAID)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Wallet Option
                      GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'wallet'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'wallet'
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _paymentMethod == 'wallet'
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _paymentMethod == 'wallet' ? theme.colorScheme.primary : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PrintIt Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(
                                      'Available Balance: ₹${walletBalance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isWalletInsufficient ? Colors.redAccent : (isDark ? Colors.white54 : Colors.black54),
                                        fontWeight: isWalletInsufficient ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: 'wallet',
                                groupValue: _paymentMethod,
                                onChanged: (val) => setState(() => _paymentMethod = val!),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // UPI / Online Gateway Option
                      GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'razorpay'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'razorpay'
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _paymentMethod == 'razorpay'
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payment_rounded,
                                color: _paymentMethod == 'razorpay' ? theme.colorScheme.primary : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('UPI / Cards / NetBanking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Instant secure online payment', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: 'razorpay',
                                groupValue: _paymentMethod,
                                onChanged: (val) => setState(() => _paymentMethod = val!),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bill Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Items Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('₹${cartState.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('In-Store Counter Pickup', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('FREE', style: TextStyle(fontSize: 12, color: emerald, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text(
                                  '₹${cartState.grandTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Checkout Button
          if (cartState.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isPlacingOrder || isWalletInsufficient
                      ? null
                      : () => _handleCheckout(cartState),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isWalletInsufficient
                              ? 'Insufficient Wallet Balance (Add Money)'
                              : 'Place Order & Pay ₹${cartState.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartRecommendations(
    String shopId,
    StoreCartState cartState,
    bool isDark,
    ThemeData theme,
  ) {
    final recommendationsAsync = ref.watch(shopRecommendationsProvider(shopId));

    return recommendationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        // Exclude items already in cart
        final existingProductIds = cartState.items.map((i) => i.productId).toSet();
        final unadded = items.where((it) => !existingProductIds.contains(it['product_id'])).toList();
        if (unadded.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.add_shopping_cart_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Add more from ${cartState.shop?.shopName ?? "this shop"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unadded.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final it = unadded[index];
                  final price = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
                  final stock = int.tryParse(it['stock_count']?.toString() ?? '0') ?? 0;

                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          it['title'] ?? 'Title',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                            ),
                            GestureDetector(
                              onTap: () {
                                final item = StoreCartItem(
                                  productId: it['product_id'],
                                  inventoryId: it['inventory_id'],
                                  title: it['title'],
                                  category: it['category'] ?? 'Other',
                                  unitPrice: price,
                                  quantity: 1,
                                  maxStock: stock,
                                );
                                ref.read(storeCartProvider.notifier).addToCart(
                                  shop: cartState.shop!,
                                  item: item,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('+ Add', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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

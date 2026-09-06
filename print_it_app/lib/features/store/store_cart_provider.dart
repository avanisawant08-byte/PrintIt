import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'store_models.dart';

enum CartAddStatus {
  success,
  shopConflict,
  outOfStock,
}

class CartAddResult {
  final CartAddStatus status;
  final String? existingShopName;
  final String? newShopName;

  CartAddResult({
    required this.status,
    this.existingShopName,
    this.newShopName,
  });
}

class StoreCartState {
  final StoreCartShop? shop;
  final List<StoreCartItem> items;

  const StoreCartState({
    this.shop,
    this.items = const [],
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get convenienceFee => 0.0; // Free pickup at counter
  double get grandTotal => subtotal + convenienceFee;

  StoreCartItem? findItem(String inventoryId) {
    try {
      return items.firstWhere((i) => i.inventoryId == inventoryId);
    } catch (_) {
      return null;
    }
  }

  StoreCartState copyWith({
    StoreCartShop? shop,
    List<StoreCartItem>? items,
  }) {
    return StoreCartState(
      shop: shop ?? this.shop,
      items: items ?? this.items,
    );
  }
}

class StoreCartNotifier extends Notifier<StoreCartState> {
  @override
  StoreCartState build() => const StoreCartState();

  /// Attempts to add an item to the single-shop store cart.
  /// If cart is empty or from same shop, adds/increments item.
  /// If from a different shop, returns shopConflict so UI can prompt user.
  CartAddResult addToCart({
    required StoreCartShop shop,
    required StoreCartItem item,
    int addQuantity = 1,
  }) {
    if (item.maxStock <= 0) {
      return CartAddResult(status: CartAddStatus.outOfStock);
    }

    // If cart has items from another shop, trigger confirmation
    if (state.isNotEmpty && state.shop != null && state.shop!.shopId != shop.shopId) {
      return CartAddResult(
        status: CartAddStatus.shopConflict,
        existingShopName: state.shop!.shopName,
        newShopName: shop.shopName,
      );
    }

    final existingIndex = state.items.indexWhere((i) => i.inventoryId == item.inventoryId);
    List<StoreCartItem> updatedItems = List.from(state.items);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final newQty = (existing.quantity + addQuantity).clamp(1, item.maxStock);
      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
    } else {
      updatedItems.add(item.copyWith(quantity: addQuantity.clamp(1, item.maxStock)));
    }

    state = StoreCartState(
      shop: shop,
      items: updatedItems,
    );

    return CartAddResult(status: CartAddStatus.success);
  }

  /// Replaces the entire cart with the new shop's item upon user approval
  void replaceCartWithItem({
    required StoreCartShop shop,
    required StoreCartItem item,
    int quantity = 1,
  }) {
    state = StoreCartState(
      shop: shop,
      items: [item.copyWith(quantity: quantity.clamp(1, item.maxStock))],
    );
  }

  void incrementQuantity(String inventoryId) {
    final index = state.items.indexWhere((i) => i.inventoryId == inventoryId);
    if (index >= 0) {
      final item = state.items[index];
      if (item.quantity < item.maxStock) {
        final updated = List<StoreCartItem>.from(state.items);
        updated[index] = item.copyWith(quantity: item.quantity + 1);
        state = state.copyWith(items: updated);
      }
    }
  }

  void decrementQuantity(String inventoryId) {
    final index = state.items.indexWhere((i) => i.inventoryId == inventoryId);
    if (index >= 0) {
      final item = state.items[index];
      if (item.quantity > 1) {
        final updated = List<StoreCartItem>.from(state.items);
        updated[index] = item.copyWith(quantity: item.quantity - 1);
        state = state.copyWith(items: updated);
      } else {
        removeItem(inventoryId);
      }
    }
  }

  void removeItem(String inventoryId) {
    final updated = state.items.where((i) => i.inventoryId != inventoryId).toList();
    if (updated.isEmpty) {
      state = const StoreCartState();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void clearCart() {
    state = const StoreCartState();
  }
}

final storeCartProvider = NotifierProvider<StoreCartNotifier, StoreCartState>(StoreCartNotifier.new);

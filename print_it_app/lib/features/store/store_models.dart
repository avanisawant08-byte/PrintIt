class CatalogProduct {
  final String productId;
  final String title;
  final String? description;
  final String category;
  final String? branch;
  final String? courseType;
  final String? semester;
  final String? subject;
  final String? author;
  final String? isbn;
  final String? coverPhotoUrl;
  final double minPrice;
  final double maxPrice;
  final int shopsCount;
  final int totalStock;

  CatalogProduct({
    required this.productId,
    required this.title,
    this.description,
    required this.category,
    this.branch,
    this.courseType,
    this.semester,
    this.subject,
    this.author,
    this.isbn,
    this.coverPhotoUrl,
    required this.minPrice,
    required this.maxPrice,
    required this.shopsCount,
    required this.totalStock,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      productId: json['product_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'Other',
      branch: json['branch'],
      courseType: json['course_type'],
      semester: json['semester'],
      subject: json['subject'],
      author: json['author'],
      isbn: json['isbn'],
      coverPhotoUrl: json['cover_photo_url'],
      minPrice: double.tryParse(json['min_price']?.toString() ?? '0') ?? 0.0,
      maxPrice: double.tryParse(json['max_price']?.toString() ?? '0') ?? 0.0,
      shopsCount: int.tryParse(json['shops_count']?.toString() ?? '0') ?? 0,
      totalStock: int.tryParse(json['total_stock']?.toString() ?? '0') ?? 0,
    );
  }
}

class ShopStockListing {
  final String inventoryId;
  final String shopId;
  final String shopName;
  final String? shopCode;
  final String? address;
  final String? phone;
  final double price;
  final int stockCount;
  final bool isAvailable;
  final String? distance;

  ShopStockListing({
    required this.inventoryId,
    required this.shopId,
    required this.shopName,
    this.shopCode,
    this.address,
    this.phone,
    required this.price,
    required this.stockCount,
    required this.isAvailable,
    this.distance,
  });

  factory ShopStockListing.fromJson(Map<String, dynamic> json) {
    return ShopStockListing(
      inventoryId: json['inventory_id'] ?? '',
      shopId: json['shop_id'] ?? '',
      shopName: json['shop_name'] ?? 'Print Shop',
      shopCode: json['shop_code'],
      address: json['address'],
      phone: json['phone'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stockCount: int.tryParse(json['stock_count']?.toString() ?? '0') ?? 0,
      isAvailable: json['is_available'] == true,
      distance: json['distance'],
    );
  }
}

class StoreCartItem {
  final String productId;
  final String inventoryId;
  final String title;
  final String category;
  final String? coverPhotoUrl;
  final double unitPrice;
  final int quantity;
  final int maxStock;

  StoreCartItem({
    required this.productId,
    required this.inventoryId,
    required this.title,
    required this.category,
    this.coverPhotoUrl,
    required this.unitPrice,
    required this.quantity,
    required this.maxStock,
  });

  double get totalPrice => unitPrice * quantity;

  StoreCartItem copyWith({
    int? quantity,
  }) {
    return StoreCartItem(
      productId: productId,
      inventoryId: inventoryId,
      title: title,
      category: category,
      coverPhotoUrl: coverPhotoUrl,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'inventory_id': inventoryId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

class StoreCartShop {
  final String shopId;
  final String shopName;
  final String? shopCode;
  final String? address;

  StoreCartShop({
    required this.shopId,
    required this.shopName,
    this.shopCode,
    this.address,
  });
}

class StoreOrder {
  final String orderId;
  final String shopId;
  final String shopName;
  final String? shopCode;
  final String? shopAddress;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String pickupCode;
  final DateTime createdAt;
  final DateTime? collectedAt;
  final List<dynamic> items;

  StoreOrder({
    required this.orderId,
    required this.shopId,
    required this.shopName,
    this.shopCode,
    this.shopAddress,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.pickupCode,
    required this.createdAt,
    this.collectedAt,
    required this.items,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    return StoreOrder(
      orderId: json['order_id'] ?? '',
      shopId: json['shop_id'] ?? '',
      shopName: json['shop_name'] ?? 'Print Shop',
      shopCode: json['shop_code'],
      shopAddress: json['shop_address'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'wallet',
      paymentStatus: json['payment_status'] ?? 'paid',
      status: json['status'] ?? 'placed',
      pickupCode: json['pickup_code']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      collectedAt: json['collected_at'] != null ? DateTime.tryParse(json['collected_at'].toString()) : null,
      items: (json['items'] as List<dynamic>?) ?? [],
    );
  }
}

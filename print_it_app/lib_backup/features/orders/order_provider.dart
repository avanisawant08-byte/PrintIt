import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class OrderState {
  final String? shopId;
  final String? shopName;
  final PlatformFile? file;
  final String colorMode;
  final int copies;
  final int pages;
  final String binding;
  final int pagesPerPaper;
  final String printInstructions;
  final String orientation;
  final String sides;
  final double amountTotal;
  final double priceBw;
  final double priceColor;
  final List<dynamic> pricingRules;
  final double subtotal;
  final double gst;
  final double platformFee;
  final double razorpayFee;

  OrderState({
    this.shopId,
    this.shopName,
    this.file,
    this.colorMode = 'B&W',
    this.copies = 1,
    this.pages = 24, // Hardcoded for demo since we don't parse PDF yet
    this.binding = 'none',
    this.pagesPerPaper = 1,
    this.printInstructions = '',
    this.orientation = 'portrait',
    this.sides = 'single',
    this.amountTotal = 0.0,
    this.priceBw = 0.10,
    this.priceColor = 0.45,
    this.pricingRules = const [],
    this.subtotal = 0.0,
    this.gst = 0.0,
    this.platformFee = 0.0,
    this.razorpayFee = 0.0,
  });

  OrderState copyWith({
    String? shopId,
    String? shopName,
    PlatformFile? file,
    String? colorMode,
    int? copies,
    int? pages,
    String? binding,
    int? pagesPerPaper,
    String? printInstructions,
    String? orientation,
    String? sides,
    double? amountTotal,
    double? priceBw,
    double? priceColor,
    List<dynamic>? pricingRules,
    double? subtotal,
    double? gst,
    double? platformFee,
    double? razorpayFee,
  }) {
    return OrderState(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      file: file ?? this.file,
      colorMode: colorMode ?? this.colorMode,
      copies: copies ?? this.copies,
      pages: pages ?? this.pages,
      binding: binding ?? this.binding,
      pagesPerPaper: pagesPerPaper ?? this.pagesPerPaper,
      printInstructions: printInstructions ?? this.printInstructions,
      orientation: orientation ?? this.orientation,
      sides: sides ?? this.sides,
      amountTotal: amountTotal ?? this.amountTotal,
      priceBw: priceBw ?? this.priceBw,
      priceColor: priceColor ?? this.priceColor,
      pricingRules: pricingRules ?? this.pricingRules,
      subtotal: subtotal ?? this.subtotal,
      gst: gst ?? this.gst,
      platformFee: platformFee ?? this.platformFee,
      razorpayFee: razorpayFee ?? this.razorpayFee,
    );
  }
}

class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() {
    return OrderState();
  }

  void setShopId(String shopId) {
    state = state.copyWith(shopId: shopId);
  }

  void setShop(String id, String name) {
    state = state.copyWith(shopId: id, shopName: name);
  }

  void setPrices(double bw, double color, List<dynamic> rules) {
    state = state.copyWith(priceBw: bw, priceColor: color, pricingRules: rules);
    _calculateTotal();
  }

  void setFile(PlatformFile file) {
    state = state.copyWith(file: file);
  }

  void setPages(int pages) {
    state = state.copyWith(pages: pages);
    _calculateTotal();
  }

  void setColorMode(String mode) {
    state = state.copyWith(colorMode: mode);
    _calculateTotal();
  }

  void updateCopies(int change) {
    int newCopies = state.copies + change;
    if (newCopies < 1) newCopies = 1;
    state = state.copyWith(copies: newCopies);
    _calculateTotal();
  }

  void setBinding(String binding) {
    state = state.copyWith(binding: binding);
    _calculateTotal();
  }

  void setPagesPerPaper(int count) {
    state = state.copyWith(pagesPerPaper: count);
    _calculateTotal();
  }

  void setOrientation(String val) {
    state = state.copyWith(orientation: val);
  }

  void setSides(String val) {
    state = state.copyWith(sides: val);
    _calculateTotal();
  }

  void setPrintInstructions(String text) {
    state = state.copyWith(printInstructions: text);
  }

  void _calculateTotal() {
    double basePrice = state.colorMode == 'B&W' ? state.priceBw : state.priceColor;
    double bindingPrice = 0.0;
    
    if (state.binding == 'spiral') bindingPrice = 2.50;
    if (state.binding == 'hardcover') bindingPrice = 5.00;

    String targetColor = state.colorMode == 'B&W' ? 'bw' : 'color';
    String targetSides = state.sides;
    
    for (var rule in state.pricingRules) {
      if (rule['color'] == targetColor && rule['size'] == 'A4' && rule['sides'] == targetSides) {
        basePrice = double.tryParse(rule['price_per_page']?.toString() ?? '') ?? basePrice;
        if (state.binding == 'spiral' || state.binding == 'hardcover') {
          // Note: using spiral_price for both for now, or fallback
          bindingPrice = double.tryParse(rule['binding_spiral_price']?.toString() ?? '') ?? bindingPrice;
        }
        break;
      }
    }
    
    int printedSides = (state.pages / state.pagesPerPaper).ceil();
    int physicalSheets = state.sides == 'double' ? (printedSides / 2).ceil() : printedSides;

    double subtotal = double.parse(((basePrice * physicalSheets * state.copies) + bindingPrice).toStringAsFixed(2));
    double platformFee = double.parse((subtotal * 0.03).toStringAsFixed(2)); // 3% our fee
    double amountForRazorpay = subtotal + platformFee;
    double razorpayFee = double.parse((amountForRazorpay * 0.02).toStringAsFixed(2)); // 2% razorpay fee
    double gst = double.parse((razorpayFee * 0.18).toStringAsFixed(2)); // 18% GST on razorpay fee
    
    state = state.copyWith(
      subtotal: subtotal,
      gst: gst,
      platformFee: platformFee,
      razorpayFee: razorpayFee,
      amountTotal: double.parse((subtotal + platformFee + razorpayFee + gst).toStringAsFixed(2)),
    );
  }

  void reset() {
    state = OrderState();
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderState>(OrderNotifier.new);

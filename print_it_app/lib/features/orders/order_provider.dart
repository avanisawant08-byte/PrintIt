import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/api/api_client.dart';

/// Represents a single uploaded file with its own print configuration.
class FileEntry {
  final PlatformFile file;
  final int pages;
  final String colorMode;
  final int copies;
  final String binding;
  final int pagesPerPaper;
  final String printInstructions;
  final String orientation;
  final String sides;

  FileEntry({
    required this.file,
    this.pages = 1,
    this.colorMode = 'B&W',
    this.copies = 1,
    this.binding = 'none',
    this.pagesPerPaper = 1,
    this.printInstructions = '',
    this.orientation = 'portrait',
    this.sides = 'single',
  });

  FileEntry copyWith({
    PlatformFile? file,
    int? pages,
    String? colorMode,
    int? copies,
    String? binding,
    int? pagesPerPaper,
    String? printInstructions,
    String? orientation,
    String? sides,
  }) {
    return FileEntry(
      file: file ?? this.file,
      pages: pages ?? this.pages,
      colorMode: colorMode ?? this.colorMode,
      copies: copies ?? this.copies,
      binding: binding ?? this.binding,
      pagesPerPaper: pagesPerPaper ?? this.pagesPerPaper,
      printInstructions: printInstructions ?? this.printInstructions,
      orientation: orientation ?? this.orientation,
      sides: sides ?? this.sides,
    );
  }
}

class OrderState {
  final String? shopId;
  final String? shopName;
  final PlatformFile? file;
  final List<FileEntry> files;
  final int activeFileIndex;
  final String colorMode;
  final int copies;
  final int pages;
  final String binding;
  final int pagesPerPaper;
  final String printInstructions;
  final String orientation;
  final String sides;
  final String pickupType; // 'express' or 'scheduled'
  final DateTime? pickupTime;
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
    this.files = const [],
    this.activeFileIndex = 0,
    this.colorMode = 'B&W',
    this.copies = 1,
    this.pages = 1,
    this.binding = 'none',
    this.pagesPerPaper = 1,
    this.printInstructions = '',
    this.orientation = 'portrait',
    this.sides = 'single',
    this.pickupType = 'express',
    this.pickupTime,
    this.amountTotal = 0.0,
    this.priceBw = 2.00,
    this.priceColor = 10.00,
    this.pricingRules = const [],
    this.subtotal = 0.0,
    this.gst = 0.0,
    this.platformFee = 0.0,
    this.razorpayFee = 0.0,
  });

  /// Get the currently active file entry (for document config screen)
  FileEntry? get activeFile => 
    files.isNotEmpty && activeFileIndex < files.length 
      ? files[activeFileIndex] 
      : null;

  OrderState copyWith({
    String? shopId,
    String? shopName,
    PlatformFile? file,
    List<FileEntry>? files,
    int? activeFileIndex,
    String? colorMode,
    int? copies,
    int? pages,
    String? binding,
    int? pagesPerPaper,
    String? printInstructions,
    String? orientation,
    String? sides,
    String? pickupType,
    DateTime? pickupTime,
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
      files: files ?? this.files,
      activeFileIndex: activeFileIndex ?? this.activeFileIndex,
      colorMode: colorMode ?? this.colorMode,
      copies: copies ?? this.copies,
      pages: pages ?? this.pages,
      binding: binding ?? this.binding,
      pagesPerPaper: pagesPerPaper ?? this.pagesPerPaper,
      printInstructions: printInstructions ?? this.printInstructions,
      orientation: orientation ?? this.orientation,
      sides: sides ?? this.sides,
      pickupType: pickupType ?? this.pickupType,
      pickupTime: pickupTime ?? this.pickupTime,
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
    fetchShopDetails(shopId);
  }

  Future<void> fetchShopDetails(String shopId) async {
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.get('/public/shops/$shopId');
      if (res.data != null) {
        final data = res.data is Map ? res.data : {};
        final name = (data['name'] ?? data['shop_name'])?.toString();
        final bw = double.tryParse(data['price_bw']?.toString() ?? '') ?? 2.00;
        final color = double.tryParse(data['price_color']?.toString() ?? '') ?? 10.00;
        final rules = data['pricing_rules'] as List<dynamic>? ?? [];

        state = state.copyWith(
          shopId: shopId,
          shopName: name ?? state.shopName,
          priceBw: bw,
          priceColor: color,
          pricingRules: rules,
        );
        _calculateTotal();
      }
    } catch (_) {}
  }

  void setShop(String id, String name) {
    state = state.copyWith(shopId: id, shopName: name);
    fetchShopDetails(id);
  }

  void setPrices(double bw, double color, List<dynamic> rules) {
    state = state.copyWith(priceBw: bw, priceColor: color, pricingRules: rules);
    _calculateTotal();
  }

  void setFile(PlatformFile file) {
    state = state.copyWith(file: file);
  }

  void setFiles(List<FileEntry> files) {
    state = state.copyWith(files: files);
    // Also set the first file as the primary for backward compat
    if (files.isNotEmpty) {
      state = state.copyWith(file: files.first.file, pages: files.first.pages);
    }
  }

  void setActiveFileIndex(int index) {
    if (index >= 0 && index < state.files.length) {
      final entry = state.files[index];
      state = state.copyWith(
        activeFileIndex: index,
        file: entry.file,
        pages: entry.pages,
        colorMode: entry.colorMode,
        copies: entry.copies,
        binding: entry.binding,
        pagesPerPaper: entry.pagesPerPaper,
        printInstructions: entry.printInstructions,
        orientation: entry.orientation,
        sides: entry.sides,
      );
      _calculateTotal();
    }
  }

  /// Update settings for a specific file entry and sync to state if active
  void updateFileEntry(int index, FileEntry updatedEntry) {
    if (index >= 0 && index < state.files.length) {
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[index] = updatedEntry;
      state = state.copyWith(files: newFiles);
      if (index == state.activeFileIndex) {
        setActiveFileIndex(index);
      }
    }
  }

  void removeFileEntry(int index) {
    if (index >= 0 && index < state.files.length) {
      final newFiles = List<FileEntry>.from(state.files);
      newFiles.removeAt(index);
      int newActiveIndex = state.activeFileIndex;
      if (newActiveIndex >= newFiles.length) {
        newActiveIndex = newFiles.isEmpty ? 0 : newFiles.length - 1;
      }
      state = state.copyWith(files: newFiles, activeFileIndex: newActiveIndex);
      if (newFiles.isNotEmpty) {
        setActiveFileIndex(newActiveIndex);
      }
    }
  }

  void setPages(int pages) {
    state = state.copyWith(pages: pages);
    _calculateTotal();
  }

  void setColorMode(String mode) {
    state = state.copyWith(colorMode: mode);
    // Also update the active file entry
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(colorMode: mode);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
    _calculateTotal();
  }

  void updateCopies(int change) {
    int newCopies = state.copies + change;
    if (newCopies < 1) newCopies = 1;
    state = state.copyWith(copies: newCopies);
    // Also update the active file entry
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(copies: newCopies);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
    _calculateTotal();
  }

  void setBinding(String binding) {
    state = state.copyWith(binding: binding);
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(binding: binding);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
    _calculateTotal();
  }

  void setPagesPerPaper(int count) {
    state = state.copyWith(pagesPerPaper: count);
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(pagesPerPaper: count);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
    _calculateTotal();
  }

  void setOrientation(String val) {
    state = state.copyWith(orientation: val);
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(orientation: val);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
  }

  void setSides(String val) {
    state = state.copyWith(sides: val);
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(sides: val);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
    _calculateTotal();
  }

  void setPrintInstructions(String text) {
    state = state.copyWith(printInstructions: text);
    if (state.files.isNotEmpty && state.activeFileIndex < state.files.length) {
      final updated = state.files[state.activeFileIndex].copyWith(printInstructions: text);
      final newFiles = List<FileEntry>.from(state.files);
      newFiles[state.activeFileIndex] = updated;
      state = state.copyWith(files: newFiles);
    }
  }

  void setPickupType(String type) {
    state = state.copyWith(pickupType: type);
  }

  void setPickupTime(DateTime? time) {
    state = state.copyWith(pickupTime: time);
  }

  void _calculateTotal() {
    double totalSubtotal = 0.0;

    if (state.files.isNotEmpty) {
      // Multi-file: aggregate costs across all files
      for (final entry in state.files) {
        totalSubtotal += _calculateFileSubtotal(entry);
      }
    } else {
      // Single-file fallback (e.g. home screen quick upload)
      totalSubtotal = _calculateSingleFileSubtotal();
    }

    double platformFee = double.parse((totalSubtotal * 0.03).toStringAsFixed(2)); // 3% our fee
    double amountForRazorpay = totalSubtotal + platformFee;
    double razorpayFee = double.parse((amountForRazorpay * 0.02).toStringAsFixed(2)); // 2% razorpay fee
    double gst = double.parse((razorpayFee * 0.18).toStringAsFixed(2)); // 18% GST on razorpay fee
    
    state = state.copyWith(
      subtotal: totalSubtotal,
      gst: gst,
      platformFee: platformFee,
      razorpayFee: razorpayFee,
      amountTotal: double.parse((totalSubtotal + platformFee + razorpayFee + gst).toStringAsFixed(2)),
    );
  }

  /// Calculate subtotal for a single FileEntry using its own settings.
  double _calculateFileSubtotal(FileEntry entry) {
    double basePrice = entry.colorMode == 'B&W' ? state.priceBw : state.priceColor;
    double bindingPrice = 0.0;

    if (entry.binding == 'spiral') bindingPrice = 25.0; // ₹25 standard spiral binding
    if (entry.binding == 'hardcover') bindingPrice = 60.0; // ₹60 standard hardcover

    String targetColor = entry.colorMode == 'B&W' ? 'bw' : 'color';
    String targetSides = entry.sides;

    for (var rule in state.pricingRules) {
      if (rule['color'] == targetColor && rule['size'] == 'A4' && rule['sides'] == targetSides) {
        basePrice = double.tryParse(rule['price_per_page']?.toString() ?? '') ?? basePrice;
        if (entry.binding == 'spiral' || entry.binding == 'hardcover') {
          bindingPrice = double.tryParse(rule['binding_spiral_price']?.toString() ?? '') ?? bindingPrice;
        }
        break;
      }
    }

    int totalPages = entry.pages > 0 ? entry.pages : 1;
    int printedSides = (totalPages / entry.pagesPerPaper).ceil();
    if (printedSides < 1) printedSides = 1;

    // Billing calculation: each printed page/side is charged basePrice
    double docPrintCost = (basePrice * printedSides) * entry.copies;

    return double.parse((docPrintCost + bindingPrice).toStringAsFixed(2));
  }

  /// Fallback for when files list is empty (backward compat).
  double _calculateSingleFileSubtotal() {
    double basePrice = state.colorMode == 'B&W' ? state.priceBw : state.priceColor;
    double bindingPrice = 0.0;
    
    if (state.binding == 'spiral') bindingPrice = 25.0;
    if (state.binding == 'hardcover') bindingPrice = 60.0;

    String targetColor = state.colorMode == 'B&W' ? 'bw' : 'color';
    String targetSides = state.sides;
    
    for (var rule in state.pricingRules) {
      if (rule['color'] == targetColor && rule['size'] == 'A4' && rule['sides'] == targetSides) {
        basePrice = double.tryParse(rule['price_per_page']?.toString() ?? '') ?? basePrice;
        if (state.binding == 'spiral' || state.binding == 'hardcover') {
          bindingPrice = double.tryParse(rule['binding_spiral_price']?.toString() ?? '') ?? bindingPrice;
        }
        break;
      }
    }
    
    int totalPages = state.pages > 0 ? state.pages : 1;
    int printedSides = (totalPages / state.pagesPerPaper).ceil();
    if (printedSides < 1) printedSides = 1;

    double docPrintCost = (basePrice * printedSides) * state.copies;

    return double.parse((docPrintCost + bindingPrice).toStringAsFixed(2));
  }

  void reset() {
    state = OrderState();
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderState>(OrderNotifier.new);

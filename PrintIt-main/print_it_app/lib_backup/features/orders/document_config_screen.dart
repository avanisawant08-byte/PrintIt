import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'order_provider.dart';

class DocumentConfigScreen extends ConsumerWidget {
  const DocumentConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final fileName = orderState.file?.name ?? 'Document.pdf';
    final printedSides = (orderState.pages / orderState.pagesPerPaper).ceil();
    final physicalSheets = orderState.sides == 'double' ? (printedSides / 2).ceil() : printedSides;

    // Helper to get price based on current sides selection
    double getPriceFor(String colorMode) {
      double fallbackPrice = colorMode == 'B&W' ? orderState.priceBw : orderState.priceColor;
      String targetColor = colorMode == 'B&W' ? 'bw' : 'color';
      for (var rule in orderState.pricingRules) {
        if (rule['color'] == targetColor && rule['size'] == 'A4' && rule['sides'] == orderState.sides) {
          return double.tryParse(rule['price_per_page']?.toString() ?? '') ?? fallbackPrice;
        }
      }
      return fallbackPrice;
    }
    
    double currentBwPrice = getPriceFor('B&W');
    double currentColorPrice = getPriceFor('Color');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B1E).withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Configure Print',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      children: [
                        // File Preview Card
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF37374C), Color(0xFF1E1E31)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.description, color: Color(0xFF849495), size: 28),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: const TextStyle(
                                        color: Color(0xFFE2E0FB),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(orderState.file?.size ?? 0) / 1024 / 1024 > 0 ? ((orderState.file?.size ?? 0) / 1024 / 1024).toStringAsFixed(1) : "0.0"} MB • ${orderState.pages} pages',
                                      style: const TextStyle(
                                        color: Color(0xFFB9CACB),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00DBE9).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.picture_as_pdf, color: Color(0xFF00DBE9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Color Mode Toggle
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              _buildModeToggle(
                                context, 
                                'B&W (₹${currentBwPrice.toStringAsFixed(2)}/pg)', 
                                orderState.colorMode == 'B&W',
                                () => ref.read(orderProvider.notifier).setColorMode('B&W'),
                              ),
                              const SizedBox(width: 8),
                              _buildModeToggle(
                                context, 
                                'Color (₹${currentColorPrice.toStringAsFixed(2)}/pg)', 
                                orderState.colorMode == 'Color',
                                () => ref.read(orderProvider.notifier).setColorMode('Color'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sides Toggle (Single / Back-to-Back)
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              _buildModeToggle(
                                context, 
                                'Single Sided', 
                                orderState.sides == 'single',
                                () => ref.read(orderProvider.notifier).setSides('single'),
                              ),
                              const SizedBox(width: 8),
                              _buildModeToggle(
                                context, 
                                'Back-to-Back', 
                                orderState.sides == 'double',
                                () => ref.read(orderProvider.notifier).setSides('double'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quantity Stepper
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1BCFF).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.content_copy, color: Color(0xFFD1BCFF)),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Text(
                                        'Number of Copies',
                                        style: TextStyle(
                                          color: Color(0xFFE2E0FB),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E31),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                                      onPressed: () => ref.read(orderProvider.notifier).updateCopies(-1),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${orderState.copies}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                      onPressed: () => ref.read(orderProvider.notifier).updateCopies(1),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Orientation Toggle
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              _buildModeToggle(
                                context, 
                                'Portrait', 
                                orderState.orientation == 'portrait',
                                () => ref.read(orderProvider.notifier).setOrientation('portrait'),
                              ),
                              const SizedBox(width: 8),
                              _buildModeToggle(
                                context, 
                                'Landscape', 
                                orderState.orientation == 'landscape',
                                () => ref.read(orderProvider.notifier).setOrientation('landscape'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pages per Paper
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'PAGES PER PAPER',
                                    style: TextStyle(
                                      color: Color(0xFFB9CACB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E31).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF3B494B).withValues(alpha: 0.5)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: orderState.pagesPerPaper,
                                        dropdownColor: const Color(0xFF111125),
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00DBE9), size: 20),
                                        style: const TextStyle(color: Color(0xFFE2E0FB), fontSize: 14),
                                        onChanged: (val) {
                                          if (val != null) ref.read(orderProvider.notifier).setPagesPerPaper(val);
                                        },
                                        items: [1, 2, 4, 6, 9, 16].map((int value) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text('$value'),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Visual Layout Preview
                              Center(
                                child: _buildVisualPreview(orderState.pagesPerPaper, orderState.orientation),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Binding Options
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BINDING OPTION',
                                style: TextStyle(
                                  color: Color(0xFFB9CACB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E31).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3B494B).withValues(alpha: 0.5)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: orderState.binding,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF111125),
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00DBE9)),
                                    style: const TextStyle(color: Color(0xFFE2E0FB), fontSize: 16),
                                    onChanged: (val) {
                                      if (val != null) ref.read(orderProvider.notifier).setBinding(val);
                                    },
                                    items: const [
                                      DropdownMenuItem(value: 'none', child: Text('None')),
                                      DropdownMenuItem(value: 'spiral', child: Text('Spiral Binding (+₹2.50)')),
                                      DropdownMenuItem(value: 'hardcover', child: Text('Hardcover (+₹5.00)')),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Print Instructions
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRINT INSTRUCTIONS (OPTIONAL)',
                                style: TextStyle(
                                  color: Color(0xFFB9CACB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (val) => ref.read(orderProvider.notifier).setPrintInstructions(val),
                                maxLines: 3,
                                maxLength: 500,
                                style: const TextStyle(color: Color(0xFFE2E0FB)),
                                decoration: InputDecoration(
                                  hintText: 'E.g., Please print in landscape, staple in top left corner...',
                                  hintStyle: TextStyle(color: const Color(0xFF849495).withValues(alpha: 0.8)),
                                  filled: true,
                                  fillColor: const Color(0xFF1E1E31).withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: const Color(0xFF3B494B).withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: const Color(0xFF3B494B).withValues(alpha: 0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF00DBE9)),
                                  ),
                                  counterStyle: const TextStyle(color: Color(0xFF849495)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Sticky Footer Price Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111125).withValues(alpha: 0.6),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPriceRow('Subtotal ($physicalSheets sheets x ${orderState.copies})', '₹${orderState.subtotal.toStringAsFixed(2)}'),
                          _buildPriceRow('Platform Fee (3%)', '₹${orderState.platformFee.toStringAsFixed(2)}'),
                          _buildPriceRow('Razorpay Fee (2%)', '₹${orderState.razorpayFee.toStringAsFixed(2)}'),
                          _buildPriceRow('GST (18% on Razorpay Fee)', '₹${orderState.gst.toStringAsFixed(2)}'),
                          const Divider(color: Colors.white24, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(color: Color(0xFFE2E0FB), fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '₹${orderState.amountTotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF00DBE9), fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              onPressed: () => context.push('/payment'),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00DBE9), Color(0xFF7000FF)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'PROCEED TO PAY',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00DBE9) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected 
              ? [BoxShadow(color: const Color(0xFF00DBE9).withValues(alpha: 0.4), blurRadius: 12)] 
              : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00363A) : const Color(0xFFB9CACB),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFB9CACB), fontSize: 14)),
          Text(value, style: const TextStyle(color: Color(0xFFB9CACB), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVisualPreview(int pagesPerPaper, String orientation) {
    int columns = 1;
    int rows = 1;
    
    if (orientation == 'portrait') {
      if (pagesPerPaper == 2) { columns = 1; rows = 2; }
      else if (pagesPerPaper == 4) { columns = 2; rows = 2; }
      else if (pagesPerPaper == 6) { columns = 2; rows = 3; }
      else if (pagesPerPaper == 9) { columns = 3; rows = 3; }
      else if (pagesPerPaper == 16) { columns = 4; rows = 4; }
    } else {
      if (pagesPerPaper == 2) { columns = 2; rows = 1; }
      else if (pagesPerPaper == 4) { columns = 2; rows = 2; }
      else if (pagesPerPaper == 6) { columns = 3; rows = 2; }
      else if (pagesPerPaper == 9) { columns = 3; rows = 3; }
      else if (pagesPerPaper == 16) { columns = 4; rows = 4; }
    }

    double width = orientation == 'landscape' ? 160 : 120;
    double height = orientation == 'landscape' ? 120 : 160;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFB9CACB), width: 1),
      ),
      child: Column(
        children: List.generate(rows, (r) {
          return Expanded(
            child: Row(
              children: List.generate(columns, (c) {
                int pageNum = r * columns + c + 1;
                if (pageNum > pagesPerPaper) return const Expanded(child: SizedBox());
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFB9CACB).withValues(alpha: 0.5), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          color: const Color(0xFFB9CACB),
                          fontSize: pagesPerPaper > 4 ? 10 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

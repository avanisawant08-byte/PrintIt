import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';
import 'order_provider.dart';
import 'widgets/live_file_preview.dart';

class DocumentConfigScreen extends ConsumerStatefulWidget {
  const DocumentConfigScreen({super.key});

  @override
  ConsumerState<DocumentConfigScreen> createState() => _DocumentConfigScreenState();
}

class _DocumentConfigScreenState extends ConsumerState<DocumentConfigScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final orderNotifier = ref.read(orderProvider.notifier);
    if (ref.read(orderProvider).files.isEmpty) {
      orderNotifier.addDemoFileIfEmpty();
    }
    final activeIndex = ref.read(orderProvider).activeFileIndex;
    _pageController = PageController(initialPage: activeIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Document Configuration',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Document Preview Card matching Stitch
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                                    : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x18A0C3D7),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 330,
                                    child: Stack(
                                      children: [
                                        PageView.builder(
                                          controller: _pageController,
                                          itemCount: orderState.files.length,
                                          onPageChanged: (index) {
                                            ref.read(orderProvider.notifier).setActiveFileIndex(index);
                                          },
                                          itemBuilder: (context, index) {
                                            final entry = orderState.files[index];
                                            return LiveFilePreview(
                                              fileEntry: entry,
                                              pagesPerPaper: orderState.pagesPerPaper,
                                              orientation: orderState.orientation,
                                              bottomOverlay: Positioned(
                                                bottom: 6,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1E293B).withValues(alpha: 0.94),
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.25),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Text(
                                                          'PAGES / SHEET',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 0.6,
                                                            color: Color(0xFFCBD5E1),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        _buildOverlayPageButton(ref, 1, orderState.pagesPerPaper == 1),
                                                        const SizedBox(width: 4),
                                                        _buildOverlayPageButton(ref, 2, orderState.pagesPerPaper == 2),
                                                        const SizedBox(width: 4),
                                                        _buildOverlayPageButton(ref, 4, orderState.pagesPerPaper == 4),
                                                        const SizedBox(width: 4),
                                                        _buildOverlayPageButton(ref, 6, orderState.pagesPerPaper == 6),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // Close Button top-right
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              ref.read(orderProvider.notifier).removeFileEntry(orderState.activeFileIndex);
                                              if (orderState.files.length <= 1) {
                                                context.pop();
                                              }
                                            },
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (orderState.files.isNotEmpty)
                                    Text(
                                      '${orderState.files[orderState.activeFileIndex].file.name} • ${orderState.files[orderState.activeFileIndex].pages} pages',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Number of Copies Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x12A0C3D7),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Number of copies',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (orderState.files.isNotEmpty)
                                        Text(
                                          'File ${orderState.activeFileIndex + 1} (${orderState.files[orderState.activeFileIndex].pages} pages)',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.white12 : Colors.white,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 18, color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0F172A)),
                                          onPressed: () => ref.read(orderProvider.notifier).updateCopies(-1),
                                          splashRadius: 18,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '${orderState.copies}',
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 18, color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0F172A)),
                                          onPressed: () => ref.read(orderProvider.notifier).updateCopies(1),
                                          splashRadius: 18,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Choose Print Color Section
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 8),
                              child: Text(
                                'Choose print color',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSelectableCard(
                                    isDark: isDark,
                                    isSelected: orderState.colorMode == 'Color',
                                    onTap: () => ref.read(orderProvider.notifier).setColorMode('Color'),
                                    icon: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 2, left: 2,
                                            child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                                          ),
                                          Positioned(
                                            bottom: 2, left: 3,
                                            child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                                          ),
                                          Positioned(
                                            right: 2, top: 5,
                                            child: Container(width: 11, height: 11, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: 'Coloured',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectableCard(
                                    isDark: isDark,
                                    isSelected: orderState.colorMode == 'B&W',
                                    onTap: () => ref.read(orderProvider.notifier).setColorMode('B&W'),
                                    icon: Icon(
                                      Icons.tonality,
                                      size: 24,
                                      color: orderState.colorMode == 'B&W'
                                          ? const Color(0xFF0891B2)
                                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A)),
                                    ),
                                    title: 'B & W',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Choose Print Orientation Section
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 8),
                              child: Text(
                                'Choose print orientation',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSelectableCard(
                                    isDark: isDark,
                                    isSelected: orderState.orientation == 'portrait',
                                    onTap: () => ref.read(orderProvider.notifier).setOrientation('portrait'),
                                    icon: Icon(
                                      Icons.description_outlined,
                                      size: 24,
                                      color: orderState.orientation == 'portrait'
                                          ? const Color(0xFF0891B2)
                                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                    ),
                                    title: 'Portrait',
                                    subtitle: '8.3 × 11.7 in',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectableCard(
                                    isDark: isDark,
                                    isSelected: orderState.orientation == 'landscape',
                                    onTap: () => ref.read(orderProvider.notifier).setOrientation('landscape'),
                                    icon: RotatedBox(
                                      quarterTurns: 1,
                                      child: Icon(
                                        Icons.description_outlined,
                                        size: 24,
                                        color: orderState.orientation == 'landscape'
                                            ? const Color(0xFF0891B2)
                                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                      ),
                                    ),
                                    title: 'Landscape',
                                    subtitle: '11.7 × 8.3 in',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Sidedness Section
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 8),
                              child: Text(
                                'Sidedness',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSelectableCard(
                                    isDark: isDark,
                                    isSelected: orderState.sides == 'single',
                                    onTap: () => ref.read(orderProvider.notifier).setSides('single'),
                                    icon: Container(
                                      width: 18,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: orderState.sides == 'single'
                                              ? const Color(0xFF0891B2)
                                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '1',
                                        style: TextStyle(
                                          color: orderState.sides == 'single'
                                              ? const Color(0xFF0891B2)
                                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: 'Single Sided',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectableCard(
                                    isDark: isDark,
                                    isSelected: orderState.sides == 'double',
                                    onTap: () => ref.read(orderProvider.notifier).setSides('double'),
                                    icon: SizedBox(
                                      width: 22,
                                      height: 24,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 0, right: 0,
                                            child: Container(
                                              width: 16, height: 20,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                                  width: 1.2,
                                                ),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0, left: 0,
                                            child: Container(
                                              width: 16, height: 20,
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                border: Border.all(
                                                  color: orderState.sides == 'double'
                                                      ? const Color(0xFF0891B2)
                                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                                  width: 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '2',
                                                style: TextStyle(
                                                  color: orderState.sides == 'double'
                                                      ? const Color(0xFF0891B2)
                                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: 'Back-to-Back',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Binding Option Section
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 8),
                              child: Text(
                                'Binding Option',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showBindingOptions(context, ref, orderState.binding, isDark),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A).withValues(alpha: 0.55)
                                      : Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x1064748B),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.menu_book_outlined,
                                            size: 20,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          orderState.binding == 'none'
                                              ? 'No Binding'
                                              : orderState.binding == 'spiral'
                                                  ? 'Spiral Binding'
                                                  : 'Hardcover',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Print Instructions Section
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 8),
                              child: Text(
                                'Print Instructions (Optional)',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.55)
                                    : Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x1064748B),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: TextField(
                                onChanged: (val) => ref.read(orderProvider.notifier).setPrintInstructions(val),
                                maxLines: 3,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add any specific instructions for printing...',
                                  hintStyle: TextStyle(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Action Bar matching Stitch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0F1D).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.88),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ${(orderState.pages / orderState.pagesPerPaper).ceil() * orderState.copies} pages',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/schedule-pickup');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22D3EE),
                          foregroundColor: const Color(0xFF082F49),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
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

  void _showBindingOptions(BuildContext context, WidgetRef ref, String currentBinding, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Binding',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBindingOption(context, ref, 'none', 'No Binding', currentBinding, isDark),
                _buildBindingOption(context, ref, 'spiral', 'Spiral Binding', currentBinding, isDark),
                _buildBindingOption(context, ref, 'hardcover', 'Hardcover', currentBinding, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBindingOption(BuildContext context, WidgetRef ref, String value, String label, String currentBinding, bool isDark) {
    final isSelected = currentBinding == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF22D3EE)) : null,
      onTap: () {
        ref.read(orderProvider.notifier).setBinding(value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSelectableCard({
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget icon,
    required String title,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF06B6D4).withValues(alpha: 0.18) : null)
              : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.65)),
          gradient: isSelected
              ? (isDark
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF06B6D4).withValues(alpha: 0.28),
                        const Color(0xFF0891B2).withValues(alpha: 0.15),
                      ],
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xD9CFFAFE),
                        Color(0xB3E0F7FA),
                      ],
                    ))
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22D3EE)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF22D3EE).withValues(alpha: isDark ? 0.35 : 0.28),
                blurRadius: 14,
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x1064748B),
                blurRadius: 8,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? const Color(0xFF8AEBFF) : const Color(0xFF0891B2))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayPageButton(WidgetRef ref, int count, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(orderProvider.notifier).setPagesPerPaper(count),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22D3EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: isSelected ? const Color(0xFF082F49) : const Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

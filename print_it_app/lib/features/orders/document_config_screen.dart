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
    final activeIndex = ref.read(orderProvider).activeFileIndex;
    _pageController = PageController(initialPage: activeIndex, viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    


    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF051424).withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8AEBFF)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Document Configuration',
          style: TextStyle(
            color: Color(0xFFD4E4FA),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFBBC9CD)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120), // Space for sticky footer
                    child: Column(
                      children: [
                        // Preview Section
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF010F1F).withValues(alpha: 0.5),
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 320,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: orderState.files.length,
                                  onPageChanged: (index) {
                                    ref.read(orderProvider.notifier).setActiveFileIndex(index);
                                  },
                                  itemBuilder: (context, index) {
                                    final entry = orderState.files[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF122131).withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Stack(
                                            children: [
                                              LiveFilePreview(
                                                fileEntry: entry,
                                                pagesPerPaper: orderState.pagesPerPaper,
                                                orientation: orderState.orientation,
                                                bottomOverlay: Positioned(
                                                  bottom: 12, left: 12, right: 12,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF122131).withValues(alpha: 0.8),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        const Padding(
                                                          padding: EdgeInsets.only(left: 4.0),
                                                          child: Text(
                                                            'PAGES / SHEET',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              letterSpacing: 0.5,
                                                              color: Color(0xFFBBC9CD),
                                                            ),
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            _buildOverlayPageButton(ref, 1, orderState.pagesPerPaper == 1),
                                                            const SizedBox(width: 4),
                                                            _buildOverlayPageButton(ref, 2, orderState.pagesPerPaper == 2),
                                                            const SizedBox(width: 4),
                                                            _buildOverlayPageButton(ref, 4, orderState.pagesPerPaper == 4),
                                                            const SizedBox(width: 4),
                                                            _buildOverlayPageButton(ref, 6, orderState.pagesPerPaper == 6),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    ref.read(orderProvider.notifier).removeFileEntry(index);
                                                    if (orderState.files.length <= 1) {
                                                      context.pop(); 
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (orderState.files.isNotEmpty)
                                Text(
                                  '${orderState.files[orderState.activeFileIndex].file.name} • ${orderState.files[orderState.activeFileIndex].pages} pages',
                                  style: const TextStyle(
                                    color: Color(0xFFBBC9CD),
                                    fontSize: 14,
                                  ),
                                ),

                            ],
                          ),
                        ),
                        
                        // Configurations
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number of copies
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _glassDecoration(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Number of copies', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)),
                                          if (orderState.files.isNotEmpty)
                                            Text('File ${orderState.activeFileIndex + 1} (${orderState.files[orderState.activeFileIndex].pages} pages)', style: const TextStyle(color: Color(0xFFBBC9CD), fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C2B3C),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, color: Color(0xFF8AEBFF)),
                                            onPressed: () => ref.read(orderProvider.notifier).updateCopies(-1),
                                          ),
                                          Text(
                                            '${orderState.copies}',
                                            style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 20, fontWeight: FontWeight.w600),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, color: Color(0xFF8AEBFF)),
                                            onPressed: () => ref.read(orderProvider.notifier).updateCopies(1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Choose print color
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Choose print color', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSelectableCard(
                                      isSelected: orderState.colorMode == 'Color',
                                      onTap: () => ref.read(orderProvider.notifier).setColorMode('Color'),
                                      icon: Container(
                                        width: 40, height: 40,
                                        decoration: const BoxDecoration(shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                          child: const Icon(Icons.circle, color: Color(0xFFFF3B30), size: 28, shadows: [Shadow(color: Color(0xFF4CD964), offset: Offset(8, 0)), Shadow(color: Color(0xFF007AFF), offset: Offset(4, 6))]),
                                      ),
                                      title: 'Coloured',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSelectableCard(
                                      isSelected: orderState.colorMode == 'B&W',
                                      onTap: () => ref.read(orderProvider.notifier).setColorMode('B&W'),
                                      icon: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF273647), Color(0xFF3C494C)]),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.tonality, color: Color(0xFFBBC9CD)),
                                      ),
                                      title: 'B & W',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Choose print orientation
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Choose print orientation', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSelectableCard(
                                      isSelected: orderState.orientation == 'portrait',
                                      onTap: () => ref.read(orderProvider.notifier).setOrientation('portrait'),
                                      icon: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8AEBFF).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.description, color: Color(0xFF8AEBFF)),
                                      ),
                                      title: 'Portrait',
                                      subtitle: '8.3 x 11.7 in',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSelectableCard(
                                      isSelected: orderState.orientation == 'landscape',
                                      onTap: () => ref.read(orderProvider.notifier).setOrientation('landscape'),
                                      icon: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF273647).withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: const RotatedBox(
                                          quarterTurns: 1,
                                          child: Icon(Icons.description, color: Color(0xFFBBC9CD)),
                                        ),
                                      ),
                                      title: 'Landscape',
                                      subtitle: '11.7 x 8.3 in',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sidedness
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Sidedness', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSelectableCard(
                                      isSelected: orderState.sides == 'single',
                                      onTap: () => ref.read(orderProvider.notifier).setSides('single'),
                                      icon: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: orderState.sides == 'single' ? const Color(0xFF8AEBFF).withValues(alpha: 0.2) : const Color(0xFF273647).withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(Icons.filter_1, color: orderState.sides == 'single' ? const Color(0xFF8AEBFF) : const Color(0xFFBBC9CD)),
                                      ),
                                      title: 'Single Sided',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSelectableCard(
                                      isSelected: orderState.sides == 'double',
                                      onTap: () => ref.read(orderProvider.notifier).setSides('double'),
                                      icon: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: orderState.sides == 'double' ? const Color(0xFF8AEBFF).withValues(alpha: 0.2) : const Color(0xFF273647).withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(Icons.filter_2, color: orderState.sides == 'double' ? const Color(0xFF8AEBFF) : const Color(0xFFBBC9CD)),
                                      ),
                                      title: 'Back-to-Back',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Binding Option
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Binding Option', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Show bottom sheet or dropdown
                                  _showBindingOptions(context, ref, orderState.binding);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: _glassDecoration(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40, height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF273647).withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.menu_book, color: Color(0xFFBBC9CD)),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            orderState.binding == 'none' ? 'No Binding' : 
                                            orderState.binding == 'spiral' ? 'Spiral Binding' : 'Hardcover',
                                            style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.expand_more, color: Color(0xFFBBC9CD)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Print Instructions
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('Print Instructions (Optional)', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _glassDecoration(),
                                child: TextField(
                                  onChanged: (val) => ref.read(orderProvider.notifier).setPrintInstructions(val),
                                  maxLines: 3,
                                  style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Add any specific instructions for printing...',
                                    hintStyle: TextStyle(color: Color(0xFFBBC9CD), fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF051424).withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: const Color(0xFF3C494C).withValues(alpha: 0.5))),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total ${(orderState.pages / orderState.pagesPerPaper).ceil() * orderState.copies} pages', style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                           context.push('/schedule-pickup');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22D3EE),
                          foregroundColor: const Color(0xFF005763),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: const Color(0xFF8AEBFF).withValues(alpha: 0.2),
                        ),
                        child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  void _showBindingOptions(BuildContext context, WidgetRef ref, String currentBinding) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF122131),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Binding', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBindingOption(context, ref, 'none', 'No Binding', currentBinding),
              _buildBindingOption(context, ref, 'spiral', 'Spiral Binding', currentBinding),
              _buildBindingOption(context, ref, 'hardcover', 'Hardcover', currentBinding),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBindingOption(BuildContext context, WidgetRef ref, String value, String label, String currentBinding) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Color(0xFFD4E4FA))),
      trailing: currentBinding == value ? const Icon(Icons.check, color: Color(0xFF8AEBFF)) : null,
      onTap: () {
        ref.read(orderProvider.notifier).setBinding(value);
        Navigator.pop(context);
      },
    );
  }

  BoxDecoration _glassDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? const Color(0xFF22D3EE).withValues(alpha: 0.1) : const Color(0xFF122131).withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? const Color(0xFF8AEBFF) : Colors.white.withValues(alpha: 0.08),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isSelected
          ? [const BoxShadow(color: Color(0x4D22D3EE), blurRadius: 15)]
          : [],
    );
  }

  Widget _buildSelectableCard({
    required bool isSelected,
    required VoidCallback onTap,
    required Widget icon,
    required String title,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _glassDecoration(isSelected: isSelected),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  if (subtitle != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(subtitle, style: const TextStyle(color: Color(0xFFBBC9CD), fontSize: 12)),
                    ),
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
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8AEBFF) : const Color(0xFF273647).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: isSelected ? const Color(0xFF00363E) : const Color(0xFFBBC9CD),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'order_provider.dart';
import 'widgets/office_doc_helper.dart';

class ExpressPickupScreen extends ConsumerStatefulWidget {
  const ExpressPickupScreen({super.key});

  @override
  ConsumerState<ExpressPickupScreen> createState() => _ExpressPickupScreenState();
}

class _ExpressPickupScreenState extends ConsumerState<ExpressPickupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isExpressMode = true;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'docx', 'doc', 'ppt', 'pptx', 'xls', 'xlsx'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      final currentFiles = ref.read(orderProvider).files;
      List<FileEntry> newEntries = List.from(currentFiles);

      for (var file in result.files) {
        int pages = 1;
        final ext = file.extension?.toLowerCase() ?? '';
        if (ext == 'pdf') {
          try {
            List<int>? bytes = file.bytes;
            if (bytes == null && !kIsWeb && file.path != null) {
              bytes = await File(file.path!).readAsBytes();
            }
            if (bytes != null) {
              final PdfDocument document = PdfDocument(inputBytes: bytes);
              pages = document.pages.count;
              document.dispose();
            }
          } catch (e) {
            debugPrint('Error parsing PDF: $e');
          }
        } else if (['ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx'].contains(ext)) {
          try {
            pages = await OfficeDocHelper.getOfficePageCount(file);
          } catch (e) {
            debugPrint('Error parsing office document page count: $e');
          }
        }
        newEntries.add(FileEntry(file: file, pages: pages));
      }

      ref.read(orderProvider.notifier).setFiles(newEntries);
    }
  }

  void _removeFile(int index) {
    ref.read(orderProvider.notifier).removeFileEntry(index);
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final files = orderState.files;
    final totalDocs = files.length;
    final totalPrice = totalDocs * 5.00;

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
          'Velocity',
          style: TextStyle(
            color: Color(0xFF8AEBFF),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Row(
            children: const [
              Icon(Icons.speed, color: Color(0xFF22D3EE), size: 20),
              SizedBox(width: 4),
              Text(
                'EXPRESS MODE',
                style: TextStyle(
                  color: Color(0xFF8AEBFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
              children: [
                // Toggle Section
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2B3C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isExpressMode = true);
                            ref.read(orderProvider.notifier).setPickupType('express');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isExpressMode ? const Color(0xFF22D3EE) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: _isExpressMode ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Express (Now)',
                                  style: TextStyle(
                                    color: _isExpressMode ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isExpressMode = false);
                            ref.read(orderProvider.notifier).setPickupType('scheduled');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isExpressMode ? const Color(0xFF22D3EE) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: !_isExpressMode ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Scheduled',
                                  style: TextStyle(
                                    color: !_isExpressMode ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 32),

                // Estimate Banner
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8AEBFF).withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withValues(alpha: _glowAnimation.value * 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
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
                                  color: const Color(0xFF8AEBFF).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.timer, color: Color(0xFF8AEBFF)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ESTIMATED READINESS',
                                    style: TextStyle(
                                      color: Color(0xFF8AEBFF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '5-10 Minutes',
                                    style: TextStyle(
                                      color: Color(0xFFD4E4FA),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildPulsingBar(0),
                              const SizedBox(width: 4),
                              _buildPulsingBar(1),
                              const SizedBox(width: 4),
                              _buildPulsingBar(2),
                            ],
                          )
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 32),

                // Upload Area
                GestureDetector(
                  onTap: _pickFiles,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF3C494C).withValues(alpha: 0.5),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF273647),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.cloud_upload, color: Color(0xFF8AEBFF), size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Drag & Drop or Tap to Upload',
                          style: TextStyle(
                            color: Color(0xFFD4E4FA),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PDF, DOCX, PPTX, XLSX, JPG, PNG (Max 25MB per file)',
                          style: TextStyle(
                            color: Color(0xFFBBC9CD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Pricing & Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRICE PER UNIT',
                              style: TextStyle(
                                color: Color(0xFFBBC9CD),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  '₹5.00',
                                  style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '/doc',
                                  style: TextStyle(color: Color(0xFFBBC9CD), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUEUE STATUS',
                              style: TextStyle(
                                color: Color(0xFFBBC9CD),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF8AEBFF), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Low Traffic',
                                  style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UPLOADED FILES',
                      style: TextStyle(
                        color: Color(0xFFBBC9CD),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '$totalDocs Document${totalDocs == 1 ? '' : 's'} Uploaded',
                      style: const TextStyle(
                        color: Color(0xFF8AEBFF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (files.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.description, size: 40, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'No documents selected yet',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: files.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final fileEntry = entry.value;
                      final sizeMb = fileEntry.file.size / (1024 * 1024);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF8AEBFF).withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8AEBFF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.description, color: Color(0xFF8AEBFF), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileEntry.file.name,
                                    style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${sizeMb.toStringAsFixed(2)} MB • READY',
                                    style: const TextStyle(color: Color(0xFF859397), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFFBBC9CD), size: 20),
                              onPressed: () => _removeFile(idx),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          
          // Fixed Bottom Action Area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 16 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFF051424).withValues(alpha: 0.8),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Total', style: TextStyle(color: Color(0xFFBBC9CD), fontSize: 12)),
                          Text('₹${totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF8AEBFF), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22D3EE),
                            foregroundColor: const Color(0xFF005763),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: files.isEmpty ? null : () {
                            if (!_isExpressMode && ref.read(orderProvider).pickupTime == null) {
                               // Open a time picker or route to schedule pickup time selector
                               context.push('/schedule-pickup');
                            } else {
                               context.push('/select-shop');
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Start Processing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
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

  Widget _buildPulsingBar(int index) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        // Create an offset wave effect
        double val = _glowAnimation.value + (index * 0.3);
        if (val > 1.0) val -= 1.0;
        
        return Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF8AEBFF).withValues(alpha: val),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }
    );
  }
}

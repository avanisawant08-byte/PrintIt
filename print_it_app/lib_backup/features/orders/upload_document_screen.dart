import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'order_provider.dart';

class UploadDocumentScreen extends ConsumerStatefulWidget {
  final String? shopId;
  const UploadDocumentScreen({super.key, this.shopId});

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      int pages = 1;
      
      debugPrint('File picked: ${file.name}, size: ${file.size}, bytes length: ${file.bytes?.length}, path: ${file.path}');

      if (file.extension?.toLowerCase() == 'pdf') {
        try {
          List<int>? bytes = file.bytes;
          if (bytes == null && file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
          
          if (bytes != null) {
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            pages = document.pages.count;
            document.dispose();
          } else {
            debugPrint('Warning: Could not get bytes for PDF parsing.');
          }
        } catch (e) {
          debugPrint('Error parsing PDF: $e');
        }
      }

      ref.read(orderProvider.notifier).setPages(pages);

      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _proceedToConfig() {
    if (_selectedFile == null) return;
    
    ref.read(orderProvider.notifier).setFile(_selectedFile!);
    
    if (widget.shopId != null && widget.shopId!.isNotEmpty) {
      ref.read(orderProvider.notifier).setShopId(widget.shopId!);
      context.push('/document-config');
    } else {
      context.push('/select-shop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00DBE9)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Upload',
          style: TextStyle(
            color: Color(0xFF00DBE9),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFB9CACB)),
            onPressed: () {},
          )
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                  // Drop Zone
                  GestureDetector(
                    onTap: _pickFile,
                    child: GlassContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFF28283C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              color: Color(0xFF00DBE9),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to Browse Files',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE2E0FB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Support for PDF, JPG, PNG up to 50MB.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB9CACB),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333348),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF3B494B).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Browse Files',
                              style: TextStyle(
                                color: Color(0xFF00DBE9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Selected File
                  if (_selectedFile != null) ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333348),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: Color(0xFFE9DDFF)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E0FB),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF333348),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: 1.0, // Completed
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00F0FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFB9CACB)),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(bottom: 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _selectedFile == null ? null : _proceedToConfig,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedFile != null
                            ? [const Color(0xFF7000FF), const Color(0xFF00F0FF)]
                            : [Colors.grey.shade800, Colors.grey.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Next: Print Options',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
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
}

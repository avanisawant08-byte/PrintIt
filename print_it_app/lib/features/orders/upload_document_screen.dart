import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
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

/// Tracks the upload/processing progress of an individual file.
class _FileUploadState {
  final PlatformFile file;
  final int pages;
  double progress = 0.0; // 0.0 to 1.0
  bool isComplete = false;
  Timer? _progressTimer;

  _FileUploadState({
    required this.file,
    this.pages = 1,
  });

  void dispose() {
    _progressTimer?.cancel();
  }
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen>
    with TickerProviderStateMixin {
  final List<_FileUploadState> _uploadedFiles = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
      withData: true,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        // Skip duplicates
        if (_uploadedFiles.any((f) => f.file.name == file.name && f.file.size == file.size)) {
          continue;
        }

        int pages = 1;
        debugPrint('File picked: ${file.name}, size: ${file.size}, bytes length: ${file.bytes?.length}');

        if (file.extension?.toLowerCase() == 'pdf') {
          try {
            List<int>? bytes = file.bytes;
            if (bytes == null && !kIsWeb && file.path != null) {
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

        final uploadState = _FileUploadState(file: file, pages: pages);
        setState(() {
          _uploadedFiles.add(uploadState);
        });

        // Simulate upload progress animation
        _simulateUploadProgress(uploadState);
      }
    }
  }

  void _simulateUploadProgress(_FileUploadState fileState) {
    // Simulate a realistic upload progress over ~1.5 seconds
    const totalSteps = 30;
    const stepDuration = Duration(milliseconds: 50);
    int currentStep = 0;

    fileState._progressTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Non-linear progress: fast start, pause at 70%, then complete
        if (currentStep <= totalSteps * 0.5) {
          fileState.progress = (currentStep / (totalSteps * 0.5)) * 0.7;
        } else if (currentStep <= totalSteps * 0.8) {
          // Slow phase
          double t = (currentStep - totalSteps * 0.5) / (totalSteps * 0.3);
          fileState.progress = 0.7 + t * 0.2;
        } else {
          // Final burst
          double t = (currentStep - totalSteps * 0.8) / (totalSteps * 0.2);
          fileState.progress = 0.9 + t * 0.1;
        }

        if (currentStep >= totalSteps) {
          fileState.progress = 1.0;
          fileState.isComplete = true;
          timer.cancel();
        }
      });
    });
  }

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles[index].dispose();
      _uploadedFiles.removeAt(index);
    });
  }

  void _proceedToConfig() {
    if (_uploadedFiles.isEmpty) return;

    // Convert uploaded files to FileEntry list
    final fileEntries = _uploadedFiles.map((f) => FileEntry(
      file: f.file,
      pages: f.pages,
    )).toList();

    ref.read(orderProvider.notifier).setFiles(fileEntries);

    // Set pages from first file for backward compat
    ref.read(orderProvider.notifier).setPages(fileEntries.first.pages);

    if (widget.shopId != null && widget.shopId!.isNotEmpty) {
      ref.read(orderProvider.notifier).setShopId(widget.shopId!);
      context.push('/document-config');
    } else {
      context.push('/select-shop');
    }
  }

  @override
  void dispose() {
    for (final f in _uploadedFiles) {
      f.dispose();
    }
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.co_present;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String? extension, BuildContext context) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.deepOrangeAccent;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
        return Colors.orangeAccent;
      case 'png':
        return Colors.blueAccent;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allComplete = _uploadedFiles.isNotEmpty && 
        _uploadedFiles.every((f) => f.isComplete);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Upload',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_uploadedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_uploadedFiles.length} file${_uploadedFiles.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        // Drop Zone
                        GestureDetector(
                          onTap: _pickFiles,
                          child: GlassContainer(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_upload,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _uploadedFiles.isEmpty
                                      ? 'Tap to Browse Files'
                                      : 'Tap to Add More Files',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Support for PDF, DOCX, PPTX, XLSX, JPG, PNG up to 50MB.\nSelect multiple files at once.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  ),
                                  child: Text(
                                    'Browse Files',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Uploaded Files List
                        if (_uploadedFiles.isNotEmpty) ...[
                          Text(
                            'Uploaded Files',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_uploadedFiles.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildFileCard(index),
                            );
                          }),
                        ],
                        const SizedBox(height: 100), // Space for button
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
                      onPressed: !allComplete ? null : _proceedToConfig,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: allComplete
                                ? [const Color(0xFF7000FF), Theme.of(context).colorScheme.primary]
                                : [Colors.grey.shade800, Colors.grey.shade700],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _uploadedFiles.length > 1
                                      ? 'Next: Print Options (${_uploadedFiles.length} files)'
                                      : 'Next: Print Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface),
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

  Widget _buildFileCard(int index) {
    final fileState = _uploadedFiles[index];
    final file = fileState.file;
    final fileColor = _getFileColor(file.extension, context);
    final percentText = '${(fileState.progress * 100).toInt()}%';

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // File type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getFileIcon(file.extension), color: fileColor, size: 24),
              ),
              const SizedBox(width: 14),
              // File name + size
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _formatFileSize(file.size),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        if (file.extension?.toLowerCase() == 'pdf') ...[
                          Text(
                            ' • ${fileState.pages} page${fileState.pages > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status indicator / percentage
              if (fileState.isComplete)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 18),
                )
              else
                SizedBox(
                  width: 36,
                  child: Text(
                    percentText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Remove button
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => _removeFile(index),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animated Progress Bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fileState.progress),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        // Background track
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Filled progress
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: fileState.isComplete
                                    ? [Colors.green.shade400, Colors.green.shade600]
                                    : [Theme.of(context).colorScheme.primary, const Color(0xFF7000FF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (fileState.isComplete
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.primary)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Shimmer effect when uploading
                        if (!fileState.isComplete)
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value.clamp(0.0, 1.0),
                            child: _ShimmerProgressOverlay(height: 6),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A shimmer overlay that animates across the progress bar
class _ShimmerProgressOverlay extends StatefulWidget {
  final double height;
  const _ShimmerProgressOverlay({required this.height});

  @override
  State<_ShimmerProgressOverlay> createState() => _ShimmerProgressOverlayState();
}

class _ShimmerProgressOverlayState extends State<_ShimmerProgressOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1.0 + 2 * _controller.value, 0),
                end: Alignment(-0.5 + 2 * _controller.value, 0),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ).createShader(rect);
            },
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}

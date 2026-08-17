import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:shimmer/shimmer.dart';
import '../order_provider.dart';

class LiveFilePreview extends StatefulWidget {
  final FileEntry fileEntry;
  final int pagesPerPaper;
  final String orientation;
  final Widget? bottomOverlay;

  const LiveFilePreview({
    super.key,
    required this.fileEntry,
    required this.pagesPerPaper,
    required this.orientation,
    this.bottomOverlay,
  });

  @override
  State<LiveFilePreview> createState() => _LiveFilePreviewState();
}

class _LiveFilePreviewState extends State<LiveFilePreview> {
  PdfController? _pdfController;
  int _currentPage = 1;
  bool _isLoading = true;
  PdfDocument? _cachedDocument;

  @override
  void initState() {
    super.initState();
    final type = _getFileType();
    if (type == 'pdf') {
      _initPdf();
    } else if (type != 'jpg' && type != 'png' && type != 'webp') {
      _isLoading = false;
    }
  }
  
  @override
  void didUpdateWidget(covariant LiveFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileEntry.file != widget.fileEntry.file) {
      final type = _getFileType();
      if (type == 'pdf') {
        _pdfController?.dispose();
        _cachedDocument = null;
        _isLoading = true;
        _initPdf();
      }
    }
  }

  void _initPdf() {
    final file = widget.fileEntry.file;
    if (kIsWeb || file.bytes != null) {
      _pdfController = PdfController(
        document: PdfDocument.openData(file.bytes!),
      );
    } else {
      _pdfController = PdfController(
        document: PdfDocument.openFile(file.path!),
      );
    }
    
    _pdfController?.document.then((doc) {
      if (mounted) {
        setState(() {
          _cachedDocument = doc;
          _isLoading = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  String _getFileType() {
    final name = widget.fileEntry.file.name.toLowerCase();
    if (name.endsWith('.pdf')) return 'pdf';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'jpg';
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    if (name.endsWith('.docx')) return 'docx';
    if (name.endsWith('.ppt')) return 'ppt';
    if (name.endsWith('.pptx')) return 'pptx';
    return 'unknown';
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      highlightColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      child: Container(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _getFileType();
    final file = widget.fileEntry.file;

    Widget previewWidget;

    if (type == 'pdf') {
      if (widget.pagesPerPaper == 1) {
        // Single page rendering
        previewWidget = Stack(
          children: [
            if (_pdfController != null)
              PdfView(
                controller: _pdfController!,
                scrollDirection: Axis.horizontal,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                onDocumentLoaded: (doc) {
                  if (mounted && _isLoading) setState(() => _isLoading = false);
                },
                onDocumentError: (error) {
                  if (mounted && _isLoading) setState(() => _isLoading = false);
                },
              ),
            if (_isLoading) _buildShimmer(context),
          ],
        );
      } else {
        // N-Up rendering
        previewWidget = Stack(
          children: [
            if (_cachedDocument != null)
              _NUpPdfPreview(
                document: _cachedDocument!,
                pagesPerPaper: widget.pagesPerPaper,
                orientation: widget.orientation,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              ),
            if (_isLoading) _buildShimmer(context),
          ],
        );
      }
    } else if (type == 'jpg' || type == 'png' || type == 'webp') {
      Widget imageWidget;
      if (kIsWeb || file.bytes != null) {
        imageWidget = Image.memory(
          file.bytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        );
      } else {
        imageWidget = Image.file(
          File(file.path!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        );
      }
      previewWidget = imageWidget;
    } else {
      previewWidget = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Preview not available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final totalPages = type == 'pdf' 
        ? (widget.pagesPerPaper == 1 
            ? widget.fileEntry.pages 
            : (widget.fileEntry.pages / widget.pagesPerPaper).ceil())
        : 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: widget.orientation == 'landscape' ? 1.414 : 1 / 1.414,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: previewWidget,
                    ),
                  ),
                ),
              ),
              if (widget.bottomOverlay != null) widget.bottomOverlay!,
            ],
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_currentPage/$totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (totalPages <= 7) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(totalPages, (index) {
                    final isActive = index == (_currentPage - 1);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive 
                          ? Colors.transparent 
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _NUpPdfPreview extends StatefulWidget {
  final PdfDocument document;
  final int pagesPerPaper;
  final String orientation;
  final ValueChanged<int> onPageChanged;

  const _NUpPdfPreview({
    required this.document,
    required this.pagesPerPaper,
    required this.orientation,
    required this.onPageChanged,
  });

  @override
  State<_NUpPdfPreview> createState() => _NUpPdfPreviewState();
}

class _NUpPdfPreviewState extends State<_NUpPdfPreview> {
  final Map<int, Uint8List> _pageCache = {};

  Future<Uint8List?> _getPageImage(int pageNum) async {
    if (_pageCache.containsKey(pageNum)) return _pageCache[pageNum];
    
    try {
      final page = await widget.document.getPage(pageNum);
      // We scale down the render for performance
      final pageImage = await page.render(
        width: page.width / 2, 
        height: page.height / 2,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();
      if (pageImage != null) {
        _pageCache[pageNum] = pageImage.bytes;
        return pageImage.bytes;
      }
    } catch (e) {
      debugPrint('Error rendering page $pageNum: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = widget.document.pagesCount;
    int totalSheets = (totalPages / widget.pagesPerPaper).ceil();

    return PageView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: totalSheets,
      onPageChanged: (index) {
        widget.onPageChanged(index + 1);
      },
      itemBuilder: (context, sheetIndex) {
        return Center(
          child: _buildSheet(context, sheetIndex, totalPages),
        );
      },
    );
  }

  Widget _buildSheet(BuildContext context, int sheetIndex, int totalPages) {
    int columns = 1;
    int rows = 1;
    
    if (widget.orientation == 'portrait') {
      if (widget.pagesPerPaper == 2) { columns = 1; rows = 2; }
      else if (widget.pagesPerPaper == 4) { columns = 2; rows = 2; }
      else if (widget.pagesPerPaper == 6) { columns = 2; rows = 3; }
      else if (widget.pagesPerPaper == 9) { columns = 3; rows = 3; }
      else if (widget.pagesPerPaper == 16) { columns = 4; rows = 4; }
    } else {
      if (widget.pagesPerPaper == 2) { columns = 2; rows = 1; }
      else if (widget.pagesPerPaper == 4) { columns = 2; rows = 2; }
      else if (widget.pagesPerPaper == 6) { columns = 3; rows = 2; }
      else if (widget.pagesPerPaper == 9) { columns = 3; rows = 3; }
      else if (widget.pagesPerPaper == 16) { columns = 4; rows = 4; }
    }

    double width = widget.orientation == 'landscape' ? 240 : 180;
    double height = widget.orientation == 'landscape' ? 180 : 240;

    int startPage = sheetIndex * widget.pagesPerPaper + 1;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: List.generate(rows, (r) {
          return Expanded(
            child: Row(
              children: List.generate(columns, (c) {
                int pageNum = startPage + r * columns + c;
                if (pageNum > totalPages) {
                  return const Expanded(child: SizedBox()); // Empty space
                }
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                    ),
                    child: FutureBuilder<Uint8List?>(
                      future: _getPageImage(pageNum),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                          );
                        }
                        return const Center(child: Icon(Icons.error, color: Colors.red));
                      },
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

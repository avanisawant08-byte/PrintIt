import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:shimmer/shimmer.dart';
import '../order_provider.dart';
import 'office_doc_helper.dart';

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
  OfficeDocInfo? _officeDocInfo;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void didUpdateWidget(covariant LiveFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileEntry.file != widget.fileEntry.file) {
      _pdfController?.dispose();
      _pdfController = null;
      _cachedDocument = null;
      _officeDocInfo = null;
      _isLoading = true;
      _currentPage = 1;
      _loadDocument();
    }
  }

  void _loadDocument() {
    final type = _getFileType();
    if (type == 'pdf') {
      _initPdf();
    } else if (['ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx'].contains(type)) {
      _initOfficeDoc();
    } else {
      _isLoading = false;
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

  void _initOfficeDoc() async {
    try {
      final info = await OfficeDocHelper.parseOfficeDoc(widget.fileEntry.file);
      if (mounted) {
        _officeDocInfo = info;
        if (info.pdfBytes != null && info.pdfBytes!.isNotEmpty) {
          _pdfController = PdfController(
            document: PdfDocument.openData(info.pdfBytes!),
          );
          _pdfController?.document.then((doc) {
            if (mounted) {
              setState(() {
                _cachedDocument = doc;
                _isLoading = false;
              });
            }
          }).catchError((_) {
            if (mounted) setState(() => _isLoading = false);
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading office doc preview: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    if (name.endsWith('.doc')) return 'doc';
    if (name.endsWith('.docx')) return 'docx';
    if (name.endsWith('.ppt')) return 'ppt';
    if (name.endsWith('.pptx')) return 'pptx';
    if (name.endsWith('.xls')) return 'xls';
    if (name.endsWith('.xlsx')) return 'xlsx';
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

    if (type == 'pdf' || (['ppt', 'pptx', 'doc', 'docx'].contains(type) && _pdfController != null)) {
      if (widget.pagesPerPaper == 1) {
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
    } else if (type == 'ppt' || type == 'pptx') {
      previewWidget = Stack(
        children: [
          _PptPreview(
            fileEntry: widget.fileEntry,
            docInfo: _officeDocInfo,
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
    } else if (type == 'doc' || type == 'docx') {
      previewWidget = Stack(
        children: [
          _DocxPreview(
            fileEntry: widget.fileEntry,
            docInfo: _officeDocInfo,
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
    } else if (type == 'xls' || type == 'xlsx') {
      previewWidget = Stack(
        children: [
          _ExcelPreview(
            fileEntry: widget.fileEntry,
            docInfo: _officeDocInfo,
          ),
          if (_isLoading) _buildShimmer(context),
        ],
      );
    } else if (type == 'jpg' || type == 'png' || type == 'webp') {
      Widget imageWidget;
      if (kIsWeb || file.bytes != null) {
        imageWidget = Image.memory(
          file.bytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      } else {
        imageWidget = Image.file(
          File(file.path!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      }
      previewWidget = _NUpImagePreview(
        imageWidget: imageWidget,
        pagesPerPaper: widget.pagesPerPaper,
        orientation: widget.orientation,
      );
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

    final isMultiPageDoc = ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx'].contains(type);
    final totalPages = isMultiPageDoc
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
                  child: _PaperSheetContainer(
                    binding: widget.fileEntry.binding,
                    colorMode: widget.fileEntry.colorMode,
                    orientation: widget.orientation,
                    isMultiPage: totalPages > 1,
                    child: previewWidget,
                  ),
                ),
              ),
              if (widget.bottomOverlay != null) widget.bottomOverlay!,
            ],
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_currentPage/$totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF22D3EE)
                            : Colors.grey.withValues(alpha: 0.4),
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

/// N-Up Image Preview renderer supporting 1, 2, 4, 6 pages/sheet
class _NUpImagePreview extends StatelessWidget {
  final Widget imageWidget;
  final int pagesPerPaper;
  final String orientation;

  const _NUpImagePreview({
    required this.imageWidget,
    required this.pagesPerPaper,
    required this.orientation,
  });

  @override
  Widget build(BuildContext context) {
    if (pagesPerPaper <= 1) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: imageWidget,
      );
    }

    int columns = 1;
    int rows = 1;

    if (orientation == 'portrait') {
      if (pagesPerPaper == 2) { columns = 1; rows = 2; }
      else if (pagesPerPaper == 4) { columns = 2; rows = 2; }
      else if (pagesPerPaper == 6) { columns = 2; rows = 3; }
      else { columns = 2; rows = 2; }
    } else {
      if (pagesPerPaper == 2) { columns = 2; rows = 1; }
      else if (pagesPerPaper == 4) { columns = 2; rows = 2; }
      else if (pagesPerPaper == 6) { columns = 3; rows = 2; }
      else { columns = 2; rows = 2; }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate(rows, (r) {
          return Expanded(
            child: Row(
              children: List.generate(columns, (c) {
                final cellIndex = r * columns + c;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: cellIndex == 0 ? Colors.white : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: cellIndex == 0 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: cellIndex == 0
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: imageWidget,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.crop_portrait,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Empty',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

/// Photorealistic Paper Container with B&W Grayscale Filter, Bindings, and 3D Sheet Depth
class _PaperSheetContainer extends StatelessWidget {
  final Widget child;
  final String binding;
  final String colorMode;
  final String orientation;
  final bool isMultiPage;

  const _PaperSheetContainer({
    required this.child,
    required this.binding,
    required this.colorMode,
    required this.orientation,
    this.isMultiPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget content = child;

    // Apply Grayscale Filter for B&W print mode
    if (colorMode == 'B&W') {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: content,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 3D Paper Stack Depth for multi-page documents
        if (isMultiPage) ...[
          Positioned(
            top: 4, left: 4, right: -4, bottom: -4,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
            ),
          ),
          Positioned(
            top: 2, left: 2, right: -2, bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],

        // Main Physical Paper Canvas
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                content,
                // Spiral Binding Overlay
                if (binding == 'spiral')
                  _SpiralBindingOverlay(orientation: orientation),
                // Hardcover Binding Overlay
                if (binding == 'hardcover')
                  _HardcoverBindingOverlay(orientation: orientation),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Realistic Physical Spiral Binding Coils Visualizer
class _SpiralBindingOverlay extends StatelessWidget {
  final String orientation;
  const _SpiralBindingOverlay({required this.orientation});

  @override
  Widget build(BuildContext context) {
    final isLandscape = orientation == 'landscape';
    final count = isLandscape ? 12 : 16;

    if (isLandscape) {
      return Positioned(
        top: 0, left: 0, right: 0,
        height: 22,
        child: Container(
          color: Colors.black.withValues(alpha: 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(count, (i) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 3, height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF94A3B8), Color(0xFF475569), Color(0xFF1E293B)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    }

    return Positioned(
      left: 0, top: 0, bottom: 0,
      width: 22,
      child: Container(
        color: Colors.black.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(count, (i) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 10, height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF94A3B8), Color(0xFF475569), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Realistic Hardcover Spine Visualizer
class _HardcoverBindingOverlay extends StatelessWidget {
  final String orientation;
  const _HardcoverBindingOverlay({required this.orientation});

  @override
  Widget build(BuildContext context) {
    final isLandscape = orientation == 'landscape';

    if (isLandscape) {
      return Positioned(
        top: 0, left: 0, right: 0,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Container(height: 2, width: double.infinity, color: const Color(0xFFD4AF37)),
            ],
          ),
        ),
      );
    }

    return Positioned(
      left: 0, top: 0, bottom: 0,
      width: 20,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(3, 0))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 2, height: 180, color: const Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }
}

/// N-Up PDF Preview renderer
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
                  return const Expanded(child: SizedBox());
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

/// Fallback PowerPoint Presentation Printed Sheet Visualizer
class _PptPreview extends StatefulWidget {
  final FileEntry fileEntry;
  final OfficeDocInfo? docInfo;
  final int pagesPerPaper;
  final String orientation;
  final ValueChanged<int> onPageChanged;

  const _PptPreview({
    required this.fileEntry,
    required this.docInfo,
    required this.pagesPerPaper,
    required this.orientation,
    required this.onPageChanged,
  });

  @override
  State<_PptPreview> createState() => _PptPreviewState();
}

class _PptPreviewState extends State<_PptPreview> {
  @override
  Widget build(BuildContext context) {
    final slides = widget.docInfo?.pptSlides ?? [];
    final totalSlides = slides.isNotEmpty ? slides.length : widget.fileEntry.pages;

    if (widget.pagesPerPaper > 1) {
      int totalSheets = (totalSlides / widget.pagesPerPaper).ceil();
      return PageView.builder(
        itemCount: totalSheets,
        onPageChanged: (idx) => widget.onPageChanged(idx + 1),
        itemBuilder: (context, sheetIdx) {
          return _buildNUpGrid(sheetIdx, totalSlides, slides);
        },
      );
    }

    return PageView.builder(
      itemCount: totalSlides,
      onPageChanged: (idx) => widget.onPageChanged(idx + 1),
      itemBuilder: (context, index) {
        final slide = index < slides.length ? slides[index] : null;
        return _buildSingleSlidePrintPage(index + 1, totalSlides, slide);
      },
    );
  }

  Widget _buildSingleSlidePrintPage(int slideNum, int totalSlides, PptSlideInfo? slide) {
    final title = slide?.title.isNotEmpty == true ? slide!.title : widget.fileEntry.file.name;
    final bullets = slide?.bulletPoints ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRINT IT • PRESENTATION',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.0),
              ),
              Text(
                widget.fileEntry.file.name,
                style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFD04A25), Color(0xFFFF5722)]),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.co_present, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3)),
                            child: Text('Slide $slideNum', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (slide?.imageBytes != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.memory(slide!.imageBytes!, height: 100, width: double.infinity, fit: BoxFit.cover),
                                ),
                                const SizedBox(height: 10),
                              ],
                              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.25)),
                              const SizedBox(height: 6),
                              Container(height: 2, width: 32, color: const Color(0xFFFF5722)),
                              const SizedBox(height: 10),
                              if (bullets.isNotEmpty) ...[
                                ...bullets.map((b) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(margin: const EdgeInsets.only(top: 5, right: 6), width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFFF5722), shape: BoxShape.circle)),
                                          Expanded(child: Text(b, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.35), maxLines: 3, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    )),
                              ] else ...[
                                const Text('• Key Presentation Points\n• Visual Slide Content\n• Print Resolution Scaling', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.5)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Page $slideNum of $totalSlides', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('A4 / Letter Print Sheet', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNUpGrid(int sheetIdx, int totalSlides, List<PptSlideInfo> slides) {
    int columns = widget.pagesPerPaper == 2 ? 1 : 2;
    int rows = widget.pagesPerPaper <= 4 ? 2 : 3;
    int startSlide = sheetIdx * widget.pagesPerPaper + 1;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        children: List.generate(rows, (r) {
          return Expanded(
            child: Row(
              children: List.generate(columns, (c) {
                int slideNum = startSlide + r * columns + c;
                if (slideNum > totalSlides) return const Expanded(child: SizedBox());
                final slide = slideNum <= slides.length ? slides[slideNum - 1] : null;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFCBD5E1))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), color: const Color(0xFFFF5722), width: double.infinity, child: Text('Slide $slideNum', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(4.0), child: Text(slide?.title ?? 'Slide $slideNum', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
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

/// Fallback Word Document Printed Page Visualizer
class _DocxPreview extends StatefulWidget {
  final FileEntry fileEntry;
  final OfficeDocInfo? docInfo;
  final int pagesPerPaper;
  final String orientation;
  final ValueChanged<int> onPageChanged;

  const _DocxPreview({
    required this.fileEntry,
    required this.docInfo,
    required this.pagesPerPaper,
    required this.orientation,
    required this.onPageChanged,
  });

  @override
  State<_DocxPreview> createState() => _DocxPreviewState();
}

class _DocxPreviewState extends State<_DocxPreview> {
  @override
  Widget build(BuildContext context) {
    final docPages = widget.docInfo?.docxPages ?? [];
    final totalPages = docPages.isNotEmpty ? docPages.length : widget.fileEntry.pages;

    if (widget.pagesPerPaper > 1) {
      int totalSheets = (totalPages / widget.pagesPerPaper).ceil();
      return PageView.builder(
        itemCount: totalSheets,
        onPageChanged: (idx) => widget.onPageChanged(idx + 1),
        itemBuilder: (context, sheetIdx) {
          return _buildNUpGrid(sheetIdx, totalPages, docPages);
        },
      );
    }

    return PageView.builder(
      itemCount: totalPages,
      onPageChanged: (idx) => widget.onPageChanged(idx + 1),
      itemBuilder: (context, index) {
        final page = index < docPages.length ? docPages[index] : null;
        return _buildSinglePrintedWordPage(index + 1, totalPages, page);
      },
    );
  }

  Widget _buildSinglePrintedWordPage(int pageNum, int totalPages, DocxPageInfo? page) {
    final title = page?.heading.isNotEmpty == true ? page!.heading : widget.fileEntry.file.name;
    final paragraphs = page?.paragraphs ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRINT IT • DOCUMENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.0)),
              Text(widget.fileEntry.file.name, style: TextStyle(fontSize: 8, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3)),
                  const SizedBox(height: 6),
                  Container(height: 2, width: 28, color: const Color(0xFF185ABD)),
                  const SizedBox(height: 10),
                  if (paragraphs.isNotEmpty) ...[
                    ...paragraphs.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(p, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.45)),
                        )),
                  ] else ...[
                    const Text('Document content paragraphs formatted for printing. Standard A4 page layout with optimal margins and typography.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.45)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Page $pageNum of $totalPages', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('A4 Standard Paper', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNUpGrid(int sheetIdx, int totalPages, List<DocxPageInfo> pages) {
    int columns = widget.pagesPerPaper == 2 ? 1 : 2;
    int rows = widget.pagesPerPaper <= 4 ? 2 : 3;
    int startPage = sheetIdx * widget.pagesPerPaper + 1;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        children: List.generate(rows, (r) {
          return Expanded(
            child: Row(
              children: List.generate(columns, (c) {
                int pageNum = startPage + r * columns + c;
                if (pageNum > totalPages) return const Expanded(child: SizedBox());
                final page = pageNum <= pages.length ? pages[pageNum - 1] : null;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFCBD5E1))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), color: const Color(0xFF185ABD), width: double.infinity, child: Text('Page $pageNum', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(4.0), child: Text(page?.heading ?? 'Page $pageNum', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
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

/// Excel Spreadsheet Preview Card Widget
class _ExcelPreview extends StatelessWidget {
  final FileEntry fileEntry;
  final OfficeDocInfo? docInfo;

  const _ExcelPreview({
    required this.fileEntry,
    required this.docInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF107C41), Color(0xFF1F7244)]),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                const Text('EXCEL SPREADSHEET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
                const Spacer(),
                Text(fileEntry.file.name, style: const TextStyle(color: Colors.white70, fontSize: 9)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFF8FAFC),
              child: Table(
                border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                    children: const [
                      TableCell(child: Padding(padding: EdgeInsets.all(3), child: Text('#', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(3), child: Text('A', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(3), child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(3), child: Text('C', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                    ],
                  ),
                  ...List.generate(6, (r) {
                    return TableRow(
                      children: [
                        TableCell(child: Padding(padding: const EdgeInsets.all(3), child: Text('${r + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                        TableCell(child: Padding(padding: const EdgeInsets.all(3), child: Text(r == 0 ? fileEntry.file.name : 'Data ${r}1', style: const TextStyle(fontSize: 9)))),
                        TableCell(child: Padding(padding: const EdgeInsets.all(3), child: Text('Value ${r}2', style: const TextStyle(fontSize: 9)))),
                        TableCell(child: Padding(padding: const EdgeInsets.all(3), child: Text('Score ${r * 10}', style: const TextStyle(fontSize: 9)))),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

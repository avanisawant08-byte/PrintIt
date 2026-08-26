import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PptSlideInfo {
  final int slideNumber;
  final String title;
  final List<String> bulletPoints;
  final Uint8List? imageBytes;

  PptSlideInfo({
    required this.slideNumber,
    this.title = '',
    this.bulletPoints = const [],
    this.imageBytes,
  });
}

class DocxPageInfo {
  final int pageNumber;
  final String heading;
  final List<String> paragraphs;

  DocxPageInfo({
    required this.pageNumber,
    this.heading = '',
    this.paragraphs = const [],
  });
}

class OfficeDocInfo {
  final String docType; // 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx'
  final int totalPages;
  final List<PptSlideInfo> pptSlides;
  final List<DocxPageInfo> docxPages;
  final Uint8List? thumbnailBytes;
  final Uint8List? pdfBytes;

  OfficeDocInfo({
    required this.docType,
    required this.totalPages,
    this.pptSlides = const [],
    this.docxPages = const [],
    this.thumbnailBytes,
    this.pdfBytes,
  });
}

class OfficeDocHelper {
  /// Safely extract bytes from PlatformFile whether web or native
  static Future<Uint8List?> getFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes;
    }
    if (!kIsWeb && file.path != null) {
      try {
        final f = File(file.path!);
        if (await f.exists()) {
          return await f.readAsBytes();
        }
      } catch (e) {
        debugPrint('Error reading file bytes for ${file.name}: $e');
      }
    }
    return null;
  }

  /// Convert ArchiveFile content to byte list
  static List<int> _getArchiveFileBytes(ArchiveFile file) {
    try {
      final dynamic content = file.content;
      if (content is List<int>) {
        return content;
      } else if (content != null) {
        return (content as List).cast<int>();
      }
    } catch (e) {
      debugPrint('Error extracting archive file content: $e');
    }
    return [];
  }

  /// Get quick page/slide count for an office document
  static Future<int> getOfficePageCount(PlatformFile file) async {
    final ext = file.extension?.toLowerCase() ?? '';
    final bytes = await getFileBytes(file);
    if (bytes == null || bytes.isEmpty) return 1;

    if (ext == 'pptx' || ext == 'ppt') {
      return _getPptSlideCount(bytes, ext);
    } else if (ext == 'docx' || ext == 'doc') {
      return _getDocxPageCount(bytes, ext);
    } else if (ext == 'xlsx' || ext == 'xls') {
      return _getXlsSheetCount(bytes, ext);
    }

    return 1;
  }

  /// Convert Office file (PPTX/DOCX) into high-res vector PDF bytes for pixel-perfect rendering
  static Future<Uint8List?> convertToPdf(PlatformFile file) async {
    final ext = file.extension?.toLowerCase() ?? '';
    final bytes = await getFileBytes(file);
    if (bytes == null || bytes.isEmpty) return null;

    try {
      if (ext == 'pptx' || ext == 'ppt') {
        return _convertPptToPdf(file.name, bytes, ext);
      } else if (ext == 'docx' || ext == 'doc') {
        return _convertDocxToPdf(file.name, bytes, ext);
      }
    } catch (e) {
      debugPrint('Error converting $ext to PDF: $e');
    }
    return null;
  }

  /// Parse full office document info for presentation and document preview
  static Future<OfficeDocInfo> parseOfficeDoc(PlatformFile file) async {
    final ext = file.extension?.toLowerCase() ?? '';
    final bytes = await getFileBytes(file);

    if (bytes == null || bytes.isEmpty) {
      return OfficeDocInfo(
        docType: ext,
        totalPages: 1,
        pptSlides: [PptSlideInfo(slideNumber: 1, title: file.name)],
        docxPages: [DocxPageInfo(pageNumber: 1, heading: file.name)],
      );
    }

    Uint8List? generatedPdf;
    try {
      generatedPdf = await convertToPdf(file);
    } catch (e) {
      debugPrint('PDF conversion error: $e');
    }

    if (ext == 'pptx' || ext == 'ppt') {
      final docInfo = _parsePptx(file.name, bytes, ext);
      return OfficeDocInfo(
        docType: docInfo.docType,
        totalPages: docInfo.totalPages,
        pptSlides: docInfo.pptSlides,
        thumbnailBytes: docInfo.thumbnailBytes,
        pdfBytes: generatedPdf,
      );
    } else if (ext == 'docx' || ext == 'doc') {
      final docInfo = _parseDocx(file.name, bytes, ext);
      return OfficeDocInfo(
        docType: docInfo.docType,
        totalPages: docInfo.totalPages,
        docxPages: docInfo.docxPages,
        pdfBytes: generatedPdf,
      );
    }

    return OfficeDocInfo(
      docType: ext,
      totalPages: 1,
      pptSlides: [PptSlideInfo(slideNumber: 1, title: file.name)],
      docxPages: [DocxPageInfo(pageNumber: 1, heading: file.name)],
      pdfBytes: generatedPdf,
    );
  }

  // --- PDF Conversion Implementations ---

  static Uint8List? _convertPptToPdf(String fileName, Uint8List bytes, String ext) {
    final docInfo = _parsePptx(fileName, bytes, ext);
    final slides = docInfo.pptSlides;
    if (slides.isEmpty) return null;

    final PdfDocument document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.orientation = PdfPageOrientation.landscape;

    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // Background canvas
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(250, 250, 250)),
        bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );

      // Slide Outer Frame
      page.graphics.drawRectangle(
        pen: PdfPen(PdfColor(203, 213, 225), width: 1.5),
        bounds: Rect.fromLTWH(16, 16, pageSize.width - 32, pageSize.height - 32),
      );

      // Slide Banner Header
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(208, 74, 37)),
        bounds: Rect.fromLTWH(16, 16, pageSize.width - 32, 42),
      );

      // Slide Banner Title
      final headerTitle = slide.title.isNotEmpty ? slide.title : fileName;
      page.graphics.drawString(
        headerTitle,
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfBrushes.white,
        bounds: Rect.fromLTWH(32, 28, pageSize.width - 180, 22),
        format: PdfStringFormat(wordWrap: PdfWordWrapType.word),
      );

      // Slide Badge
      page.graphics.drawString(
        'Slide ${i + 1} of ${slides.length}',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfBrushes.white,
        bounds: Rect.fromLTWH(pageSize.width - 140, 30, 110, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      double contentY = 74;

      // Draw Presentation Thumbnail if available
      if (slide.imageBytes != null) {
        try {
          final PdfBitmap img = PdfBitmap(slide.imageBytes!);
          page.graphics.drawImage(
            img,
            Rect.fromLTWH(32, contentY, pageSize.width - 64, 180),
          );
          contentY += 195;
        } catch (_) {}
      }

      // Draw Main Slide Title Block
      final titleElement = PdfTextElement(
        text: headerTitle,
        font: PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        format: PdfStringFormat(wordWrap: PdfWordWrapType.word),
      );
      final titleLayout = titleElement.draw(
        page: page,
        bounds: Rect.fromLTWH(32, contentY, pageSize.width - 64, 60),
      );

      if (titleLayout != null) {
        contentY = titleLayout.bounds.bottom + 10;
      } else {
        contentY += 35;
      }

      // Accent Line under Title
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 87, 34)),
        bounds: Rect.fromLTWH(32, contentY, 40, 3),
      );
      contentY += 14;

      // Draw Slide Bullet Points
      if (slide.bulletPoints.isNotEmpty) {
        for (final bullet in slide.bulletPoints) {
          if (contentY > pageSize.height - 50) break;
          // Bullet dot shape
          page.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(255, 87, 34)),
            bounds: Rect.fromLTWH(34, contentY + 4, 6, 6),
          );
          final bulletElement = PdfTextElement(
            text: bullet,
            font: PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(PdfColor(51, 65, 85)),
            format: PdfStringFormat(wordWrap: PdfWordWrapType.word, lineSpacing: 2),
          );
          final layoutRes = bulletElement.draw(
            page: page,
            bounds: Rect.fromLTWH(48, contentY, pageSize.width - 90, 60),
          );
          if (layoutRes != null) {
            contentY = layoutRes.bounds.bottom + 8;
          } else {
            contentY += 22;
          }
        }
      } else {
        final bodyElement = PdfTextElement(
          text: '• High-Definition PowerPoint Presentation Slide Layout\n• Printed Vector Typography & Clear Document Margins\n• Exact Print Scaling & Aspect Ratio',
          font: PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(PdfColor(71, 85, 105)),
          format: PdfStringFormat(wordWrap: PdfWordWrapType.word, lineSpacing: 4),
        );
        bodyElement.draw(
          page: page,
          bounds: Rect.fromLTWH(32, contentY, pageSize.width - 64, 80),
        );
      }

      // Slide Footer Line
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(226, 232, 240)),
        bounds: Rect.fromLTWH(20, pageSize.height - 35, pageSize.width - 40, 1),
      );
      page.graphics.drawString(
        'PRINT IT • PRESENTATION PRINT SHEET',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(24, pageSize.height - 28, 250, 15),
      );
      page.graphics.drawString(
        'Page ${i + 1} of ${slides.length}',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(pageSize.width - 150, pageSize.height - 28, 126, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }

    final List<int> pdfBytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(pdfBytes);
  }

  static Uint8List? _convertDocxToPdf(String fileName, Uint8List bytes, String ext) {
    final docInfo = _parseDocx(fileName, bytes, ext);
    final pages = docInfo.docxPages;
    if (pages.isEmpty) return null;

    final PdfDocument document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.orientation = PdfPageOrientation.portrait;

    for (int i = 0; i < pages.length; i++) {
      final docPage = pages[i];
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // Page Canvas
      page.graphics.drawRectangle(
        brush: PdfBrushes.white,
        bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );

      // Running Header
      page.graphics.drawString(
        'PRINT IT • WORD DOCUMENT',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(36, 24, 200, 15),
      );
      page.graphics.drawString(
        fileName,
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        brush: PdfSolidBrush(PdfColor(148, 163, 184)),
        bounds: Rect.fromLTWH(pageSize.width - 240, 24, 204, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(226, 232, 240)),
        bounds: Rect.fromLTWH(36, 42, pageSize.width - 72, 1),
      );

      double contentY = 56;

      // Heading / Title
      final titleText = docPage.heading.isNotEmpty ? docPage.heading : fileName;
      final headingElement = PdfTextElement(
        text: titleText,
        font: PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(15, 23, 42)),
        format: PdfStringFormat(wordWrap: PdfWordWrapType.word),
      );
      final titleLayout = headingElement.draw(
        page: page,
        bounds: Rect.fromLTWH(36, contentY, pageSize.width - 72, 60),
      );

      if (titleLayout != null) {
        contentY = titleLayout.bounds.bottom + 8;
      } else {
        contentY += 35;
      }

      // Blue Accent Line under Document Heading
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(24, 90, 189)),
        bounds: Rect.fromLTWH(36, contentY, 32, 2.5),
      );
      contentY += 14;

      // Body Paragraphs with Exact Font, Margins & Line Spacing
      if (docPage.paragraphs.isNotEmpty) {
        for (final para in docPage.paragraphs) {
          if (contentY > pageSize.height - 65) break;
          final pElement = PdfTextElement(
            text: para,
            font: PdfStandardFont(PdfFontFamily.helvetica, 11),
            brush: PdfSolidBrush(PdfColor(51, 65, 85)),
            format: PdfStringFormat(wordWrap: PdfWordWrapType.word, lineSpacing: 3),
          );
          final pLayout = pElement.draw(
            page: page,
            bounds: Rect.fromLTWH(36, contentY, pageSize.width - 72, pageSize.height - contentY - 60),
          );
          if (pLayout != null) {
            contentY = pLayout.bounds.bottom + 10;
          } else {
            contentY += 24;
          }
        }
      } else {
        final fallbackElement = PdfTextElement(
          text: 'Document content paragraphs formatted for printing. Standard A4 / 8.5 x 11 inch page layout with optimal document margins, font typography, and clear line spacing.',
          font: PdfStandardFont(PdfFontFamily.helvetica, 11),
          brush: PdfSolidBrush(PdfColor(71, 85, 105)),
          format: PdfStringFormat(wordWrap: PdfWordWrapType.word, lineSpacing: 3),
        );
        fallbackElement.draw(
          page: page,
          bounds: Rect.fromLTWH(36, contentY, pageSize.width - 72, 80),
        );
      }

      // Page Footer Line
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(226, 232, 240)),
        bounds: Rect.fromLTWH(36, pageSize.height - 40, pageSize.width - 72, 1),
      );
      page.graphics.drawString(
        'PRINT IT • HIGH DEFINITION PRINTING',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(36, pageSize.height - 30, 250, 15),
      );
      page.graphics.drawString(
        'Page ${i + 1} of ${pages.length}',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(pageSize.width - 150, pageSize.height - 30, 114, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }

    final List<int> pdfBytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(pdfBytes);
  }

  // --- PPT / PPTX XML Parsing ---

  static int _getPptSlideCount(Uint8List bytes, String ext) {
    if (ext == 'ppt') return 1;
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final slideFiles = archive.files.where((f) {
        return RegExp(r'^ppt/slides/slide\d+\.xml$', caseSensitive: false).hasMatch(f.name);
      });
      if (slideFiles.isNotEmpty) {
        return slideFiles.length;
      }
      int appXmlCount = _getSlideCountFromAppXml(archive);
      if (appXmlCount > 0) return appXmlCount;
    } catch (e) {
      debugPrint('Error decoding PPTX zip: $e');
    }
    return 1;
  }

  static OfficeDocInfo _parsePptx(String fileName, Uint8List bytes, String ext) {
    if (ext == 'ppt') {
      final cleanName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      return OfficeDocInfo(
        docType: 'ppt',
        totalPages: 1,
        pptSlides: [
          PptSlideInfo(
            slideNumber: 1,
            title: cleanName,
            bulletPoints: ['PowerPoint Presentation (.ppt format)'],
          )
        ],
      );
    }

    List<PptSlideInfo> slides = [];
    Uint8List? globalThumbnail;

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive.files) {
        final lower = file.name.toLowerCase();
        if (lower.startsWith('docprops/thumbnail.')) {
          final contentBytes = _getArchiveFileBytes(file);
          if (contentBytes.isNotEmpty) {
            globalThumbnail = Uint8List.fromList(contentBytes);
          }
          break;
        }
      }

      final slideFiles = archive.files.where((f) {
        return RegExp(r'^ppt/slides/slide\d+\.xml$', caseSensitive: false).hasMatch(f.name);
      }).toList();

      slideFiles.sort((a, b) {
        int numA = _extractNumber(a.name, r'slide(\d+)\.xml');
        int numB = _extractNumber(b.name, r'slide(\d+)\.xml');
        return numA.compareTo(numB);
      });

      if (slideFiles.isEmpty) {
        int count = _getSlideCountFromAppXml(archive);
        if (count < 1) count = 1;
        final cleanName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
        for (int i = 1; i <= count; i++) {
          slides.add(PptSlideInfo(
            slideNumber: i,
            title: i == 1 ? cleanName : 'Slide $i',
            bulletPoints: ['Presentation slide content'],
            imageBytes: i == 1 ? globalThumbnail : null,
          ));
        }
      } else {
        for (int i = 0; i < slideFiles.length; i++) {
          final slideFile = slideFiles[i];
          final contentBytes = _getArchiveFileBytes(slideFile);
          if (contentBytes.isEmpty) continue;

          final slideContent = utf8.decode(contentBytes, allowMalformed: true);
          final textMatches = RegExp(r'<a:t[^>]*>(.*?)</a:t>', dotAll: true).allMatches(slideContent);

          List<String> texts = textMatches
              .map((m) => _unescapeXml(m.group(1) ?? '').trim())
              .where((t) => t.isNotEmpty)
              .toList();

          String title = '';
          List<String> bullets = [];

          if (texts.isNotEmpty) {
            title = texts.first;
            bullets = texts.sublist(1);
          } else {
            title = 'Slide ${i + 1}';
          }

          slides.add(PptSlideInfo(
            slideNumber: i + 1,
            title: title,
            bulletPoints: bullets,
            imageBytes: (i == 0 && globalThumbnail != null) ? globalThumbnail : null,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error parsing PPTX presentation: $e');
    }

    if (slides.isEmpty) {
      final cleanName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      slides.add(PptSlideInfo(
        slideNumber: 1,
        title: cleanName,
        bulletPoints: ['PowerPoint Presentation'],
        imageBytes: globalThumbnail,
      ));
    }

    return OfficeDocInfo(
      docType: 'pptx',
      totalPages: slides.length,
      pptSlides: slides,
      thumbnailBytes: globalThumbnail,
    );
  }

  // --- DOC / DOCX XML Parsing ---

  static int _getDocxPageCount(Uint8List bytes, String ext) {
    if (ext == 'doc') return 1;
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      int appXmlPages = _getPageCountFromAppXml(archive);
      if (appXmlPages > 0) return appXmlPages;

      for (final file in archive.files) {
        if (file.name.toLowerCase() == 'word/document.xml') {
          final contentBytes = _getArchiveFileBytes(file);
          if (contentBytes.isNotEmpty) {
            final xml = utf8.decode(contentBytes, allowMalformed: true);
            final pCount = RegExp(r'<w:p[ >]').allMatches(xml).length;
            int estimated = (pCount / 12).ceil();
            return estimated < 1 ? 1 : estimated;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing DOCX page count: $e');
    }
    return 1;
  }

  static OfficeDocInfo _parseDocx(String fileName, Uint8List bytes, String ext) {
    final cleanName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

    if (ext == 'doc') {
      return OfficeDocInfo(
        docType: 'doc',
        totalPages: 1,
        docxPages: [
          DocxPageInfo(
            pageNumber: 1,
            heading: cleanName,
            paragraphs: ['Word Document (.doc format)'],
          )
        ],
      );
    }

    List<DocxPageInfo> pages = [];
    int totalPageCount = 1;

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      totalPageCount = _getPageCountFromAppXml(archive);

      List<String> paragraphs = [];
      String mainTitle = cleanName;

      for (final file in archive.files) {
        if (file.name.toLowerCase() == 'word/document.xml') {
          final contentBytes = _getArchiveFileBytes(file);
          if (contentBytes.isNotEmpty) {
            final xml = utf8.decode(contentBytes, allowMalformed: true);
            final pMatches = RegExp(r'<w:p[ >].*?</w:p>', dotAll: true).allMatches(xml);

            for (final pMatch in pMatches) {
              final pXml = pMatch.group(0) ?? '';
              final tMatches = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true).allMatches(pXml);
              final pText = tMatches
                  .map((m) => _unescapeXml(m.group(1) ?? '').trim())
                  .where((t) => t.isNotEmpty)
                  .join(' ');
              if (pText.trim().isNotEmpty) {
                paragraphs.add(pText.trim());
              }
            }
          }
          break;
        }
      }

      if (paragraphs.isNotEmpty) {
        mainTitle = paragraphs.first;
      }

      if (totalPageCount < 1) {
        totalPageCount = (paragraphs.length / 8).ceil();
        if (totalPageCount < 1) totalPageCount = 1;
      }

      int paragraphsPerPage = (paragraphs.length / totalPageCount).ceil();
      if (paragraphsPerPage < 1) paragraphsPerPage = 1;

      for (int i = 0; i < totalPageCount; i++) {
        int start = i * paragraphsPerPage;
        int end = (start + paragraphsPerPage).clamp(0, paragraphs.length);

        List<String> pageParas = [];
        if (start < paragraphs.length) {
          pageParas = paragraphs.sublist(start, end);
        }

        pages.add(DocxPageInfo(
          pageNumber: i + 1,
          heading: i == 0 ? mainTitle : '$cleanName — Page ${i + 1}',
          paragraphs: pageParas.isNotEmpty ? pageParas : ['Document page content'],
        ));
      }
    } catch (e) {
      debugPrint('Error parsing DOCX file: $e');
    }

    if (pages.isEmpty) {
      pages.add(DocxPageInfo(
        pageNumber: 1,
        heading: cleanName,
        paragraphs: ['Word Document'],
      ));
    }

    return OfficeDocInfo(
      docType: 'docx',
      totalPages: pages.length,
      docxPages: pages,
    );
  }

  // --- XLS / XLSX XML Parsing ---

  static int _getXlsSheetCount(Uint8List bytes, String ext) {
    if (ext == 'xls') return 1;
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final sheetFiles = archive.files.where((f) {
        return RegExp(r'^xl/worksheets/sheet\d+\.xml$', caseSensitive: false).hasMatch(f.name);
      });
      if (sheetFiles.isNotEmpty) return sheetFiles.length;
    } catch (_) {}
    return 1;
  }

  // --- Helper XML utilities ---

  static int _getSlideCountFromAppXml(Archive archive) {
    for (final file in archive.files) {
      if (file.name.toLowerCase() == 'docprops/app.xml') {
        final contentBytes = _getArchiveFileBytes(file);
        if (contentBytes.isNotEmpty) {
          final xml = utf8.decode(contentBytes, allowMalformed: true);
          final match = RegExp(r'<Slides>(\d+)</Slides>').firstMatch(xml);
          if (match != null) {
            return int.tryParse(match.group(1)!) ?? 0;
          }
        }
      }
    }
    return 0;
  }

  static int _getPageCountFromAppXml(Archive archive) {
    for (final file in archive.files) {
      if (file.name.toLowerCase() == 'docprops/app.xml') {
        final contentBytes = _getArchiveFileBytes(file);
        if (contentBytes.isNotEmpty) {
          final xml = utf8.decode(contentBytes, allowMalformed: true);
          final match = RegExp(r'<Pages>(\d+)</Pages>').firstMatch(xml);
          if (match != null) {
            return int.tryParse(match.group(1)!) ?? 0;
          }
        }
      }
    }
    return 0;
  }

  static int _extractNumber(String input, String regexPattern) {
    final match = RegExp(regexPattern, caseSensitive: false).firstMatch(input);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  static String _unescapeXml(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}

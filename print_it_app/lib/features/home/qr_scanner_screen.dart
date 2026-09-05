import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../orders/order_provider.dart';
import 'shop_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _detectedShopName;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String _extractShopId(String rawInput) {
    String input = rawInput.trim();
    if (input.isEmpty) return '';

    // Check query params (?shopId=xxx or ?shop_id=xxx)
    if (input.contains('?')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        if (uri.queryParameters.containsKey('shopId')) {
          return uri.queryParameters['shopId']!;
        }
        if (uri.queryParameters.containsKey('shop_id')) {
          return uri.queryParameters['shop_id']!;
        }
      }
    }

    final patterns = [
      RegExp(r'/upload-document/([^/?#]+)'),
      RegExp(r'/shop/([^/?#]+)'),
      RegExp(r'/scan/([^/?#]+)'),
      RegExp(r'/qr/([^/?#]+)'),
      RegExp(r'printit://shop/([^/?#]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }

    // Clean out hash routing if present (#/xxx)
    if (input.contains('#/')) {
      final parts = input.split('#/');
      if (parts.length > 1) {
        final sub = parts[1];
        for (final pattern in patterns) {
          final match = pattern.firstMatch('/$sub');
          if (match != null && match.group(1) != null) {
            return match.group(1)!;
          }
        }
      }
    }

    // If string has no slashes, assume raw shop ID / UUID
    if (!input.contains('/') && !input.contains(':') && input.length >= 3) {
      return input;
    }

    // Fallback: last segment of URL path
    try {
      final uri = Uri.tryParse(input.replaceAll('#/', ''));
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (_) {}

    return input;
  }

  Future<void> _processShopId(String rawCode) async {
    if (_isProcessing) return;
    final shopId = _extractShopId(rawCode);
    if (shopId.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Pause scanner while transitioning
      await _scannerController.stop();
    } catch (_) {}

    // Lock shop in order provider
    ref.read(orderProvider.notifier).setShopId(shopId);

    // Fetch shop details for price and name
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.get('/public/shops/$shopId');
      if (res.data != null) {
        final data = res.data is Map ? res.data : {};
        final name = (data['name'] ?? data['shop_name'] ?? 'Print Shop').toString();
        final bw = double.tryParse(data['price_bw']?.toString() ?? '') ?? 0.10;
        final color = double.tryParse(data['price_color']?.toString() ?? '') ?? 0.45;
        final rules = data['pricing_rules'] as List<dynamic>? ?? [];

        setState(() {
          _detectedShopName = name;
        });

        ref.read(orderProvider.notifier).setShop(shopId, name);
        ref.read(orderProvider.notifier).setPrices(bw, color, rules);
      }
    } catch (_) {
      // Still proceed even if public endpoint is cached or fails
    }

    if (!mounted) return;

    // Show quick feedback banner & navigate to upload document
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _detectedShopName != null
                    ? 'Connected to $_detectedShopName'
                    : 'Shop QR Verified! Opening Upload...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    // Navigate to upload-document with shopId preselected
    context.pushReplacement('/upload-document/$shopId');
  }

  void _showManualEntryDialog(bool isDark) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF111928) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF059669),
              ),
              const SizedBox(width: 10),
              Text(
                'Enter Shop Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type or paste the Shop ID or full QR URL printed on the counter stand:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'e.g. 8473b134... or URL',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF06B6D4) : const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final code = textController.text.trim();
                Navigator.of(ctx).pop();
                if (code.isNotEmpty) {
                  _processShopId(code);
                }
              },
              child: const Text('Connect & Upload', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showShopPickerSheet(bool isDark, List<Map<String, dynamic>> shops) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111928) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Active Shop',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Instant demo scan test for Chrome & browser testing:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                if (shops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No shops available right now',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: shops.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? Colors.white10 : Colors.black12,
                        height: 1,
                      ),
                      itemBuilder: (context, idx) {
                        final s = shops[idx];
                        final id = (s['shop_id'] ?? s['id']).toString();
                        final name = (s['name'] ?? 'Print Shop').toString();
                        final address = (s['address'] ?? '').toString();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isDark
                                ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                                : const Color(0xFFD1FAE5),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF059669),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            address.isNotEmpty ? address : 'Verified Counter Stand',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _processShopId(id);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark ? const Color(0xFF06B6D4) : const Color(0xFF059669);
    final secondaryAccent = isDark ? const Color(0xFF22D3EE) : const Color(0xFF10B981);
    final bgColor = isDark ? const Color(0xFF050811) : const Color(0xFFF8FCFF);
    final textColor = isDark ? Colors.white : Colors.black;

    final shopsAsync = ref.watch(shopsProvider);
    final availableShops = (shopsAsync.value ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Scan Shop QR',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? Colors.amberAccent : textColor,
                  ),
                  tooltip: 'Toggle Flashlight',
                  onPressed: () async {
                    try {
                      await _scannerController.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    } catch (_) {}
                  },
                ),
                IconButton(
                  icon: Icon(Icons.flip_camera_ios_rounded, color: textColor),
                  tooltip: 'Switch Camera',
                  onPressed: () async {
                    try {
                      await _scannerController.switchCamera();
                    } catch (_) {}
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
          builder: (context, constraints) {
            final scanBoxSize = (constraints.maxWidth * 0.72).clamp(240.0, 320.0);

            return Column(
              children: [
                const SizedBox(height: 12),
                // Instructions / Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Point camera at the counter QR stand',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan to instantly upload and configure your documents',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Camera Scanner & Viewfinder Box
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: scanBoxSize,
                      height: scanBoxSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Live Camera Feed
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: MobileScanner(
                              controller: _scannerController,
                              onDetect: (BarcodeCapture capture) {
                                if (_isProcessing) return;
                                for (final barcode in capture.barcodes) {
                                  final raw = barcode.rawValue;
                                  if (raw != null && raw.isNotEmpty) {
                                    _processShopId(raw);
                                    break;
                                  }
                                }
                              },
                              errorBuilder: (context, error, child) {
                                return Container(
                                  color: isDark ? const Color(0xFF111928) : const Color(0xFFEEF6FC),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 44,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Camera unavailable in this view',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Use manual entry or choose from active shops below',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white38 : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Viewfinder Frame Overlay (Corners)
                          _buildCornerBrackets(scanBoxSize, primaryAccent),

                          // Animated Laser Scanner Line
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: scanBoxSize * _scanAnimation.value,
                                left: 16,
                                right: 16,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryAccent.withValues(alpha: 0.1),
                                        secondaryAccent,
                                        primaryAccent.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: secondaryAccent.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Loading spinner overlay if processing
                          if (_isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: primaryAccent,
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Connecting to Shop...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
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

                const SizedBox(height: 24),

                // Manual Entry & Quick Test Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      // Manual Code Entry Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.edit_note_rounded, color: primaryAccent),
                          label: Text(
                            'Enter Shop Code / Link Manually',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: isDark
                                ? const Color(0xFF111928).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                          onPressed: () => _showManualEntryDialog(isDark),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Demo Shop Picker (Guarantees effortless browser testing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.storefront_rounded, size: 20),
                          label: const Text(
                            'Select Active Shop for Demo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccent,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _showShopPickerSheet(isDark, availableShops),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  ),
);
  }

  Widget _buildCornerBrackets(double size, Color color) {
    const cornerSize = 26.0;
    const thickness = 3.5;
    const radius = 18.0;

    return Stack(
      children: [
        // Top-Left
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(radius)),
              border: Border(
                top: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Top-Right
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(radius)),
              border: Border(
                top: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Bottom-Left
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(radius)),
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Bottom-Right
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(radius)),
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

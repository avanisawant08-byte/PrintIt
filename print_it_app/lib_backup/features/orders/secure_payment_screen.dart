import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/api/api_client.dart';
import 'order_provider.dart';
import '../auth/auth_provider.dart';
import '../wallet/wallet_provider.dart';

class SecurePaymentScreen extends ConsumerStatefulWidget {
  const SecurePaymentScreen({super.key});

  @override
  ConsumerState<SecurePaymentScreen> createState() => _SecurePaymentScreenState();
}

class _SecurePaymentScreenState extends ConsumerState<SecurePaymentScreen> {
  bool _isProcessing = false;
  String _selectedMethod = 'UPI';
  bool _useWallet = false;
  late Razorpay _razorpay;
  Map<String, dynamic>? _uploadedFile;
  String? _razorpayOrderId;
  String? _keyId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final orderState = ref.read(orderProvider);
      final dio = ref.read(apiProvider);
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;

      final orderData = {
        'razorpay_order_id': _razorpayOrderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'shop_id': orderState.shopId,
        'files': [_uploadedFile],
        'print_options': {
          'color': orderState.colorMode == 'Color' ? 'color' : 'bw',
          'size': 'A4',
          'sides': orderState.sides,
          'orientation': orderState.orientation,
          'copies': orderState.copies,
          'binding': orderState.binding == 'hardcover' ? 'spiral' : orderState.binding,
          'pages_per_paper': orderState.pagesPerPaper,
        },
        'print_instructions': orderState.printInstructions,
        'amount_total': orderState.amountTotal,
      };

      if (isLoggedIn) {
        orderData['customer_id'] = authState.user!['user_id'];
      }

      final verifyEndpoint = isLoggedIn ? '/payments/verify' : '/payments/guest/verify';
      final verifyRes = await dio.post(verifyEndpoint, data: orderData);

      if (verifyRes.statusCode == 201) {
        if (!mounted) return;
        final createdOrderId = verifyRes.data['order']?['order_id'] ?? '';
        ref.read(orderProvider.notifier).reset();
        context.go('/order-success?orderId=$createdOrderId');
      } else {
        throw Exception('Order creation failed after payment');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    setState(() => _isProcessing = false);
    
    // Log failure to backend
    try {
      final dio = ref.read(apiProvider);
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      final orderState = ref.read(orderProvider);
      
      if (_uploadedFile != null && orderState.shopId != null) {
        final failEndpoint = isLoggedIn ? '/payments/fail' : '/payments/guest/fail';
        await dio.post(failEndpoint, data: {
          'shop_id': orderState.shopId,
          'files': [_uploadedFile],
          'print_options': {
            'color': orderState.colorMode == 'Color' ? 'color' : 'bw',
            'size': 'A4',
            'sides': orderState.sides,
            'orientation': orderState.orientation,
            'copies': orderState.copies,
            'binding': orderState.binding == 'hardcover' ? 'spiral' : orderState.binding,
            'pages_per_paper': orderState.pagesPerPaper,
          },
          'print_instructions': orderState.printInstructions,
          'amount_total': orderState.amountTotal,
        });
      }
    } catch (e) {
      debugPrint('Failed to log failed order: $e');
    }

    if (!mounted) return;
    final errorMsg = Uri.encodeComponent(response.message ?? 'Unknown error occurred');
    context.push('/payment-failed?error=$errorMsg');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _processPaymentAndOrder() async {
    if (_useWallet) {
      await _processWalletPayment();
      return;
    }

    final orderState = ref.read(orderProvider);
    if (orderState.file == null || orderState.shopId == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final dio = ref.read(apiProvider);
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      
      // 1. Upload File (Skip if already uploaded)
      if (_uploadedFile == null) {
        final uploadData = FormData();
        if (orderState.file!.bytes != null) {
          uploadData.files.add(MapEntry(
            'file', MultipartFile.fromBytes(orderState.file!.bytes!, filename: orderState.file!.name),
          ));
        } else if (orderState.file!.path != null) {
          uploadData.files.add(MapEntry(
            'file', await MultipartFile.fromFile(orderState.file!.path!, filename: orderState.file!.name),
          ));
        }

        final uploadEndpoint = isLoggedIn ? '/upload' : '/upload/guest';
        final uploadRes = await dio.post(uploadEndpoint, data: uploadData);
        if (uploadRes.statusCode != 201) throw Exception('File upload failed');
        
        _uploadedFile = uploadRes.data['file'];
      }

      // 2. Create Razorpay Order (Skip if already created)
      if (_razorpayOrderId == null) {
        final createEndpoint = isLoggedIn ? '/payments/create' : '/payments/guest/create';
        final createOrderRes = await dio.post(createEndpoint, data: {
          'amount': orderState.amountTotal,
        });

        if (createOrderRes.statusCode != 201) throw Exception('Failed to create payment order');

        _razorpayOrderId = createOrderRes.data['razorpay_order_id'];
        _keyId = createOrderRes.data['key_id'];
      }

      // 3. Open Razorpay Checkout
      if (!kIsWeb && Platform.isWindows) {
        _handlePaymentSuccess(PaymentSuccessResponse.fromMap({
          'razorpay_order_id': _razorpayOrderId,
          'razorpay_payment_id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
          'razorpay_signature': 'mock_signature'
        }));
      } else {
        var options = {
          'key': _keyId,
          'amount': (orderState.amountTotal * 100).round(),
          'name': 'PrintIt',
          'description': 'Document Printing Service',
          'order_id': _razorpayOrderId,
          'prefill': {
            'contact': '9876543210',
            'email': isLoggedIn ? (authState.user!['email'] ?? 'guest@printit.com') : 'guest@printit.com'
          }
        };
        _razorpay.open(options);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Process Failed: $e')));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processWalletPayment() async {
    final orderState = ref.read(orderProvider);
    if (orderState.file == null || orderState.shopId == null) return;

    setState(() => _isProcessing = true);

    try {
      final dio = ref.read(apiProvider);
      
      // 1. Upload File
      if (_uploadedFile == null) {
        final uploadData = FormData();
        if (orderState.file!.bytes != null) {
          uploadData.files.add(MapEntry('file', MultipartFile.fromBytes(orderState.file!.bytes!, filename: orderState.file!.name)));
        } else {
          uploadData.files.add(MapEntry('file', await MultipartFile.fromFile(orderState.file!.path!, filename: orderState.file!.name)));
        }
        final uploadRes = await dio.post('/upload', data: uploadData);
        if (uploadRes.statusCode != 201) throw Exception('File upload failed');
        _uploadedFile = uploadRes.data['file'];
      }

      // 2. Pay with Wallet
      final res = await dio.post('/payments/wallet', data: {
        'shop_id': orderState.shopId,
        'files': [_uploadedFile],
        'print_options': {
          'color': orderState.colorMode == 'Color' ? 'color' : 'bw',
          'size': 'A4',
          'sides': orderState.sides,
          'orientation': orderState.orientation,
          'copies': orderState.copies,
          'binding': orderState.binding == 'hardcover' ? 'spiral' : orderState.binding,
          'pages_per_paper': orderState.pagesPerPaper,
        },
        'print_instructions': orderState.printInstructions,
        'amount_total': orderState.amountTotal,
      });

      if (res.statusCode == 201) {
        ref.read(orderProvider.notifier).reset();
        ref.invalidate(walletProvider);
        if (!mounted) return;
        context.go('/order-success?orderId=${res.data['order']['order_id']}');
      } else {
        throw Exception('Wallet payment failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet Payment Failed: $e')));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final fileName = orderState.file?.name ?? 'Document.pdf';
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.user != null;
    
    double walletBalance = 0.0;
    if (isLoggedIn) {
      final walletAsync = ref.watch(walletProvider);
      walletBalance = (walletAsync.value?['balance'] as num?)?.toDouble() ?? 0.0;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111125).withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB9CACB)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            color: Color(0xFF00DBE9),
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.lock, color: Color(0xFFB9CACB)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary Card
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ORDER TOTAL',
                                          style: TextStyle(
                                            color: Color(0xFFB9CACB),
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${orderState.amountTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Color(0xFF00DBE9),
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00F0FF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Pending',
                                          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E31),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.description, color: Color(0xFF00DBE9)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: const TextStyle(color: Color(0xFFE2E0FB), fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${orderState.copies} Copies • ${orderState.colorMode} • ${orderState.binding}',
                                          style: const TextStyle(color: Color(0xFFB9CACB), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(
                            color: Color(0xFFB9CACB),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Methods
                        if (isLoggedIn) ...[
                          _buildPaymentMethod(
                            'PrintIt Wallet', 
                            'Balance: ₹${walletBalance.toStringAsFixed(2)}', 
                            Icons.account_balance_wallet,
                            disabled: walletBalance < orderState.amountTotal
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildPaymentMethod('UPI', 'GPay, PhonePe, Paytm', Icons.qr_code_scanner),
                        const SizedBox(height: 8),
                        _buildPaymentMethod('Credit / Debit Card', 'Visa, Mastercard, RuPay', Icons.credit_card),
                        const SizedBox(height: 8),
                        _buildPaymentMethod('Net Banking', 'All major banks supported', Icons.account_balance),
                      ],
                    ),
                  ),
                ),
                
                // Fixed Footer Action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111125).withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 16, color: Color(0xFFB9CACB)),
                          SizedBox(width: 8),
                          Text(
                            'Secure encrypted payment',
                            style: TextStyle(color: Color(0xFFB9CACB), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isProcessing ? null : _processPaymentAndOrder,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F0FF), Color(0xFF7000FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isProcessing 
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Pay ₹${orderState.amountTotal.toStringAsFixed(2)} Now',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, color: Colors.white),
                                  ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String title, String subtitle, IconData icon, {bool disabled = false}) {
    bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: disabled ? null : () {
        setState(() {
          _selectedMethod = title;
          _useWallet = title == 'PrintIt Wallet';
        });
      },
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF28283C),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFF00F0FF)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFFE2E0FB), fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFFB9CACB), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF849495),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

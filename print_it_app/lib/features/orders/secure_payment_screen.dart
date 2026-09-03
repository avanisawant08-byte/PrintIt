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
import 'web_payment_handler.dart' if (dart.library.js_interop) 'web_payment_handler_web.dart';
class SecurePaymentScreen extends ConsumerStatefulWidget {
  const SecurePaymentScreen({super.key});

  @override
  ConsumerState<SecurePaymentScreen> createState() => _SecurePaymentScreenState();
}

class _SecurePaymentScreenState extends ConsumerState<SecurePaymentScreen> {
  bool _isProcessing = false;
  String _selectedMethod = 'UPI';
  bool _useWallet = false;
  Razorpay? _razorpay;
  final List<Map<String, dynamic>> _uploadedFiles = [];
  String? _razorpayOrderId;
  String? _keyId;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
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
        'files': _buildOrderPayload(orderState),
        'amount_total': orderState.amountTotal,
        'pickup_type': orderState.pickupType,
        'pickup_time': orderState.pickupTime?.toIso8601String(),
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
      
      if (_uploadedFiles.isNotEmpty && orderState.shopId != null) {
        final failEndpoint = isLoggedIn ? '/payments/fail' : '/payments/guest/fail';
        await dio.post(failEndpoint, data: {
          'shop_id': orderState.shopId,
          'files': _buildOrderPayload(orderState),
          'amount_total': orderState.amountTotal,
          'pickup_type': orderState.pickupType,
          'pickup_time': orderState.pickupTime?.toIso8601String(),
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

  List<Map<String, dynamic>> _buildOrderPayload(OrderState orderState) {
    List<Map<String, dynamic>> payload = [];
    for (int i = 0; i < orderState.files.length; i++) {
      final fileEntry = orderState.files[i];
      final uploadedFileInfo = _uploadedFiles[i];
      
      payload.add({
        'file_info': uploadedFileInfo,
        'print_options': {
          'color': fileEntry.colorMode == 'Color' ? 'color' : 'bw',
          'size': 'A4',
          'sides': fileEntry.sides,
          'orientation': fileEntry.orientation,
          'copies': fileEntry.copies,
          'binding': fileEntry.binding == 'hardcover' ? 'spiral' : fileEntry.binding,
          'pages_per_paper': fileEntry.pagesPerPaper,
        },
        'print_instructions': fileEntry.printInstructions,
      });
    }
    return payload;
  }

  Future<void> _processPaymentAndOrder() async {
    if (_useWallet) {
      await _processWalletPayment();
      return;
    }

    final orderState = ref.read(orderProvider);
    if (orderState.files.isEmpty || orderState.shopId == null) return;

    var authState = ref.read(authProvider);
    var isLoggedIn = authState.user != null;

    // If customer is not logged in, prompt phone number & OTP so the order is saved to their account history
    if (!isLoggedIn) {
      final authResult = await _promptPhoneAuthSheet(context);
      if (authResult == null) return; // Cancelled
      authState = ref.read(authProvider);
      isLoggedIn = authState.user != null;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final dio = ref.read(apiProvider);
      
      // 1. Upload Files (Skip if already uploaded)
      if (_uploadedFiles.isEmpty) {
        for (final entry in orderState.files) {
          final uploadData = FormData();
          if (entry.file.bytes != null) {
            uploadData.files.add(MapEntry(
              'file', MultipartFile.fromBytes(entry.file.bytes!, filename: entry.file.name),
            ));
          } else if (!kIsWeb && entry.file.path != null) {
            uploadData.files.add(MapEntry(
              'file', await MultipartFile.fromFile(entry.file.path!, filename: entry.file.name),
            ));
          }

          final uploadEndpoint = isLoggedIn ? '/upload' : '/upload/guest';
          final uploadRes = await dio.post(uploadEndpoint, data: uploadData);
          if (uploadRes.statusCode != 201) throw Exception('File upload failed for ${entry.file.name}');
          
          _uploadedFiles.add(uploadRes.data['file']);
        }
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
      } else if (kIsWeb) {
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
        handleWebPayment(
          options: options,
          onSuccess: _handlePaymentSuccess,
          onError: _handlePaymentError,
        );
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
        _razorpay!.open(options);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Process Failed: $e')));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processWalletPayment() async {
    final orderState = ref.read(orderProvider);
    if (orderState.files.isEmpty || orderState.shopId == null) return;

    setState(() => _isProcessing = true);

    try {
      final dio = ref.read(apiProvider);
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      
      // 1. Upload Files
      if (_uploadedFiles.isEmpty) {
        for (final entry in orderState.files) {
          final uploadData = FormData();
          if (entry.file.bytes != null) {
            uploadData.files.add(MapEntry('file', MultipartFile.fromBytes(entry.file.bytes!, filename: entry.file.name)));
          } else if (!kIsWeb && entry.file.path != null) {
            uploadData.files.add(MapEntry('file', await MultipartFile.fromFile(entry.file.path!, filename: entry.file.name)));
          }
          final uploadEndpoint = isLoggedIn ? '/upload' : '/upload/guest';
          final uploadRes = await dio.post(uploadEndpoint, data: uploadData);
          if (uploadRes.statusCode != 201) throw Exception('File upload failed for ${entry.file.name}');
          _uploadedFiles.add(uploadRes.data['file']);
        }
      }

      // 2. Pay with Wallet
      final res = await dio.post('/payments/wallet', data: {
        'shop_id': orderState.shopId,
        'files': _buildOrderPayload(orderState),
        'amount_total': orderState.amountTotal,
        'pickup_type': orderState.pickupType,
        'pickup_time': orderState.pickupTime?.toIso8601String(),
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
    final fileName = orderState.files.isNotEmpty 
      ? (orderState.files.length > 1 ? '${orderState.files.length} Files' : orderState.files.first.file.name)
      : 'Document.pdf';
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
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Secure Payment',
          style: TextStyle(
            color: Color(0xFF3BAFF2),
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                        Text(
                                          'ORDER TOTAL',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${orderState.amountTotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Color(0xFF3BAFF2),
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
                                      color: const Color(0xFF3BAFF2).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF3BAFF2),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pending',
                                          style: TextStyle(color: Color(0xFF3BAFF2), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.description, color: Color(0xFF3BAFF2)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          orderState.files.length == 1 
                                            ? '${orderState.files.first.copies} Copies • ${orderState.files.first.colorMode} • ${orderState.files.first.binding}'
                                            : 'Multiple Files Configurations',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
                        Text(
                          'Select Payment Method',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          SizedBox(width: 8),
                          Text(
                            'Secure encrypted payment',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
                              gradient: LinearGradient(
                                colors: [Color(0xFF3BAFF2), Color(0xFF7000FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isProcessing 
                                ? SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2),
                                  )
                                : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Pay ₹${orderState.amountTotal.toStringAsFixed(2)} Now',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface),
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
          color: isSelected ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3BAFF2).withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFF3BAFF2)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? const Color(0xFF3BAFF2) : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<bool?> _promptPhoneAuthSheet(BuildContext context) async {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    bool otpSent = false;
    bool isSubmitting = false;
    String? localError;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: const Color(0xFF0F1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_android, color: Color(0xFF22D3EE), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          otpSent ? 'Verify OTP' : 'Quick Mobile Login',
                          style: const TextStyle(color: Color(0xFF8AEBFF), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.of(dialogCtx).pop(null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  otpSent
                      ? 'Enter the 6-digit code sent to +91 ${phoneController.text.trim()}'
                      : 'Enter your mobile number to link this print order to your account and track its live printing status.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                if (!otpSent) ...[
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1),
                    decoration: InputDecoration(
                      prefixText: '+91 ',
                      prefixStyle: const TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, fontSize: 16),
                      hintText: '98765 43210',
                      hintStyle: const TextStyle(color: Colors.white30),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22D3EE))),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '------',
                      hintStyle: const TextStyle(color: Colors.white30),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22D3EE))),
                    ),
                  ),
                ],
                if (localError != null) ...[
                  const SizedBox(height: 12),
                  Text(localError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22D3EE),
                      foregroundColor: const Color(0xFF00363E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() {
                              isSubmitting = true;
                              localError = null;
                            });

                            if (!otpSent) {
                              final phone = phoneController.text.trim();
                              if (phone.length != 10) {
                                setModalState(() {
                                  isSubmitting = false;
                                  localError = 'Please enter a valid 10-digit mobile number';
                                });
                                return;
                              }

                              final success = await ref.read(authProvider.notifier).sendPhoneOtp(phone);
                              if (context.mounted) {
                                setModalState(() {
                                  isSubmitting = false;
                                  if (success) {
                                    otpSent = true;
                                  } else {
                                    localError = ref.read(authProvider).error ?? 'Failed to send OTP';
                                  }
                                });
                              }
                            } else {
                              final otp = otpController.text.trim();
                              if (otp.length != 6) {
                                setModalState(() {
                                  isSubmitting = false;
                                  localError = 'Please enter 6-digit OTP';
                                });
                                return;
                              }

                              final success = await ref.read(authProvider.notifier).verifyPhoneOtpAndLogin(otp);
                              if (context.mounted) {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                                if (success) {
                                  Navigator.of(dialogCtx).pop(true);
                                } else {
                                  setModalState(() {
                                    localError = ref.read(authProvider).error ?? 'Invalid OTP code';
                                  });
                                }
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00363E)))
                        : Text(otpSent ? 'Verify & Continue' : 'Send Verification OTP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: const Text('Skip and continue as Guest', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

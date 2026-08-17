import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> manual;

  const ProductDetailScreen({super.key, required this.manual});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;
  late Razorpay _razorpay;
  bool _isProcessing = false;

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
      final api = ref.read(apiProvider);
      final res = await api.post('/product-orders', data: {
        'product_id': widget.manual['product_id'],
        'quantity': quantity,
        'amount_total': (double.parse(widget.manual['price'].toString()) * quantity).toStringAsFixed(2),
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      });

      if (res.statusCode == 201) {
        if (!mounted) return;
        context.pushReplacement('/post-order', extra: res.data['order']);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External wallet selected: ${response.walletName}')));
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    final amount = double.parse(widget.manual['price'].toString()) * quantity;

    try {
      final api = ref.read(apiProvider);
      
      // We will check if the user is authenticated. 
      // Based on that we call the correct endpoint. But for now we can just assume they are.
      // Wait, let's use the guest endpoint if auth might not be available, or just standard.
      // Assuming user is authenticated in this marketplace view:
      final createRes = await api.post('/payments/create', data: {
        'amount': amount,
      });
      
      final keyId = createRes.data['key_id'];
      final razorpayOrderId = createRes.data['razorpay_order_id'];

      var options = {
        'key': keyId,
        'amount': (amount * 100).toInt(),
        'name': 'PrintIt Marketplace',
        'description': 'Payment for ${widget.manual['title']}',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': '',
          'email': ''
        }
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error preparing payment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final manual = widget.manual;
    final stock = manual['stock_count'] as int;
    final maxQty = stock > 5 ? 5 : stock;
    final price = double.parse(manual['price'].toString());
    final isOutOfStock = stock <= 0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Details'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                image: manual['cover_photo_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(manual['cover_photo_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: manual['cover_photo_url'] == null
                ? const Icon(Icons.book, size: 80, color: Colors.grey)
                : null,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          manual['title'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹$price',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(manual['branch']), backgroundColor: Colors.blue.withValues(alpha: 0.2)),
                      Chip(label: Text(manual['course_type']), backgroundColor: Colors.purple.withValues(alpha: 0.2)),
                      if (manual['semester'] != null && manual['semester'].toString().isNotEmpty)
                        Chip(label: Text('${manual['semester']} Sem'), backgroundColor: Colors.orange.withValues(alpha: 0.2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Subject: ${manual['subject'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (manual['description'] != null && manual['description'].toString().isNotEmpty)
                    Text(
                      manual['description'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  const Divider(height: 48),
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(manual['shop_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(manual['shop_address'] ?? 'Address unavailable', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  if (isOutOfStock)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Center(
                        child: Text('Currently Out of Stock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                                ),
                                Text('$quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: quantity < maxQty ? () => setState(() => quantity++) : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Total: ₹${(price * quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isProcessing ? null : _processPayment,
                            child: _isProcessing 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Pay & Order Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

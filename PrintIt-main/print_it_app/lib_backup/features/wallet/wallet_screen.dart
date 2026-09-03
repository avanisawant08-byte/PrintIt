import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_provider.dart';
import 'wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  double _topupAmount = 100.0;

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

  Future<void> _startTopup(double amount) async {
    setState(() {
      _isProcessing = true;
      _topupAmount = amount;
    });

    try {
      final dio = ref.read(apiProvider);
      final createRes = await dio.post('/wallet/topup/create', data: {'amount': amount});

      if (createRes.statusCode != 201) throw Exception('Failed to create topup order');

      final orderId = createRes.data['razorpay_order_id'];
      final keyId = createRes.data['key_id'];

      if (!kIsWeb && Platform.isWindows) {
        // Mock success for Windows testing
        _handlePaymentSuccess(PaymentSuccessResponse.fromMap({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
          'razorpay_signature': 'mock_signature'
        }));
      } else {
        final authState = ref.read(authProvider);
        var options = {
          'key': keyId,
          'amount': (amount * 100).round(),
          'name': 'PrintIt Wallet',
          'description': 'Add Money to Wallet',
          'order_id': orderId,
          'prefill': {
            'contact': authState.user?['phone'] ?? '9876543210',
            'email': authState.user?['email'] ?? 'guest@printit.com'
          }
        };
        _razorpay.open(options);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Topup Failed: $e')));
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final dio = ref.read(apiProvider);
      final verifyRes = await dio.post('/wallet/topup/verify', data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'amount': _topupAmount,
      });

      if (verifyRes.statusCode == 200) {
        ref.invalidate(walletProvider);
        if (!mounted) return;
        context.push('/wallet-success?amount=${_topupAmount}');
      } else {
        throw Exception('Verification failed');
      }
    } catch (e) {
      if (!mounted) return;
      context.push('/wallet-failed?error=${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    context.push('/wallet-failed?error=${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
  }

  void _showTopupDialog() {
    final TextEditingController amountController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Add Money', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00DBE9)),
            onPressed: () {
              Navigator.pop(context);
              final amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt > 0) _startTopup(amt);
            },
            child: const Text('Proceed', style: TextStyle(color: Color(0xFF0B0B1E))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF111125).withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00DBE9)))
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(walletProvider),
                    child: walletAsync.when(
                      data: (data) => _buildWalletView(context, data),
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00DBE9))),
                      error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletView(BuildContext context, Map<String, dynamic> data) {
    final balance = data['balance'] ?? 0.0;
    final transactions = data['transactions'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(30),
            borderRadius: 20,
            child: Column(
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF00DBE9), fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showTopupDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00DBE9),
                      foregroundColor: const Color(0xFF0B0B1E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Recent Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No transactions yet', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isCredit = tx['type'] == 'refund' || tx['type'] == 'topup';
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                      child: Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isCredit ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      tx['type'].toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      tx['created_at'].toString().substring(0, 10),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: Text(
                      '${isCredit ? '+' : '-'}₹${tx['amount']}',
                      style: TextStyle(
                        color: isCredit ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

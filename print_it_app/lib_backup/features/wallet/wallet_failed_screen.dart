import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';

class WalletFailedScreen extends StatelessWidget {
  final String? errorMessage;
  const WalletFailedScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => context.go('/wallet'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Failed Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: const Icon(Icons.error_outline, color: Colors.white, size: 48),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Topup Failed',
                    style: TextStyle(
                      color: Color(0xFFE2E0FB),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage ?? 'We couldn\'t process your wallet topup. Please try again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB9CACB),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  const Spacer(),
                  
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {
                        // Pop back to the WalletScreen to retry
                        context.go('/wallet');
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00DBE9), Color(0xFF7000FF)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Retry Topup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3B494B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to Home', style: TextStyle(color: Color(0xFFB9CACB), fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

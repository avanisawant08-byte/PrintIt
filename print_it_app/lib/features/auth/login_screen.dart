import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/ambient_background.dart';
import 'auth_provider.dart';
import '../orders/order_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AmbientBackground(),
          Center(
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Print It',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liquid Glass Edition',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (authState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        authState.error!,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              final success = await ref.read(authProvider.notifier).login(
                                    emailController.text,
                                    passwordController.text,
                                  );
                              if (success && context.mounted) {
                                final lockedShopId = ref.read(orderProvider).shopId;
                                if (lockedShopId != null && lockedShopId.isNotEmpty) {
                                  context.go('/upload-document/$lockedShopId');
                                } else {
                                  context.go('/home');
                                }
                              }
                            },
                      child: authState.isLoading && !_isGoogleLoading
                          ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface)
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text("Don't have an account? Register", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isGoogleLoading = true;
                              });
                              final success = await ref.read(authProvider.notifier).loginWithGoogle();
                              if (context.mounted) {
                                setState(() {
                                  _isGoogleLoading = false;
                                });
                              }
                              if (success && context.mounted) {
                                final lockedShopId = ref.read(orderProvider).shopId;
                                if (lockedShopId != null && lockedShopId.isNotEmpty) {
                                  context.go('/upload-document/$lockedShopId');
                                } else {
                                  context.go('/home');
                                }
                              }
                            },
                      icon: _isGoogleLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          : Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                              height: 24,
                            ),
                      label: Text(
                        _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _showPhoneLoginDialog(context),
                      icon: const Icon(Icons.phone_android, color: Color(0xFF22D3EE), size: 22),
                      label: const Text(
                        'Continue with Phone Number',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8AEBFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  void _showPhoneLoginDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    bool otpSent = false;
    bool isSubmitting = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: const Color(0xFF0F1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF22D3EE), width: 1.5)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      otpSent ? 'Enter SMS OTP' : 'Phone Number Login',
                      style: const TextStyle(color: Color(0xFF8AEBFF), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  otpSent 
                    ? 'We have sent a 6-digit verification code to +91 ${phoneController.text.trim()}'
                    : 'Enter your 10-digit mobile number to receive a one-time OTP.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                                    localError = ref.read(authProvider).error ?? 'Failed to send OTP. Please check number.';
                                  }
                                });
                              }
                            } else {
                              final otp = otpController.text.trim();
                              if (otp.length != 6) {
                                setModalState(() {
                                  isSubmitting = false;
                                  localError = 'Please enter the 6-digit OTP';
                                });
                                return;
                              }

                              final success = await ref.read(authProvider.notifier).verifyPhoneOtpAndLogin(otp);
                              if (context.mounted) {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                                if (success) {
                                  Navigator.of(dialogCtx).pop();
                                  final lockedShopId = ref.read(orderProvider).shopId;
                                  if (lockedShopId != null && lockedShopId.isNotEmpty) {
                                    context.go('/upload-document/$lockedShopId');
                                  } else {
                                    context.go('/home');
                                  }
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
                        : Text(otpSent ? 'Verify & Login' : 'Send OTP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_provider.dart';
import '../wallet/wallet_provider.dart';
import '../orders/order_history_screen.dart';
import 'notification_settings_provider.dart';
import '../../core/api/api_client.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.print, color: const Color(0xFF00daf3)),
            const SizedBox(width: 8),
            const Text(
              'Print It',
              style: TextStyle(
                color: Color(0xFF00daf3),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark 
                ? Icons.light_mode 
                : Icons.dark_mode,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle(Theme.of(context).brightness);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: user == null
                ? _buildGuestProfile(context)
                : _buildUserProfile(context, ref, user),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person_outline, size: 50, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          ),
          const SizedBox(height: 24),
          Text('You are using Guest Mode', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Sign in to save your history and preferences.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00daf3),
              foregroundColor: const Color(0xFF0b1326),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Login / Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero Section
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00daf3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00daf3).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFF131b2e),
                        backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                        child: user['avatar_url'] == null 
                            ? const Icon(Icons.person, size: 44, color: Color(0xFF00daf3))
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/edit-profile'),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00daf3),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0b1326), width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 14, color: Color(0xFF00363d)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user['full_name'] ?? user['name'] ?? 'User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final email = user['email']?.toString() ?? '';
                    final phone = user['phone']?.toString() ?? '';
                    String displayContact = email;
                    if (email.contains('@phone.printit.in') || email.isEmpty) {
                      if (phone.isNotEmpty) {
                        final digits = phone.replaceAll(RegExp(r'\D'), '');
                        final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
                        displayContact = '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
                      } else {
                        displayContact = 'Customer Account';
                      }
                    }
                    return Text(
                      displayContact,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final ordersAsync = ref.watch(orderHistoryProvider);
                    final ordersCount = ordersAsync.value?.length ?? 0;
                    final walletAsync = ref.watch(walletProvider);
                    final walletBalance = walletAsync.value?['balance']?.toString() ?? '0.00';

                    return Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/orders'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$ordersCount',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00daf3),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'MY ORDERS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/wallet'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '₹$walletBalance',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00daf3),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'WALLET',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // App Settings
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'APP SETTINGS',
              style: TextStyle(
                color: Color(0xFF00daf3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          GlassContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildToggleTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Status updates & collection alerts',
                  value: ref.watch(notificationSettingsProvider),
                  onChanged: (val) {
                    ref.read(notificationSettingsProvider.notifier).toggle(val);
                  },
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                _buildNavigationTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Support & FAQ',
                  onTap: () => context.push('/help'),
                ),
                if (user['role'] == 'shopkeeper') ...[
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  _buildNavigationTile(
                    context,
                    icon: Icons.storefront,
                    title: 'Manage Shop Services',
                    onTap: () => context.push('/manage-services'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Legal & Policies Section
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'LEGAL & POLICIES',
              style: TextStyle(
                color: Color(0xFF00daf3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          GlassContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildNavigationTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/privacy'),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                _buildNavigationTile(
                  context,
                  icon: Icons.gavel_outlined,
                  title: 'Terms of Service',
                  onTap: () => context.push('/terms'),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                _buildNavigationTile(
                  context,
                  icon: Icons.currency_rupee,
                  title: 'Refund & Cancellation Policy',
                  onTap: () => context.push('/refund-policy'),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                _buildNavigationTile(
                  context,
                  icon: Icons.security_outlined,
                  title: 'Security Practices',
                  onTap: () => context.push('/security'),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                _buildNavigationTile(
                  context,
                  icon: Icons.accessibility_new_outlined,
                  title: 'Accessibility Statement',
                  onTap: () => context.push('/accessibility'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Wallet History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'WALLET HISTORY',
                  style: TextStyle(
                    color: Color(0xFF00daf3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/wallet'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00daf3),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Wallet', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          ref.watch(walletProvider).when(
            data: (data) {
              final transactions = data['transactions'] as List<dynamic>? ?? [];
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('No transactions yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                );
              }
              
              return Column(
                children: transactions.take(3).map((tx) {
                  final isCredit = tx['type'] == 'refund' || tx['type'] == 'topup';
                  String title = tx['type'].toString().toUpperCase();
                  if (tx['type'] == 'topup') title = 'Added Funds';
                  if (tx['type'] == 'payment') title = 'Payment';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildWalletHistoryCard(
                      context,
                      title: title,
                      date: tx['created_at'].toString().substring(0, 10),
                      amount: '${isCredit ? '+' : '-'}₹${tx['amount']}',
                      isCredit: isCredit,
                      icon: isCredit ? Icons.account_balance_wallet : Icons.receipt_long,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF00daf3)),
            )),
            error: (e, st) => Center(child: Text('Error loading wallet history', style: TextStyle(color: Colors.redAccent))),
          ),

          const SizedBox(height: 32),
          
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/home');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF5252), width: 1),
                foregroundColor: const Color(0xFFFF5252),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Danger Zone - Delete Account
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _confirmAccountDeletion(context, ref),
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 18),
              label: const Text(
                'Delete Account & Data',
                style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildToggleTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00daf3),
            activeTrackColor: const Color(0xFF00daf3).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHistoryCard(BuildContext context, {required String title, required String date, required String amount, required bool isCredit, required IconData icon}) {
    return GlassContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isCredit ? const Color(0xFF00daf3) : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit ? const Color(0xFF00C853) : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Account & Data?'),
        content: const Text(
          'This action is irreversible. Your profile, order records, and active credentials will be permanently erased from Print It.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(apiProvider);
        final res = await api.delete('/auth/account');
        if (context.mounted) {
          if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your account and data have been permanently deleted.')),
            );
            ref.read(authProvider.notifier).logout();
            context.go('/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.data?['message'] ?? 'Failed to delete account.')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }
}


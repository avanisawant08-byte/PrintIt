import 'package:flutter/material.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(24.0),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Print It Privacy Policy',
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Effective Date: September 2026',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLegalNotice(
                          context,
                          'Legal Notice: This policy details real technical data practices implemented in Print It. Legal counsel review is recommended before commercial deployment.',
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          context,
                          '1. Information We Collect',
                          '• Account Information: Name, email address, and encrypted authentication credentials.\n'
                          '• Document Files: User-uploaded PDF, image, and document files submitted for print jobs.\n'
                          '• Order & Transaction Metadata: Print specifications (color, paper size, orientation, page range, copies, binding), pickup method (Express / Scheduled), payment amount, transaction IDs, and order status.\n'
                          '• Device & Diagnostic Data: Browser/app type, network IP address, and technical logs for error prevention.',
                        ),
                        _buildSection(
                          context,
                          '2. How We Use Information',
                          'We use the collected information strictly for:\n'
                          '• Rendering document previews and calculating exact print pricing.\n'
                          '• Dispatching print orders to the customer-selected print shop.\n'
                          '• Processing payments and managing your in-app wallet balance.\n'
                          '• Sending real-time pickup ready alerts and status notifications.\n'
                          '• Customer support and ticket resolution.',
                        ),
                        _buildSection(
                          context,
                          '3. Document Retention & Auto-Purge',
                          'To protect your privacy and document confidentiality, all uploaded print files stored in our secure cloud storage are automatically and permanently purged within 48 hours of order completion or cancellation via our automated cleanup scheduler.',
                        ),
                        _buildSection(
                          context,
                          '4. Third-Party Service Providers',
                          'We integrate only verified third-party infrastructure for core operations:\n'
                          '• Razorpay: Secure online payment processing (UPI, cards, net banking). We never store payment card or banking credentials on our servers.\n'
                          '• Google Cloud & Firebase: Cloud storage and real-time push notifications.\n'
                          '• Partner Print Shops: Document data is shared only with the specific vendor shop chosen by you for fulfillment.',
                        ),
                        _buildSection(
                          context,
                          '5. User Rights & Account Deletion',
                          'You have the right to access your profile data, review order history, and delete your account at any time. Account deletion permanently wipes your profile, contact data, and active session tokens from our database via the Profile settings screen.',
                        ),
                        _buildSection(
                          context,
                          '6. Contact & Privacy Inquiries',
                          'For privacy-related questions or data deletion requests, contact us at:\nEmail: support@printit.com',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNotice(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.amber, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

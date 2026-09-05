import 'package:flutter/material.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Refund & Cancellation', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            Icon(Icons.currency_rupee, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Refund & Cancellation Policy',
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
                        _buildSection(
                          context,
                          '1. Order Cancellation Window',
                          '• Queued Orders: You may cancel your order at any time while its status is "Queued" (before the print shop begins processing). Upon cancellation, 100% of the order total is instantly credited to your Print It wallet.\n'
                          '• Processing & Ready Orders: Once the print vendor starts printing (status "Processing" or "Ready"), ink and paper materials are irreversibly consumed and automated cancellation is locked.',
                        ),
                        _buildSection(
                          context,
                          '2. Failed Prints & Vendor Rejections',
                          'If a partner print shop is unable to fulfill an order due to printer maintenance, technical errors, paper stock unavailability, or unreadable files, the vendor marks the job as cancelled/rejected, and 100% of the funds are automatically refunded to your in-app wallet balance.',
                        ),
                        _buildSection(
                          context,
                          '3. Physical Pickup Inspection & Quality Issues',
                          'Customers must inspect printed documents at the partner shop during physical pickup:\n'
                          '• If print defects (e.g. illegible streaks, smudged ink, missing pages, or wrong paper size) differ from your order specifications, notify the shopkeeper immediately at the counter for an on-the-spot reprint.\n'
                          '• If an agreeable reprint is not possible, raise an in-app support ticket via Help & Support within 24 hours of pickup.',
                        ),
                        _buildSection(
                          context,
                          '4. Refund Processing Method',
                          '• All validated refunds are credited directly to your Print It in-app Wallet instantly.\n'
                          '• Wallet funds do not expire and can be applied toward any future print order or stationery purchase on the platform.',
                        ),
                        _buildSection(
                          context,
                          '5. Support & Disputes',
                          'For questions or dispute assistance, visit the Help & Support section in the app or reach us at support@printit.com.',
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
}

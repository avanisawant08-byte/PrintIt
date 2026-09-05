import 'package:flutter/material.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            Icon(Icons.description_outlined, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Terms of Service',
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
                          'Legal Notice: These terms govern usage of the Print It platform. Subject to final legal review prior to production launch.',
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          context,
                          '1. Service Overview',
                          'Print It is a marketplace and print orchestration platform connecting customers with partner print shops. Customers upload files, select print specifications, pay online or via wallet, and physically pick up their completed orders at their chosen store location.',
                        ),
                        _buildSection(
                          context,
                          '2. User Responsibilities & Acceptable Content',
                          'By uploading documents to Print It, you affirm that:\n'
                          '• You hold the copyright, license, or legal authorization to reproduce the materials.\n'
                          '• Your documents do not contain unlawful, harassing, defamatory, fraudulent, or malicious content.\n'
                          '• You will not use the platform to transmit malware, automated scraping bots, or disrupt platform infrastructure.',
                        ),
                        _buildSection(
                          context,
                          '3. Physical Pickup & Verification',
                          '• All print orders are fulfilled strictly via in-store physical pickup at the selected partner shop.\n'
                          '• Orders must be claimed using the unique digital Order ID or Pickup QR code shown in your app.\n'
                          '• Orders not picked up within 7 calendar days may be safely recycled by the shopkeeper without entitlement to refund.',
                        ),
                        _buildSection(
                          context,
                          '4. Payments & In-App Wallet',
                          '• Pricing is computed based on page count, color configuration, paper type, and binding options.\n'
                          '• Payments are securely processed via Razorpay or debited from your Print It wallet balance.\n'
                          '• Wallet top-ups are non-transferable and can only be used for platform services.',
                        ),
                        _buildSection(
                          context,
                          '5. Limitation of Liability',
                          'Print It provides the technology platform connecting customers with independent print vendors. While we enforce strict quality standards, physical print output, equipment calibration, and finishing are performed by independent shops. In any event, our total aggregate liability is limited to the amount paid for the specific order.',
                        ),
                        _buildSection(
                          context,
                          '6. Contact Information',
                          'For any inquiries regarding these terms, contact support@printit.com.',
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

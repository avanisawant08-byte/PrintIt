import 'package:flutter/material.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class SecurityPolicyScreen extends StatelessWidget {
  const SecurityPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Security & Disclosure', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security Practices & Disclosure',
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
                          '1. Data Transmission & Cryptography',
                          '• All communications between the mobile application, web portals, and backend APIs are strictly encrypted using TLS 1.2+.\n'
                          '• Passwords are cryptographically salted and hashed using bcrypt on our backend before storage.\n'
                          '• API communications use JSON Web Tokens (JWT) with server-side validation and expiration.',
                        ),
                        _buildSection(
                          context,
                          '2. Payment Security',
                          '• Payment transactions are handled directly through Razorpay’s PCI-DSS compliant infrastructure.\n'
                          '• Print It does not store or process sensitive credit card numbers, CVVs, or net-banking credentials on our application servers.',
                        ),
                        _buildSection(
                          context,
                          '3. Document Confidentiality & Ephemeral Retention',
                          '• Uploaded customer print documents are stored in secure cloud buckets accessible only through authenticated pre-signed links.\n'
                          '• An automated scheduled background job permanently purges completed and cancelled job documents within 48 hours.',
                        ),
                        _buildSection(
                          context,
                          '4. Responsible Vulnerability Disclosure',
                          'We welcome reports from independent security researchers. If you identify a potential security vulnerability in Print It:\n'
                          '• Email: security@printit.com\n'
                          '• Include detailed steps to reproduce, affected endpoints, and proof-of-concept.\n'
                          '• Allow reasonable time for remediation before any public disclosure.\n'
                          '• Please refrain from accessing user data, disrupting production operations, or performing volumetric denial-of-service tests.',
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

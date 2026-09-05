import 'package:flutter/material.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Accessibility', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            Icon(Icons.accessibility_new, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Accessibility Statement',
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
                          '1. Our Commitment',
                          'Print It is dedicated to providing an accessible, usable, and inclusive experience for all users regardless of ability or assistive technologies used. We strive to continually enhance the user experience and apply relevant accessibility guidelines.',
                        ),
                        _buildSection(
                          context,
                          '2. Implemented Measures',
                          '• High contrast typography with support for both dark and light modes.\n'
                          '• Semantic touch targets exceeding 48x48dp for comfortable one-handed navigation.\n'
                          '• Dynamic text scaling support honoring system-level accessibility settings.\n'
                          '• Screen-reader friendly semantic labels across primary order and checkout flows.\n'
                          '• Clear non-color visual indicators for errors, validation warnings, and order status changes.',
                        ),
                        _buildSection(
                          context,
                          '3. Conformance Status & Ongoing Improvements',
                          'We are continuously working toward alignment with Web Content Accessibility Guidelines (WCAG) 2.1 Level AA standards. While our core user flows are engineered for accessibility, formal third-party certification is in progress.',
                        ),
                        _buildSection(
                          context,
                          '4. Feedback & Assistance',
                          'If you experience any difficulty accessing content or utilizing features on Print It, please let us know:\nEmail: accessibility@printit.com\nWe take your feedback seriously and strive to respond promptly.',
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

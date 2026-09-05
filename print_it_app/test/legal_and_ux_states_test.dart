import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:print_it_app/features/legal/privacy_policy_screen.dart';
import 'package:print_it_app/features/legal/terms_screen.dart';
import 'package:print_it_app/features/legal/refund_policy_screen.dart';
import 'package:print_it_app/features/legal/security_policy_screen.dart';
import 'package:print_it_app/features/legal/accessibility_screen.dart';
import 'package:print_it_app/features/navigation/not_found_screen.dart';
import 'package:print_it_app/shared/widgets/empty_state_widget.dart';
import 'package:print_it_app/shared/widgets/error_state_widget.dart';
import 'package:print_it_app/shared/widgets/offline_banner_widget.dart';

void main() {
  testWidgets('Privacy Policy screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyPolicyScreen(),
      ),
    );

    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('1. Information We Collect'), findsOneWidget);
    expect(find.text('3. Document Retention & Auto-Purge'), findsOneWidget);
  });

  testWidgets('Terms of Service screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TermsScreen(),
      ),
    );

    expect(find.text('Terms of Service'), findsWidgets);
    expect(find.text('1. Service Overview'), findsOneWidget);
    expect(find.text('3. Physical Pickup & Verification'), findsOneWidget);
  });

  testWidgets('Refund Policy screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RefundPolicyScreen(),
      ),
    );

    expect(find.text('Refund & Cancellation'), findsWidgets);
    expect(find.text('1. Order Cancellation Window'), findsOneWidget);
    expect(find.text('4. Refund Processing Method'), findsOneWidget);
  });

  testWidgets('Security Policy screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SecurityPolicyScreen(),
      ),
    );

    expect(find.text('Security & Disclosure'), findsWidgets);
    expect(find.text('1. Data Transmission & Cryptography'), findsOneWidget);
    expect(find.text('4. Responsible Vulnerability Disclosure'), findsOneWidget);
  });

  testWidgets('Accessibility Statement renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccessibilityScreen(),
      ),
    );

    expect(find.text('Accessibility'), findsWidgets);
    expect(find.text('1. Our Commitment'), findsOneWidget);
  });

  testWidgets('NotFoundScreen renders 404 message and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotFoundScreen(uri: '/invalid-test-route'),
      ),
    );

    expect(find.text('404 - Page Not Found'), findsOneWidget);
    expect(find.textContaining('/invalid-test-route'), findsOneWidget);
    expect(find.text('Return Home'), findsOneWidget);
  });

  testWidgets('EmptyStateWidget renders message and handles action tap', (WidgetTester tester) async {
    bool actionTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            title: 'No Documents',
            description: 'You have not uploaded any documents yet.',
            actionLabel: 'Upload Now',
            onAction: () {
              actionTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('No Documents'), findsOneWidget);
    expect(find.text('You have not uploaded any documents yet.'), findsOneWidget);
    expect(find.text('Upload Now'), findsOneWidget);

    await tester.tap(find.text('Upload Now'));
    await tester.pump();
    expect(actionTapped, isTrue);
  });

  testWidgets('ErrorStateWidget renders error and triggers retry', (WidgetTester tester) async {
    bool retryTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorStateWidget(
            title: 'Connection Error',
            message: 'Unable to reach the server.',
            retryLabel: 'Retry Request',
            onRetry: () {
              retryTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Connection Error'), findsOneWidget);
    expect(find.text('Unable to reach the server.'), findsOneWidget);

    await tester.tap(find.text('Retry Request'));
    await tester.pump();
    expect(retryTapped, isTrue);
  });

  testWidgets('OfflineBannerWidget displays when offline is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflineBannerWidget(isOffline: true),
        ),
      ),
    );

    expect(find.textContaining('You are currently offline'), findsOneWidget);
  });
}

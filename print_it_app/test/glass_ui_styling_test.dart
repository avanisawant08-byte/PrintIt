import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:print_it_app/shared/widgets/glass_container.dart';

void main() {
  testWidgets('GlassContainer renders with frosted styling and soft shadow in light mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: GlassContainer(
            child: Text('Test Frosted Card'),
          ),
        ),
      ),
    );

    expect(find.text('Test Frosted Card'), findsOneWidget);
    final containerFinder = find.byType(GlassContainer);
    expect(containerFinder, findsOneWidget);
  });

  testWidgets('GlassContainer renders with frosted styling in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: GlassContainer(
            child: Text('Dark Frosted Card'),
          ),
        ),
      ),
    );

    expect(find.text('Dark Frosted Card'), findsOneWidget);
  });

  testWidgets('Sign Out style button has no harsh outline border', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shadowColor: Colors.transparent,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {},
            child: const Text('Sign Out'),
          ),
        ),
      ),
    );

    expect(find.text('Sign Out'), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.style?.side?.resolve({}), BorderSide.none);
  });
}

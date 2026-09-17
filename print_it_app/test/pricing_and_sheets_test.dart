import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:print_it_app/features/orders/order_provider.dart';

void main() {
  group('Pricing and Sheet Calculation Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('4-page document: single sided vs back-to-back calculation', () {
      final notifier = container.read(orderProvider.notifier);
      notifier.setPrices(2.0, 10.0, [
        {'color': 'bw', 'size': 'A4', 'sides': 'single', 'price_per_page': 2.0},
        {'color': 'bw', 'size': 'A4', 'sides': 'double', 'price_per_page': 3.0},
      ]);

      final dummyFile = PlatformFile(name: 'test.pdf', size: 100);
      notifier.setFiles([
        FileEntry(file: dummyFile, pages: 4, colorMode: 'B&W', sides: 'single', copies: 1),
      ]);

      // Single sided: 4 sheets, 4 pages, subtotal 4 * 2.0 = 8.0
      var state = container.read(orderProvider);
      expect(state.totalSheets, 4);
      expect(state.totalPagesCount, 4);
      expect(state.subtotal, 8.0);

      // Switch to Back-to-Back
      notifier.setSides('double');
      state = container.read(orderProvider);
      // Double sided: 2 sheets, 4 pages, subtotal 2 * 3.0 = 6.0
      expect(state.totalSheets, 2);
      expect(state.totalPagesCount, 4);
      expect(state.subtotal, 6.0);
    });

    test('3-page document: single sided vs back-to-back calculation', () {
      final notifier = container.read(orderProvider.notifier);
      notifier.setPrices(2.0, 10.0, [
        {'color': 'bw', 'size': 'A4', 'sides': 'single', 'price_per_page': 2.0},
        {'color': 'bw', 'size': 'A4', 'sides': 'double', 'price_per_page': 3.0},
      ]);

      final dummyFile = PlatformFile(name: 'test.pdf', size: 100);
      notifier.setFiles([
        FileEntry(file: dummyFile, pages: 3, colorMode: 'B&W', sides: 'single', copies: 1),
      ]);

      // Single sided: 3 sheets, 3 pages, subtotal 3 * 2.0 = 6.0
      var state = container.read(orderProvider);
      expect(state.totalSheets, 3);
      expect(state.totalPagesCount, 3);
      expect(state.subtotal, 6.0);

      // Switch to Back-to-Back: 1 double sheet (3.0) + 1 single sheet (2.0) = 5.0
      notifier.setSides('double');
      state = container.read(orderProvider);
      expect(state.totalSheets, 2);
      expect(state.totalPagesCount, 3);
      expect(state.subtotal, 5.0);
    });

    test('1-page document: single sided vs back-to-back calculation', () {
      final notifier = container.read(orderProvider.notifier);
      notifier.setPrices(2.0, 10.0, [
        {'color': 'bw', 'size': 'A4', 'sides': 'single', 'price_per_page': 2.0},
        {'color': 'bw', 'size': 'A4', 'sides': 'double', 'price_per_page': 3.0},
      ]);

      final dummyFile = PlatformFile(name: 'test.pdf', size: 100);
      notifier.setFiles([
        FileEntry(file: dummyFile, pages: 1, colorMode: 'B&W', sides: 'single', copies: 1),
      ]);

      var state = container.read(orderProvider);
      expect(state.totalSheets, 1);
      expect(state.totalPagesCount, 1);
      expect(state.subtotal, 2.0);

      // Back-to-Back on 1 page remains 1 sheet and 2.0
      notifier.setSides('double');
      state = container.read(orderProvider);
      expect(state.totalSheets, 1);
      expect(state.totalPagesCount, 1);
      expect(state.subtotal, 2.0);
    });

    test('Fallback pricing when no double-sided rule is specified (1.5x fallback)', () {
      final notifier = container.read(orderProvider.notifier);
      notifier.setPrices(2.0, 10.0, []); // Empty rules

      final dummyFile = PlatformFile(name: 'test.pdf', size: 100);
      notifier.setFiles([
        FileEntry(file: dummyFile, pages: 4, colorMode: 'B&W', sides: 'single', copies: 1),
      ]);

      // Single sided: 4 * 2.0 = 8.0
      var state = container.read(orderProvider);
      expect(state.totalSheets, 4);
      expect(state.subtotal, 8.0);

      // Double sided: 2 sheets * (2.0 * 1.5) = 2 * 3.0 = 6.0
      notifier.setSides('double');
      state = container.read(orderProvider);
      expect(state.totalSheets, 2);
      expect(state.subtotal, 6.0);
    });
  });
}

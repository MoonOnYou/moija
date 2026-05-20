import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/calendar_grid.dart';

void main() {
  group('buildMonthGrid', () {
    final grid = buildMonthGrid(DateTime(2026, 5, 1));

    test('returns 42 days', () {
      expect(grid, hasLength(42));
    });

    test('starts on the Sunday on/before the 1st', () {
      // 2026-05-01 is Friday; the grid starts on 2026-04-26 (Sunday).
      expect(grid.first, DateTime(2026, 4, 26));
    });

    test('contains the 1st of the focused month', () {
      expect(grid.contains(DateTime(2026, 5, 1)), isTrue);
    });

    test('last cell is 41 days after the first', () {
      expect(grid.last, DateTime(2026, 6, 6));
    });
  });
}

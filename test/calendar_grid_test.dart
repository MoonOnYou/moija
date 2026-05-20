import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/calendar_grid.dart';

void main() {
  group('weekStartOf', () {
    test('returns the Sunday of that week', () {
      // 2026-05-16 is Saturday → Sunday is 2026-05-10.
      expect(weekStartOf(DateTime(2026, 5, 16)), DateTime(2026, 5, 10));
    });
    test('a Sunday returns itself', () {
      expect(weekStartOf(DateTime(2026, 5, 10)), DateTime(2026, 5, 10));
    });
  });

  group('twoWeekGridFrom', () {
    final grid = twoWeekGridFrom(DateTime(2026, 5, 10));
    test('returns 14 consecutive days', () {
      expect(grid, hasLength(14));
      expect(grid.first, DateTime(2026, 5, 10));
      expect(grid.last, DateTime(2026, 5, 23));
    });
  });

  group('buildTwoWeekGrid', () {
    final grid = buildTwoWeekGrid(DateTime(2026, 5, 16));
    test('starts on the Sunday of today\'s week', () {
      expect(grid.first, DateTime(2026, 5, 10));
    });
    test('today is in the first row', () {
      expect(grid.sublist(0, 7).contains(DateTime(2026, 5, 16)), isTrue);
    });
    test('has 14 days', () {
      expect(grid, hasLength(14));
    });
  });

  group('isSameDay', () {
    test('ignores time component', () {
      expect(
        isSameDay(DateTime(2026, 5, 16, 9), DateTime(2026, 5, 16, 21)),
        isTrue,
      );
      expect(isSameDay(DateTime(2026, 5, 16), DateTime(2026, 5, 17)), isFalse);
    });
  });

  group('windowFollowing', () {
    // 초기 창: 2026-05-10(일) ~ 2026-05-23(토)
    final start = DateTime(2026, 5, 10);

    test('keeps the window when the day is inside it', () {
      expect(windowFollowing(start, DateTime(2026, 5, 16)), start);
      expect(windowFollowing(start, DateTime(2026, 5, 23)), start);
    });

    test('shifts forward by a week when the day is past the end', () {
      final w = windowFollowing(start, DateTime(2026, 5, 24));
      expect(w, DateTime(2026, 5, 17));
      expect(w.weekday, DateTime.sunday);
    });

    test('shifts backward by a week when the day is before the start', () {
      final w = windowFollowing(start, DateTime(2026, 5, 9));
      expect(w, DateTime(2026, 5, 3));
      expect(w.weekday, DateTime.sunday);
    });

    test('shifts multiple weeks when the day is far outside', () {
      final w = windowFollowing(start, DateTime(2026, 6, 7));
      expect(w, DateTime(2026, 5, 31));
    });
  });
}

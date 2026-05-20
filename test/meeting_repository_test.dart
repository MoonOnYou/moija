import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';

void main() {
  final repo = MeetingRepository();

  test('meetingsOn returns the day sorted by start time', () {
    final may20 = repo.meetingsOn(DateTime(2026, 5, 20));
    final times = may20.map((m) => m.startTime).toList();
    final sorted = [...times]..sort();
    expect(times, sorted);
    expect(may20.length, greaterThan(1));
  });

  test('meetingsOn 5/19 has 2 meetings, earliest first', () {
    final may19 = repo.meetingsOn(DateTime(2026, 5, 19));
    expect(may19, hasLength(2));
    expect(may19.first.title, '코노 1시간'); // 19:00 < 20:00
  });

  test('meetingsOn returns empty list for a day with no meetings', () {
    expect(repo.meetingsOn(DateTime(2026, 5, 11)), isEmpty);
  });
}

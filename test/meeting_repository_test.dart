import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';

void main() {
  final repo = MeetingRepository();

  test('meetingsOn returns meetings for that day only', () {
    final may19 = repo.meetingsOn(DateTime(2026, 5, 19));
    expect(may19, hasLength(2));
    expect(may19.first.title, '방탈출 호러 테마 같이!');
  });

  test('meetingsOn returns empty list for a day with no meetings', () {
    expect(repo.meetingsOn(DateTime(2026, 5, 11)), isEmpty);
  });
}

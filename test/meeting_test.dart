import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

void main() {
  test('spotsLeft = max - current', () {
    final m = Meeting(
      id: '1',
      title: '방탈출 호러 테마 같이!',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: '강남 비밀의방',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 2,
      maxMembers: 4,
    );
    expect(m.spotsLeft, 2);
    expect(m.locationId, 'seoul-line2');
  });
}

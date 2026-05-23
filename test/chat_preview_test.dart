import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/chat/chat_preview.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

Meeting _m(String id, DateTime start) => Meeting(
      id: id,
      title: 't',
      category: MeetingCategory.cafe,
      startTime: start,
      location: 'x',
      region: 'x',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('meetingPhase', () {
    final start = DateTime(2026, 5, 23, 19, 0);
    final m = _m('a', start);

    test('시작 전이면 upcoming', () {
      expect(meetingPhase(m, DateTime(2026, 5, 23, 12, 0)),
          MeetingPhase.upcoming);
    });
    test('시작~+3시간이면 ongoing', () {
      expect(meetingPhase(m, start), MeetingPhase.ongoing);
      expect(meetingPhase(m, start.add(const Duration(hours: 2, minutes: 59))),
          MeetingPhase.ongoing);
    });
    test('시작+3시간 이후는 ended', () {
      expect(meetingPhase(m, start.add(const Duration(hours: 3))),
          MeetingPhase.ended);
    });
  });

  test('chatStillAlive: 시작 후 51시간까지 유지', () {
    final start = DateTime(2026, 5, 20, 19, 0);
    final m = _m('a', start);
    expect(chatStillAlive(m, start.add(const Duration(hours: 50))), isTrue);
    expect(chatStillAlive(m, start.add(const Duration(hours: 51))), isFalse);
  });

  test('upcomingLabel: 같은 날은 D-Day, 다음 날부터 D-N', () {
    final start = DateTime(2026, 5, 25, 19, 0);
    final m = _m('a', start);
    expect(upcomingLabel(m, DateTime(2026, 5, 25, 9, 0)), 'D-Day');
    expect(upcomingLabel(m, DateTime(2026, 5, 24, 23, 0)), 'D-1');
    expect(upcomingLabel(m, DateTime(2026, 5, 18, 9, 0)), 'D-7');
  });

  test('ongoingLabel: 모임 시작 시각', () {
    final m = _m('a', DateTime(2026, 5, 23, 19, 30));
    expect(ongoingLabel(m), '오후 7:30');
  });

  test('endedLabel: 남은 시간(시/일/분)', () {
    final start = DateTime(2026, 5, 20, 19, 0);
    final m = _m('a', start);
    // 시작 +3h부터 채팅 만료까지 48h. 시작 +5h 시점 → 채팅 만료까지 46h → 1일 남음
    expect(endedLabel(m, start.add(const Duration(hours: 5))), '1일 남음');
    // 시작 +49h → 만료까지 2h
    expect(endedLabel(m, start.add(const Duration(hours: 49))), '2시간 남음');
    // 시작 +50h 50min → 만료까지 10분
    expect(
        endedLabel(m, start.add(const Duration(hours: 50, minutes: 50))),
        '10분 남음');
  });

  test('ChatPreview.forMeeting: 같은 id는 같은 미리보기를 만든다', () {
    final a1 = ChatPreview.forMeeting(_m('id-a', DateTime(2026, 5, 23)));
    final a2 = ChatPreview.forMeeting(_m('id-a', DateTime(2026, 5, 23)));
    expect(a1.lastSender, a2.lastSender);
    expect(a1.lastMessage, a2.lastMessage);
    expect(a1.unreadCount, a2.unreadCount);
  });
}

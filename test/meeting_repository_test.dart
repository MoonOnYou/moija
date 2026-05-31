import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

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

  test('participantsOf returns currentMembers participants, deterministically',
      () {
    final t1 = repo.allMeetings.firstWhere((m) => m.id == 't1'); // cur 4
    final a = repo.participantsOf(t1);
    final b = repo.participantsOf(t1);
    expect(a.length, 4);
    expect(a.map((m) => m.nickname).toList(),
        b.map((m) => m.nickname).toList());
  });

  test('repository meetings get a derived cost and description', () {
    final t1 = repo.allMeetings.firstWhere((m) => m.id == 't1');
    expect(t1.description, isNotEmpty);
    expect(t1.nearestStation, isNotEmpty);
  });

  test('replaceBrowse: 시드 브라우즈 모임을 API 모임으로 교체한다', () {
    final r = MeetingRepository();
    // 교체 전: 5/20에 시드 모임이 여러 개 있다.
    expect(r.meetingsOn(DateTime(2026, 5, 20)).length, greaterThan(1));

    r.replaceBrowse([
      Meeting(
        id: 'api-1',
        title: 'API 모임',
        category: MeetingCategory.cafe,
        startTime: DateTime(2026, 5, 20, 15, 0),
        location: '서면',
        region: '서면',
        locationId: 'busan-line2',
        currentMembers: 2,
        maxMembers: 4,
      ),
    ]);

    final may20 = r.meetingsOn(DateTime(2026, 5, 20));
    expect(may20, hasLength(1));
    expect(may20.first.id, 'api-1');
    // 기존 시드 모임 id는 사라진다.
    expect(r.allMeetings.any((m) => m.id == 'c1'), isFalse);
  });

  test('replaceBrowse: 내 모임(joined/hosted/pending)은 보존된다', () {
    final r = MeetingRepository(baseTime: DateTime(2026, 5, 31, 12));
    final myIds = {...r.myJoinedIds, ...r.myPendingIds};
    expect(myIds, isNotEmpty);

    r.replaceBrowse(const []);

    // 내 모임 객체는 allMeetings 에 그대로 남아 채팅이 찾을 수 있어야 한다.
    for (final id in myIds) {
      expect(r.allMeetings.any((m) => m.id == id), isTrue,
          reason: '내 모임 $id 이 보존돼야 함');
    }
  });

  test('add 한 모임이 meetingsOn / allMeetings 에 반영된다', () {
    final r = MeetingRepository();
    final before = r.meetingsOn(DateTime(2026, 7, 1)).length;
    r.add(Meeting(
      id: 'new-1',
      title: '새 모임',
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 7, 1, 18, 0),
      location: '강남역',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    ));
    expect(r.meetingsOn(DateTime(2026, 7, 1)).length, before + 1);
    expect(r.allMeetings.any((m) => m.id == 'new-1'), isTrue);
  });
}

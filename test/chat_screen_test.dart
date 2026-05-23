import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/chat/chat_preview.dart';
import 'package:moija/features/chat/chat_screen.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

/// 시드 데이터 영향 없이 정해진 목록만 노출하는 저장소.
class _TestRepo extends MeetingRepository {
  _TestRepo(this._list);
  final List<Meeting> _list;

  @override
  List<Meeting> get allMeetings => List.unmodifiable(_list);

  @override
  void add(Meeting m) => _list.add(m);

  @override
  List<Meeting> meetingsOn(DateTime day) => _list
      .where((m) =>
          m.startTime.year == day.year &&
          m.startTime.month == day.month &&
          m.startTime.day == day.day)
      .toList();
}

Meeting _m(String id, String title, DateTime start) => Meeting(
      id: id,
      title: title,
      category: MeetingCategory.cafe,
      startTime: start,
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('전체 탭은 다가오는·진행중·종료된 섹션과 라벨을 보여준다', (tester) async {
    final now = DateTime(2026, 5, 23, 12, 0);
    final repo = _TestRepo([
      _m('upcoming-1', '미래 모임', now.add(const Duration(days: 2, hours: 7))),
      _m('ongoing-1', '진행중 모임', now.subtract(const Duration(hours: 1))),
      _m('ended-1', '끝난 모임', now.subtract(const Duration(hours: 10))),
      // 채팅 만료(시작 +51h 이상): 노출되지 않아야 한다.
      _m('expired-1', '만료된 채팅',
          now.subtract(const Duration(hours: 60))),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    // 섹션 헤더와 모임 제목.
    expect(find.text('다가오는 모임'), findsOneWidget);
    expect(find.text('진행중인 모임'), findsOneWidget);
    expect(find.text('종료된 모임'), findsOneWidget);
    expect(find.text('미래 모임'), findsOneWidget);
    expect(find.text('진행중 모임'), findsOneWidget);
    expect(find.text('끝난 모임'), findsOneWidget);

    // 만료된 채팅은 빠진다.
    expect(find.text('만료된 채팅'), findsNothing);

    // 시간 라벨: 다가오는(D-N), 진행중(시작 시각), 종료된(남은 시간).
    expect(find.text('D-2'), findsOneWidget);
    expect(find.text('오전 11:00'), findsOneWidget);
    expect(find.textContaining('남음'), findsOneWidget);
  });

  testWidgets('안읽음 탭은 unread>0 모임만 보여준다', (tester) async {
    final now = DateTime(2026, 5, 23, 12, 0);

    // ChatPreview는 id.hashCode % 5 에 따라 unread를 결정한다.
    // 결정적이라 id별로 unread 여부를 미리 알 수 있어, 두 그룹으로 나눠 시드한다.
    Meeting future(String id) => _m(id, '미래 $id', now.add(const Duration(days: 1)));

    final candidates = [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
    ].map(future).toList();
    final withUnread =
        candidates.where((m) => ChatPreview.forMeeting(m).unreadCount > 0).toList();
    final noUnread =
        candidates.where((m) => ChatPreview.forMeeting(m).unreadCount == 0).toList();
    // 두 그룹이 모두 비어 있지 않아야 의미 있는 테스트가 된다.
    expect(withUnread, isNotEmpty);
    expect(noUnread, isNotEmpty);

    final repo = _TestRepo(candidates);
    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    // 안읽음 탭으로 이동.
    await tester.tap(find.text('안읽음'));
    await tester.pumpAndSettle();

    for (final m in withUnread) {
      expect(find.text(m.title), findsOneWidget, reason: '${m.id} 노출');
    }
    for (final m in noUnread) {
      expect(find.text(m.title), findsNothing, reason: '${m.id} 미노출');
    }
  });

  testWidgets('안읽음 탭에 미읽음 합계 배지가 표시된다', (tester) async {
    final now = DateTime(2026, 5, 23, 12, 0);

    // ChatPreview.forMeeting는 id.hashCode % 5 로 unread를 결정한다.
    // 모두 unread>0인 id만 모아 합계가 노출되는지 확인한다.
    Meeting future(String id) => _m(id, '미래 $id', now.add(const Duration(days: 1)));
    final candidates = [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
    ].map(future).toList();
    final withUnread =
        candidates.where((m) => ChatPreview.forMeeting(m).unreadCount > 0).toList();
    final expectedTotal = withUnread.fold<int>(
        0, (sum, m) => sum + ChatPreview.forMeeting(m).unreadCount);
    expect(withUnread, isNotEmpty);
    expect(expectedTotal, greaterThan(0));

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: _TestRepo(withUnread), now: now),
    ));
    await tester.pumpAndSettle();

    // 탭 라벨 옆 배지 텍스트(합계)가 노출된다.
    expect(find.text('$expectedTotal'), findsOneWidget);
  });

  testWidgets('미읽음이 없으면 배지가 표시되지 않는다', (tester) async {
    final now = DateTime(2026, 5, 23, 12, 0);

    Meeting future(String id) => _m(id, '미래 $id', now.add(const Duration(days: 1)));
    final candidates = [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
    ].map(future).toList();
    final noUnread = candidates
        .where((m) => ChatPreview.forMeeting(m).unreadCount == 0)
        .toList();
    expect(noUnread, isNotEmpty);

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: _TestRepo(noUnread), now: now),
    ));
    await tester.pumpAndSettle();

    // 배지 컨테이너(textDanger 배경)는 그려지지 않아야 한다.
    // 안읽음 라벨은 한 번만 보여야 한다(배지 텍스트가 추가로 잡히지 않음).
    expect(find.text('안읽음'), findsOneWidget);
  });

  testWidgets('채팅이 없으면 안내 문구', (tester) async {
    final now = DateTime(2026, 5, 23, 12, 0);
    final repo = _TestRepo([
      // 만료된 채팅만 → 어떤 섹션에도 안 들어감.
      _m('old', '오래된 채팅', now.subtract(const Duration(hours: 100))),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    expect(find.text('아직 채팅이 없어요'), findsOneWidget);
  });
}

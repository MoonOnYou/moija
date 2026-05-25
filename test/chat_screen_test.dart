import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/chat/chat_preview.dart';
import 'package:moija/features/chat/chat_screen.dart';
import 'package:moija/models/join_method.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

Meeting _m(
  String id,
  String title,
  DateTime start, {
  MeetingCategory category = MeetingCategory.cafe,
  String description = '강남에서 즐기는 카페 모임이에요.',
  int currentMembers = 3,
  int maxMembers = 6,
  JoinMethod joinMethod = JoinMethod.approval,
}) =>
    Meeting(
      id: id,
      title: title,
      category: category,
      startTime: start,
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: currentMembers,
      maxMembers: maxMembers,
      description: description,
      joinMethod: joinMethod,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('내모임은 신청대기→진행중→다가오는→종료된 순으로 노출된다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final pending = _m('p1', '대기 카페', now.add(const Duration(days: 2)));
    final ongoing = _m('o1', '진행 등산', now.subtract(const Duration(hours: 1)));
    final upcoming = _m('u1', '다가오는 한잔', now.add(const Duration(days: 1)));
    final ended = _m('e1', '끝난 보드게임', now.subtract(const Duration(hours: 10)));

    final repo = MeetingRepository.test(
      meetings: [pending, ongoing, upcoming, ended],
      joined: {'o1', 'u1', 'e1'},
      pending: {'p1'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    // 네 섹션 모두 노출.
    expect(find.text('신청 대기중'), findsOneWidget);
    expect(find.text('진행중인 모임'), findsOneWidget);
    expect(find.text('다가오는 모임'), findsOneWidget);
    expect(find.text('종료된 모임'), findsOneWidget);

    // 위→아래 순서 확인.
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('신청 대기중'), lessThan(y('진행중인 모임')));
    expect(y('진행중인 모임'), lessThan(y('다가오는 모임')));
    expect(y('다가오는 모임'), lessThan(y('종료된 모임')));
  });

  testWidgets('내모임에는 내가 참가한(또는 대기 중인) 모임만 보인다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final mine = _m('mine', '내 모임', now.add(const Duration(days: 1)));
    final others = _m('other', '남의 모임', now.add(const Duration(days: 1)));

    final repo = MeetingRepository.test(
      meetings: [mine, others],
      joined: {'mine'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    expect(find.text('내 모임'), findsOneWidget);
    expect(find.text('남의 모임'), findsNothing);
  });

  testWidgets('신청 대기 셀은 요약과 "신청 취소" 버튼을 보여준다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final pending = _m('p1', '잠실 야구 직관', now.add(const Duration(days: 2)),
        description: '같이 응원해요. 자리는 미리 예약돼 있어요!');

    final repo = MeetingRepository.test(
      meetings: [pending],
      pending: {'p1'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    expect(find.text('잠실 야구 직관'), findsOneWidget);
    expect(find.text('같이 응원해요. 자리는 미리 예약돼 있어요!'), findsOneWidget);
    expect(find.text('신청 취소'), findsOneWidget);
  });

  testWidgets('신청 취소를 확정하면 해당 셀이 사라진다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final pending = _m('p1', '잠실 야구 직관', now.add(const Duration(days: 2)));
    final repo = MeetingRepository.test(
      meetings: [pending],
      pending: {'p1'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('신청 취소'));
    await tester.pumpAndSettle();
    // 확인 다이얼로그에서 "취소하기" 선택.
    await tester.tap(find.widgetWithText(TextButton, '취소하기'));
    await tester.pumpAndSettle();

    expect(find.text('잠실 야구 직관'), findsNothing);
    expect(find.text('아직 참여 중인 모임이 없어요'), findsOneWidget);
    expect(repo.isPending(pending), isFalse);
  });

  testWidgets('방장 다가오는 모임 아래에 신청자 검토 버튼이 노출된다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final hostMeeting =
        _m('u-host', '방장 다가오는', now.add(const Duration(days: 2)));
    final repo = MeetingRepository.test(
      meetings: [hostMeeting],
      joined: {'u-host'},
      hosted: {'u-host'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    final n = pendingApplicantsFor(hostMeeting);
    expect(find.text('신청자 $n명 검토하기'), findsOneWidget);
    expect(find.text('방장'), findsOneWidget); // 셀의 방장 칩.
  });

  testWidgets('방장 종료된 모임 아래에 매너 평가 버튼이 노출된다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final hostEnded =
        _m('e-host', '방장 끝난', now.subtract(const Duration(hours: 10)));
    final repo = MeetingRepository.test(
      meetings: [hostEnded],
      joined: {'e-host'},
      hosted: {'e-host'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    expect(find.text('팀원 매너 평가하기'), findsOneWidget);
  });

  testWidgets('선착순 방장 다가오는 모임에는 검토 버튼이 없다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final hostFirstCome = _m('u-host-fc', '선착순 방장 다가오는',
        now.add(const Duration(days: 2)),
        joinMethod: JoinMethod.firstCome);

    final repo = MeetingRepository.test(
      meetings: [hostFirstCome],
      joined: {'u-host-fc'},
      hosted: {'u-host-fc'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    // 셀과 방장 칩은 보이지만 검토 버튼은 없어야 한다.
    expect(find.text('선착순 방장 다가오는'), findsOneWidget);
    expect(find.text('방장'), findsOneWidget);
    expect(find.textContaining('검토하기'), findsNothing);
  });

  testWidgets('비방장 모임에는 액션 버튼이 없다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final guest =
        _m('u-guest', '게스트 다가오는', now.add(const Duration(days: 1)));
    final repo = MeetingRepository.test(
      meetings: [guest],
      joined: {'u-guest'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('검토하기'), findsNothing);
    expect(find.textContaining('평가하기'), findsNothing);
    expect(find.text('방장'), findsNothing);
  });

  testWidgets('참여 중인 모임이 없으면 안내 문구가 노출된다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final repo = MeetingRepository.test();

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    expect(find.text('아직 참여 중인 모임이 없어요'), findsOneWidget);
  });

  test('배지 합계 = 채팅 안읽음 + 방장 액션 카드(대기·선착순 검토 제외)', () {
    final now = DateTime(2026, 5, 25, 12, 0);

    final upHost = _m('u-host', '방장 다가오는', now.add(const Duration(days: 1)));
    final upHostFc = _m('u-host-fc', '선착순 방장 다가오는',
        now.add(const Duration(days: 2)),
        joinMethod: JoinMethod.firstCome);
    final endHost =
        _m('e-host', '방장 끝난', now.subtract(const Duration(hours: 5)));
    final guest = _m('u-guest', '게스트 다가오는', now.add(const Duration(days: 1)));
    final pending = _m('p1', '대기', now.add(const Duration(days: 3)));

    final repo = MeetingRepository.test(
      meetings: [upHost, upHostFc, endHost, guest, pending],
      joined: {'u-host', 'u-host-fc', 'e-host', 'u-guest'},
      hosted: {'u-host', 'u-host-fc', 'e-host'},
      pending: {'p1'},
    );

    final chatUnread = ChatPreview.forMeeting(upHost).unreadCount +
        ChatPreview.forMeeting(upHostFc).unreadCount +
        ChatPreview.forMeeting(endHost).unreadCount +
        ChatPreview.forMeeting(guest).unreadCount;
    // 방장 액션: 승인제 다가오는 1 + 종료된 1 = +2 (선착순 다가오는·대기는 제외).
    expect(myMeetingsBadgeTotal(repo, now), chatUnread + 2);
  });
}

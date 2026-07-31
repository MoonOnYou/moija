import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/chat/chat_message.dart';
import 'package:moija/features/chat/chat_preview.dart';
import 'package:moija/features/chat/chat_screen.dart';
import 'package:moija/features/meeting/meeting_detail_screen.dart';
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

  testWidgets('신청 대기 셀을 탭하면 모임 상세가 열린다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    await tester.tap(find.text('잠실 야구 직관'));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailScreen), findsOneWidget);
    // 이미 신청한 모임이므로 재신청 버튼 대신 대기 상태가 보인다.
    expect(find.text('승인 대기중'), findsOneWidget);
    expect(find.text('참가 신청하기'), findsNothing);
  });

  testWidgets('상세에서 신청을 취소하면 내모임 목록에서 사라진다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    await tester.tap(find.text('잠실 야구 직관'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '신청 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '취소하기'));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailScreen), findsNothing);
    expect(repo.isPending(pending), isFalse);
    expect(find.text('아직 참여 중인 모임이 없어요'), findsOneWidget);
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

  testWidgets('셀 미리보기는 채팅방의 마지막 메시지를 보여준다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 5, 25, 12, 0);
    final joined = _m('u-preview', '미리보기 모임', now.add(const Duration(days: 1)));
    final repo = MeetingRepository.test(
      meetings: [joined],
      joined: {'u-preview'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    final last = lastChatMessageOf(joined, repo)!;
    expect(find.text('${last.sender}: ${last.text}'), findsOneWidget);
  });

  testWidgets('채팅방에서 메시지를 보내면 셀 미리보기도 갱신된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 5, 25, 12, 0);
    final joined = _m('u-send', '전송 모임', now.add(const Duration(days: 1)));
    final repo = MeetingRepository.test(
      meetings: [joined],
      joined: {'u-send'},
    );

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    // 셀 → 채팅방 진입 후 메시지 전송.
    await tester.tap(find.text('전송 모임'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('chat-composer-input')), '조금 늦을 것 같아요');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-composer-send')));
    await tester.pumpAndSettle();

    // 뒤로 나오면 미리보기가 방금 보낸 메시지로 바뀌어 있다.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('$kMyNickname: 조금 늦을 것 같아요'), findsOneWidget);
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

  testWidgets('리스트와 빈 상태 모두 RefreshIndicator로 감싸져 있다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);

    // 데이터가 있을 때.
    final mine = _m('mine', '내 모임', now.add(const Duration(days: 1)));
    final repoWith = MeetingRepository.test(
      meetings: [mine],
      joined: {'mine'},
    );
    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repoWith, now: now),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // 비어 있을 때도.
    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: MeetingRepository.test(), now: now),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('아직 참여 중인 모임이 없어요'), findsOneWidget);
  });

  testWidgets('아래로 당기면 새로고침 인디케이터가 표시·종료된다', (tester) async {
    final now = DateTime(2026, 5, 25, 12, 0);
    final mine = _m('mine', '새로고침 모임', now.add(const Duration(days: 1)));
    final repo = MeetingRepository.test(meetings: [mine], joined: {'mine'});

    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(repository: repo, now: now),
    ));
    await tester.pumpAndSettle();

    // 리스트 아래로 fling → 인디케이터 표시 → onRefresh 완료 후 사라짐.
    await tester.fling(
        find.text('새로고침 모임'), const Offset(0, 300), 1000);
    await tester.pump(); // 인디케이터 등장 프레임
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    // 화면은 정상 유지.
    expect(find.text('새로고침 모임'), findsOneWidget);
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

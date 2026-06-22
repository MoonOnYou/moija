import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/chat/chat_room_screen.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/theme/app_colors.dart';

Meeting _m(
  String id,
  String title,
  DateTime start, {
  int currentMembers = 3,
  int maxMembers = 4,
}) =>
    Meeting(
      id: id,
      title: title,
      category: MeetingCategory.cafe,
      startTime: start,
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: currentMembers,
      maxMembers: maxMembers,
    );

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      home: child,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('AppBar에 모임 이름이 보이고 시스템 메시지가 가운데 노출된다', (tester) async {
    final m = _m('chat1', '강남 카페 모임', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat1'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    expect(find.text('강남 카페 모임'), findsAtLeastNWidgets(1)); // AppBar 제목
    expect(find.text('채팅방이 생성되었습니다'), findsOneWidget);
    expect(find.textContaining('님이 입장하셨습니다'),
        findsAtLeastNWidgets(1));
  });

  testWidgets('내 메시지는 우측, 타인 메시지는 좌측에 배치된다', (tester) async {
    final m = _m('chat-x', '말풍선 모임', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-x'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    final mine = find.text('저도 잘 부탁드려요! 도착하면 톡 드릴게요');
    final host = find.text('안녕하세요, 모임 들어와주셔서 감사해요!');
    expect(mine, findsOneWidget);
    expect(host, findsOneWidget);

    final screenMidX =
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
    final mineX = tester.getCenter(mine).dx;
    final hostX = tester.getCenter(host).dx;
    expect(mineX, greaterThan(screenMidX),
        reason: '내 메시지는 화면 오른쪽 절반에 있어야 한다');
    expect(hostX, lessThan(screenMidX),
        reason: '타인 메시지는 화면 왼쪽 절반에 있어야 한다');
  });

  testWidgets('햄버거 → endDrawer에 모임 정보와 첫 멤버 방장 칩 노출', (tester) async {
    final m = _m('chat-d', '드로어 모임', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-d'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();

    // 드로어 헤더의 제목, 팀원 섹션, 방장 칩(첫 번째 멤버 행), 모임 나가기.
    expect(find.text('드로어 모임'), findsAtLeastNWidgets(1));
    expect(find.text('팀원'), findsOneWidget);
    expect(find.text('방장'), findsOneWidget); // 첫 멤버 한 명만 방장
    expect(find.text('모임 나가기'), findsOneWidget);
  });

  testWidgets('팀원 탭 → 차단/신고 옵션 시트', (tester) async {
    final m = _m('chat-act', '차단 테스트', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-act'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();

    // 첫 번째 멤버 행을 탭.
    await tester.tap(find.byKey(const ValueKey('member-tile-0')));
    await tester.pumpAndSettle();

    expect(find.text('차단하기'), findsOneWidget);
    expect(find.text('신고하기'), findsOneWidget);
  });

  testWidgets('팀원 나가기 다이얼로그: 50 다이아 안내·즉시 나가기 가능', (tester) async {
    final m = _m('chat-leave', '나가기 모임', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-leave'});
    expect(repo.isJoined(m), isTrue);

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모임 나가기'));
    await tester.pumpAndSettle();

    // 팀원 다이얼로그: 50 다이아 + 매너평가 안내, 방장 라디오·안내 없음.
    expect(find.textContaining('50 다이아'), findsOneWidget);
    expect(find.textContaining('매너점수를 평가'), findsOneWidget);
    expect(find.textContaining('방장을 넘겨줘야 해요'), findsNothing);

    final confirm = find.byKey(const Key('leave-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repo.isJoined(m), isFalse);
  });

  testWidgets('방장 나가기 다이얼로그: 300 다이아 + 라디오, 선택 전 비활성',
      (tester) async {
    final m = _m('chat-host-leave', '방장 나가기',
        DateTime(2026, 5, 25, 18, 0),
        currentMembers: 3); // 호스트 포함 3명 → 다른 멤버 2명
    final repo = MeetingRepository.test(
      meetings: [m],
      joined: {'chat-host-leave'},
      hosted: {'chat-host-leave'},
    );
    final others = repo.participantsOf(m).sublist(1);

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모임 나가기'));
    await tester.pumpAndSettle();

    // 방장 안내문 + 방장 라디오 노출.
    expect(find.textContaining('300 다이아'), findsOneWidget);
    expect(find.textContaining('방장을 넘겨줘야 해요'), findsOneWidget);
    expect(find.byKey(ValueKey('next-host-${others.first.nickname}')),
        findsOneWidget);

    // 선택 전엔 나가기 비활성.
    final confirm = find.byKey(const Key('leave-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    // 첫 다른 멤버를 다음 방장으로 선택.
    await tester.tap(
        find.byKey(ValueKey('next-host-${others.first.nickname}')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repo.isJoined(m), isFalse);
    expect(repo.isHost(m), isFalse);
  });

  testWidgets('방장 단독(혼자) 나가기 다이얼로그: 방장 라디오 없이 즉시 가능',
      (tester) async {
    final m = _m('chat-host-solo', '혼자 방장',
        DateTime(2026, 5, 25, 18, 0),
        currentMembers: 1); // 호스트만
    final repo = MeetingRepository.test(
      meetings: [m],
      joined: {'chat-host-solo'},
      hosted: {'chat-host-solo'},
    );

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모임 나가기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('300 다이아'), findsOneWidget);
    expect(find.textContaining('방장을 넘겨줘야 해요'), findsNothing);

    final confirm = find.byKey(const Key('leave-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
  });

  testWidgets('전송 버튼은 빈 입력에는 비활성, 텍스트가 있으면 활성·전송 후 입력 비움', (tester) async {
    final m = _m('chat-send', '입력 모임', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-send'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    final sendBtn = find.byKey(const Key('chat-composer-send'));
    expect(tester.widget<IconButton>(sendBtn).onPressed, isNull,
        reason: '빈 입력일 때 전송 비활성');

    await tester.enterText(
        find.byKey(const Key('chat-composer-input')), '테스트 보내는 메시지 입니다');
    await tester.pump();
    expect(tester.widget<IconButton>(sendBtn).onPressed, isNotNull);

    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    // 내 메시지로 노출되고 입력은 비워진다.
    expect(find.text('테스트 보내는 메시지 입니다'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-composer-input')))
            .controller!
            .text,
        '');
  });

  testWidgets('입력창은 멀티라인이며 키보드 액션은 줄바꿈이다', (tester) async {
    final m = _m('chat-ml', '멀티라인', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-ml'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    final field = tester
        .widget<TextField>(find.byKey(const Key('chat-composer-input')));
    expect(field.maxLines, isNull, reason: '무제한 줄');
    expect(field.minLines, 1);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
  });

  testWidgets('endDrawer 가장자리 드래그는 비활성화돼 있다', (tester) async {
    final m = _m('chat-d2', '드래그 차단', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-d2'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.endDrawerEnableOpenDragGesture, isFalse);
  });

  testWidgets('드로어 헤더에 비용·남은 자리가 노출된다', (tester) async {
    final m = _m('chat-info', '정보 보강', DateTime(2026, 5, 25, 18, 0),
        currentMembers: 3, maxMembers: 6);
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-info'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();

    expect(find.text('더치페이'), findsOneWidget); // 기본 split cost 라벨
    expect(find.textContaining('3/6명'), findsOneWidget);
    expect(find.textContaining('3자리 남음'), findsOneWidget);
  });

  testWidgets('멤버 행에 년생·활동·만난 횟수가 보인다', (tester) async {
    final m = _m('chat-prof', '프로필 표기', DateTime(2026, 5, 25, 18, 0));
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-prof'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('년생'), findsAtLeastNWidgets(1));
    expect(find.textContaining('활동'), findsAtLeastNWidgets(1));
    expect(find.textContaining('나와'), findsAtLeastNWidgets(1));
  });

  testWidgets('말풍선 시간 옆에 안 읽은 사람 수(앰버 숫자)가 노출된다', (tester) async {
    final m = _m('chat-unread', '안읽음 표기', DateTime(2026, 5, 25, 18, 0),
        currentMembers: 3);
    final repo = MeetingRepository.test(meetings: [m], joined: {'chat-unread'});

    await tester.pumpWidget(_wrap(
      ChatRoomScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    // 앰버색 작은 숫자(_UnreadCount)가 최근 말풍선들에 붙는다.
    final amberNumbers = find.byWidgetPredicate(
      (w) => w is Text && w.style?.color == AppColors.amber,
    );
    expect(amberNumbers, findsAtLeastNWidgets(1));

    // 표시되는 텍스트는 숫자다.
    final firstText = tester.widgetList<Text>(amberNumbers).first;
    expect(int.tryParse(firstText.data ?? ''), isNotNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/create_meeting_screen.dart';
import 'package:moija/features/meeting/diamond_recharge_screen.dart';
import 'package:moija/shell/app_navigation.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  setUp(() {
    selectedTab.value = 0;
    pendingFocusDay.value = null;
  });

  // 필수 항목을 모두 채운다(설명·구체장소 제외).
  Future<void> fillRequired(WidgetTester tester) async {
    await tester.tap(find.text('카페')); // 카테고리
    await tester.pump();
    await tester.enterText(find.byKey(const Key('title')), '주말 카페 모임');
    await tester.pump();

    await tester.tap(find.byKey(const Key('date'))); // 날짜 → OK
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('time'))); // 시간 → OK
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('location'))); // 지역(단일선택)
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선')); // 노선 드릴다운
    await tester.pumpAndSettle();
    await tester.tap(find.text('시청')); // 역 선택 → 즉시 pop
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('place')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('place')), '시청역 2번 출구'); // 구체 장소(필수)
    await tester.pump();

    // 비용 칩이 보이도록 스크롤(ListView 지연 빌드).
    await tester.scrollUntilVisible(
      find.text('더치페이'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('더치페이')); // 비용
    await tester.pump();
  }

  testWidgets('필수 미완성이면 버튼 비활성, 채우면 활성', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();

    ElevatedButton button() =>
        tester.widget<ElevatedButton>(find.byKey(const Key('submit')));
    expect(button().onPressed, isNull); // 초기 비활성

    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    expect(button().onPressed, isNotNull); // 활성
  });

  testWidgets('구체적인 장소가 비면 버튼 비활성', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();

    await fillRequired(tester); // 장소 포함 모두 채움 → 활성
    // 장소 필드가 보이도록 위로 스크롤 후 비운다.
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place')), '');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('submit')));
    final button =
        tester.widget<ElevatedButton>(find.byKey(const Key('submit')));
    expect(button.onPressed, isNull); // 장소가 비면 비활성
  });

  testWidgets('잔액 충분: 저장소에 추가되고 pop', (tester) async {
    final repo = MeetingRepository();
    final before = repo.allMeetings.length;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateMeetingScreen(
                      repository: repo, currentDiamonds: 1000),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    // 안내(#22) 동의해야 실제로 생성된다.
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateMeetingScreen), findsNothing);
    expect(repo.allMeetings.length, before + 1);
    expect(repo.allMeetings.last.title, '주말 카페 모임');
    expect(selectedTab.value, 1); // 채팅 탭으로 이동
  });

  testWidgets('카테고리 직접 입력: customCategory로 저장된다', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();
    await fillRequired(tester); // 카페 선택됨

    // 카테고리 영역으로 올라가 직접 입력 칩을 연다.
    await tester.scrollUntilVisible(
      find.text('+ 직접 입력하기'),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('+ 직접 입력하기'));
    await tester.pump();
    await tester.tap(find.text('+ 직접 입력하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '클라이밍');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    // 입력한 이름이 칩으로 노출되고 프리셋(카페)은 해제된다.
    expect(find.text('클라이밍 ✓'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();

    expect(repo.allMeetings.last.customCategory, '클라이밍');
    expect(repo.allMeetings.last.categoryLabel, '클라이밍');
  });

  testWidgets('인원: 직접 입력 가능하고 99 초과는 99로 잘린다', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();
    await fillRequired(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('members-input')),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('members-input')), '150');
    await tester.pump();
    // 99로 클램프되어 필드에 반영된다.
    expect(find.text('99'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('members-input')), '8');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();
    expect(repo.allMeetings.last.maxMembers, 8);
  });

  testWidgets('비용: 기타 선택 후 직접 입력값이 저장된다', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();
    await fillRequired(tester); // 더치페이 선택됨

    await tester.scrollUntilVisible(
      find.text('기타'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('기타'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('cost-etc')), '연구실에서 갹출');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();
    expect(repo.allMeetings.last.cost.display, '연구실에서 갹출');
  });

  testWidgets('잔액 부족: 충전 화면으로 이동', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 30),
    ));
    await tester.pumpAndSettle();
    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('다이아가 부족해요'), findsOneWidget);
    expect(find.byType(DiamondRechargeScreen), findsOneWidget);
  });

  testWidgets('온라인 토글 ON 시 지역 선택이 사라진다', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('location')), findsOneWidget);
    await tester.tap(find.byKey(const Key('online')));
    await tester.pump();
    expect(find.byKey(const Key('location')), findsNothing);
  });
}

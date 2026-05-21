import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/create_meeting_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
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
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();

    // 비용 칩이 보이도록 스크롤(ListView 지연 빌드).
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
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
}

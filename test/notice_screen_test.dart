import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/common/notice_screen.dart';

void main() {
  testWidgets('동의 버튼은 true, 닫기는 false를 반환한다', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => Notices.createMeeting()),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // #22 안내 내용 노출
    expect(find.text('모임을 만들기 전에\n확인해주세요'), findsOneWidget);
    expect(find.text('다이아 300개로 모임을 만들어요'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('승인제 안내에는 방장에게 한마디 입력칸이 있다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Notices.joinApproval()));
    await tester.pumpAndSettle();

    expect(find.text('승인제 모임 · 방장 수락 필요'), findsOneWidget);
    expect(find.byKey(const Key('host-message')), findsOneWidget);
    expect(find.text('동의하고 참가 신청하기'), findsOneWidget);
  });

  testWidgets('선착순 안내에는 방장 한마디 칸이 없다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Notices.joinFirstCome()));
    await tester.pumpAndSettle();

    expect(find.text('선착순 모임 · 즉시 확정'), findsOneWidget);
    expect(find.byKey(const Key('host-message')), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/signup/signup_intro_screen.dart';
import 'package:moija/features/signup/signup_session.dart';

void main() {
  Future<SignupSession> pumpIntro(WidgetTester tester) async {
    final session = SignupSession();
    await tester.pumpWidget(
      MaterialApp(
        // 실기기 노치 영역을 흉내 내 공용 스캐폴드 앱바가 들어갈 상단 패딩을 준다.
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(top: 44)),
            child: SignupIntroScreen(session: session),
          ),
        ),
      ),
    );
    return session;
  }

  testWidgets('입력 후 완료를 누르면 trim된 자기소개가 세션에 저장된다', (tester) async {
    final session = await pumpIntro(tester);

    await tester.enterText(find.byType(TextField), '  처음 만나는 사람 환영해요 :)  ');
    await tester.pump();

    expect(find.text('완료'), findsOneWidget);
    expect(find.text('건너뛰기'), findsNothing);

    await tester.tap(find.text('완료'));
    await tester.pump();

    expect(session.intro, '처음 만나는 사람 환영해요 :)');

    // 완료 화면의 타이머 정리
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('비어 있으면 CTA가 건너뛰기이고, 눌러도 빈 소개로 진행된다', (tester) async {
    final session = await pumpIntro(tester);

    expect(find.text('건너뛰기'), findsOneWidget);
    expect(find.text('완료'), findsNothing);

    await tester.tap(find.text('건너뛰기'));
    await tester.pump();

    expect(session.intro, '');

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('자기소개는 150자를 넘길 수 없다', (tester) async {
    await pumpIntro(tester);

    await tester.enterText(find.byType(TextField), 'ㄱ' * 200);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 150);
    // maxLength 검증 (포매터 누락 방지)
    expect(field.maxLength, 150);
    expect(
      field.inputFormatters,
      contains(isA<LengthLimitingTextInputFormatter>()),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/api/auth_api.dart';
import 'package:moija/features/signup/signup_phone_screen.dart';
import 'package:moija/features/signup/signup_session.dart';

void main() {
  const registered = PhoneAvailability(
    available: false,
    detail: '이미 가입된 번호입니다.',
    reason: 'registered',
  );
  const free = PhoneAvailability(
    available: true,
    detail: '가입할 수 있는 번호입니다.',
  );

  /// 조회된 번호를 기록하는 확인 함수. [byPhone]에 없으면 가입 가능으로 답한다.
  ({List<String> asked, Future<PhoneAvailability> Function(String)? fn}) checker(
    Map<String, PhoneAvailability> byPhone,
  ) {
    final asked = <String>[];
    return (
      asked: asked,
      fn: (String phone) async {
        asked.add(phone);
        return byPhone[phone] ?? free;
      },
    );
  }

  Future<void> pumpPhone(
    WidgetTester tester,
    Future<PhoneAvailability> Function(String)? check,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      // 실기기 노치 영역을 흉내 내 공용 스캐폴드 앱바 상단 패딩을 준다.
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(padding: const EdgeInsets.only(top: 44)),
          child: SignupPhoneScreen(
            session: SignupSession(),
            checkAvailability: check,
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  bool ctaEnabled(WidgetTester tester) {
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('인증번호 받기'),
        matching: find.byType(ElevatedButton),
      ),
    );
    return button.onPressed != null;
  }

  testWidgets('번호를 다 입력하면 바로 중복 확인 후 안내하고 진행을 막는다', (tester) async {
    final c = checker({'01011112222': registered});
    await pumpPhone(tester, c.fn);

    await tester.enterText(find.byKey(const Key('signup-phone-field')), '01011112222');
    await tester.pump();

    // 디바운스 전에는 아직 서버를 찌르지 않는다.
    expect(c.asked, isEmpty);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(c.asked, ['01011112222']);
    expect(find.byKey(const Key('signup-phone-blocked')), findsOneWidget);
    expect(find.textContaining('이미 가입된 번호입니다.'), findsOneWidget);
    expect(find.byKey(const Key('signup-phone-go-login')), findsOneWidget);
    expect(ctaEnabled(tester), isFalse);
  });

  testWidgets('가입 가능한 번호면 안내를 띄우고 진행할 수 있다', (tester) async {
    final c = checker({});
    await pumpPhone(tester, c.fn);

    await tester.enterText(find.byKey(const Key('signup-phone-field')), '01033334444');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(c.asked, ['01033334444']);
    expect(find.byKey(const Key('signup-phone-available')), findsOneWidget);
    expect(find.byKey(const Key('signup-phone-blocked')), findsNothing);
    expect(ctaEnabled(tester), isTrue);
  });

  testWidgets('11자리 미만이면 확인하지 않고, 번호를 고치면 이전 결과를 버린다', (tester) async {
    final c = checker({'01011112222': registered});
    await pumpPhone(tester, c.fn);

    final field = find.byKey(const Key('signup-phone-field'));
    await tester.enterText(field, '0101111');
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.asked, isEmpty);

    await tester.enterText(field, '01011112222');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signup-phone-blocked')), findsOneWidget);

    // 한 글자 지우면 경고가 사라지고(결과 무효) 다시 확인 대상이 된다.
    await tester.enterText(field, '0101111222');
    await tester.pump();
    expect(find.byKey(const Key('signup-phone-blocked')), findsNothing);
    expect(ctaEnabled(tester), isFalse); // 11자리 미만이라 비활성

    await tester.enterText(field, '01011113333');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(c.asked, ['01011112222', '01011113333']);
    expect(find.byKey(const Key('signup-phone-available')), findsOneWidget);
  });

  testWidgets('확인이 실패하면(네트워크 오류) 진행을 막지 않는다', (tester) async {
    await pumpPhone(tester, (phone) async => throw Exception('offline'));

    await tester.enterText(find.byKey(const Key('signup-phone-field')), '01055556666');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signup-phone-blocked')), findsNothing);
    expect(find.byKey(const Key('signup-phone-available')), findsNothing);
    expect(ctaEnabled(tester), isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/auth/auth_store.dart';
import 'package:moija/features/profile/profile_screen.dart';
import 'package:moija/models/auth_user.dart';
import 'package:moija/models/member.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap() => const MaterialApp(home: ProfileScreen());

void main() {
  testWidgets('헤더에 닉네임·년생·성별·매너점수·활동 회수가 노출된다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('나'), findsAtLeastNWidgets(1));
    expect(find.textContaining('1998년생'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.textContaining('활동 12회'), findsOneWidget);
  });

  testWidgets('닉네임 편집 → 다이얼로그 저장으로 반영된다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-nickname')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '문온유');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('문온유'), findsOneWidget);
  });

  testWidgets('자기소개 편집 다이얼로그가 뜬다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-intro')));
    await tester.pumpAndSettle();

    expect(find.text('자기소개 수정'), findsOneWidget);
  });

  testWidgets('다이아 카드에 잔액과 충전하기 버튼이 노출된다', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('내 다이아'), findsOneWidget);
    expect(find.text('500개'), findsOneWidget); // Wallet.myDiamonds
    expect(find.byKey(const Key('recharge-button')), findsOneWidget);
  });

  testWidgets('정책·계정 메뉴가 모두 노출된다(리젝 방지 핵심 항목)', (tester) async {
    // ListView가 lazy mount이라 메뉴 전체가 한 화면에 들어가도록 뷰포트를 늘린다.
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final must = [
      '내 관심사',
      '차단 목록',
      '알림 설정',
      '서비스 이용약관',
      '개인정보 처리방침',
      '위치기반서비스 이용약관',
      '커뮤니티 가이드 · 신고 정책',
      '고객센터 · 문의하기',
      '앱 버전',
      // 비로그인 상태에서는 로그인 진입 메뉴가 노출된다(로그인 시 '로그아웃'으로 바뀜).
      '로그인 · 회원가입',
      '회원 탈퇴',
    ];
    for (final label in must) {
      expect(find.text(label), findsOneWidget, reason: '$label 미노출');
    }
  });

  testWidgets('회원 탈퇴 → 탈퇴 사유 화면으로 이동', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // 화면 하단으로 스크롤해 회원 탈퇴가 보이게.
    await tester.dragUntilVisible(
      find.text('회원 탈퇴'),
      find.byType(ListView),
      const Offset(0, -200),
    );

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    // 탈퇴 플로우 첫 화면(사유 선택)으로 진입한다.
    expect(find.text('떠나는 이유를 알려주세요'), findsOneWidget);
  });

  testWidgets('로그인 상태에서는 프로필과 로그아웃 메뉴가 노출된다', (tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.save(
      access: 'a',
      refresh: 'r',
      user: const AuthUser(
        id: 1,
        phone: '01011112222',
        nickname: '온유',
        birthYear: 1996,
        gender: Gender.male,
        mannerScore: 4.5,
        totalActivities: 3,
        intro: '반가워요',
      ),
    );
    addTearDown(() async => AuthStore.instance.clear());

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // 로그인 사용자 프로필 + 로그아웃(로그인 진입 메뉴는 숨김).
    expect(find.text('온유'), findsAtLeastNWidgets(1));
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('로그인 · 회원가입'), findsNothing);
  });
}

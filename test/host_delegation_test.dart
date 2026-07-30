import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/withdrawal/withdrawal_confirm_screen.dart';
import 'package:moija/features/withdrawal/withdrawal_flow.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/member.dart';

Meeting _meeting(String id, String title, {int current = 4}) => Meeting(
      id: id,
      title: title,
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 8, 3, 19, 0),
      location: '신림 카페',
      region: '신림',
      locationId: 'seoul-line2',
      currentMembers: current,
      maxMembers: 6,
    );

const _members = [
  Member(
      nickname: '재호',
      birthYear: 1996,
      gender: Gender.male,
      mannerScore: 4.8,
      totalActivities: 32,
      timesMetWithMe: 3,
      intro: '안녕하세요'),
  Member(
      nickname: '민지',
      birthYear: 1999,
      gender: Gender.female,
      mannerScore: 4.5,
      totalActivities: 18,
      timesMetWithMe: 1,
      intro: '반가워요'),
];

WithdrawalSession _session({
  required List<Meeting> hosted,
  List<Member> Function(Meeting)? candidatesOf,
  List<String>? delegatedLog,
}) =>
    WithdrawalSession(
      phone: '01012345678',
      diamonds: 1000,
      mannerScore: 4.7,
      activities: 14,
      blockCount: 3,
      joinedCount: 3,
      hostedMeetings: hosted,
      candidatesOf: candidatesOf ?? (_) => _members,
      onDelegate: (m, host) => delegatedLog?.add('${m.id}:${host.nickname}'),
    );

Widget _wrap(WithdrawalSession session) =>
    MaterialApp(home: WithdrawalConfirmScreen(session: session));

void _sizeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('방장 모임이 있으면 개수·제목을 안내하고 탈퇴 진행을 막는다', (tester) async {
    _sizeView(tester);

    final session = _session(hosted: [
      _meeting('h1', '주말 한강 러닝'),
      _meeting('h2', '판교 보드게임'),
    ]);
    await tester.pumpWidget(_wrap(session));
    await tester.pumpAndSettle();

    expect(find.text('방장으로 운영 중인 모임 2개가 있어요'), findsOneWidget);
    expect(find.text('· 주말 한강 러닝'), findsOneWidget);
    expect(find.text('· 판교 보드게임'), findsOneWidget);

    await tester.tap(find.text('인증번호 받기'));
    await tester.pump();
    expect(find.text('운영 중인 모임의 방장을 먼저 위임해주세요'), findsOneWidget);
  });

  testWidgets('모임 2개를 모두 위임하면 탈퇴를 진행할 수 있다', (tester) async {
    _sizeView(tester);

    final delegated = <String>[];
    final session = _session(
      hosted: [_meeting('h1', '주말 한강 러닝'), _meeting('h2', '판교 보드게임')],
      delegatedLog: delegated,
    );
    await tester.pumpWidget(_wrap(session));
    await tester.pumpAndSettle();

    // 위임 화면 진입 — 남은 개수가 CTA에 보인다.
    await tester.tap(find.byKey(const Key('go-delegate')));
    await tester.pumpAndSettle();
    expect(find.text('방장 자리를 넘겨주세요'), findsOneWidget);
    expect(find.text('0/2 위임됨'), findsOneWidget);
    // 방장이 모임을 닫는 선택지는 없다.
    expect(find.text('모임 닫기'), findsNothing);

    // h1 — 멤버 선택 후 위임.
    await tester.tap(find.byKey(const Key('delegate-h1')));
    await tester.pumpAndSettle();
    expect(find.text('누구에게 방장을 넘길까요?'), findsOneWidget);
    // 아무도 안 골랐으면 확정 버튼이 비활성이다.
    expect(
      tester.widget<WithdrawalButton>(find.byKey(const Key('confirm-new-host')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('candidate-민지')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('민지님에게 위임'));
    await tester.pumpAndSettle();
    expect(find.text('민지님에게 방장을 위임했어요'), findsOneWidget);
    expect(find.text('1/2 위임됨'), findsOneWidget);

    // h2 — 두 번째 모임도 위임.
    await tester.tap(find.byKey(const Key('delegate-h2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('candidate-재호')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('재호님에게 위임'));
    await tester.pumpAndSettle();

    // 완료 → 확정 다이얼로그 → 저장소 훅 호출.
    expect(find.text('완료'), findsOneWidget);
    await tester.tap(find.byKey(const Key('handover-done')));
    await tester.pumpAndSettle();
    expect(find.text('이대로 확정할까요?'), findsOneWidget);
    await tester.tap(find.text('확정'));
    await tester.pumpAndSettle();

    expect(delegated, ['h1:민지', 'h2:재호']);
    expect(session.hostsMeeting, isFalse);

    // 확인 화면으로 복귀 — 요약 카드가 뜨고 탈퇴가 진행된다.
    expect(find.text('방장을 모두 위임했어요'), findsOneWidget);
    expect(find.text('· 주말 한강 러닝 → 민지님'), findsOneWidget);
    expect(find.text('· 판교 보드게임 → 재호님'), findsOneWidget);

    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();
    expect(find.text('본인 확인'), findsAtLeastNWidgets(1));
  });

  testWidgets('되돌리기를 누르면 위임 전 상태로 돌아간다', (tester) async {
    _sizeView(tester);

    final session = _session(hosted: [_meeting('h1', '주말 한강 러닝')]);
    await tester.pumpWidget(_wrap(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-delegate')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delegate-h1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('candidate-재호')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('재호님에게 위임'));
    await tester.pumpAndSettle();
    expect(find.text('모두 위임했어요'), findsOneWidget);

    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('1개 중 0개 위임했어요'), findsOneWidget);
    expect(find.byKey(const Key('delegate-h1')), findsOneWidget);
  });

  testWidgets('멤버가 나뿐인 모임은 위임 대상에서 빠지고 탈퇴를 막지 않는다', (tester) async {
    _sizeView(tester);

    final session = _session(
      hosted: [_meeting('solo', '혼자 여는 모임', current: 1)],
      candidatesOf: (_) => const [],
    );
    await tester.pumpWidget(_wrap(session));
    await tester.pumpAndSettle();

    // 위임할 게 없으니 경고 카드도 없고 바로 탈퇴가 진행된다.
    expect(session.hostsMeeting, isFalse);
    expect(find.textContaining('방장으로 운영 중인 모임'), findsNothing);

    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();
    expect(find.text('본인 확인'), findsAtLeastNWidgets(1));
  });

  testWidgets('위임 화면은 멤버가 나뿐인 모임을 안내로만 보여준다', (tester) async {
    _sizeView(tester);

    final session = _session(
      hosted: [_meeting('h1', '주말 한강 러닝'), _meeting('solo', '혼자 여는 모임', current: 1)],
      candidatesOf: (m) => m.id == 'solo' ? const [] : _members,
    );
    await tester.pumpWidget(_wrap(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-delegate')));
    await tester.pumpAndSettle();

    // 위임 카드는 h1 하나뿐, solo는 안내 박스에만 나온다.
    expect(find.byKey(const Key('delegate-h1')), findsOneWidget);
    expect(find.byKey(const Key('delegate-solo')), findsNothing);
    expect(find.text('멤버가 나뿐인 모임 1개'), findsOneWidget);
    expect(find.text('넘길 멤버가 없어 위임하지 않아도 돼요. 탈퇴하면 함께 정리돼요.'), findsOneWidget);
    expect(find.text('0/1 위임됨'), findsOneWidget);
  });
}

# 모임 상세 화면 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 모임 카드를 누르면 모임 정보 + 참가자 프로필을 보여주는 상세 화면으로 이동하고, 하단에 "참가 신청하기" CTA를 둔다.

**Architecture:** 가격(`MeetingCost`)·참가자(`Member`) 모델을 추가하고, `Meeting`에 선택 필드(설명·역·가격)를 더한다. 저장소가 상세 필드를 중앙 생성하고 멤버 풀에서 참가자를 결정적으로 제공한다. `MeetingDetailScreen`이 이를 렌더링하고, `MeetingCard` 탭으로 진입한다.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-21-meeting-detail-design.md`

---

## File Structure

| 파일 | 변경 |
|------|------|
| `lib/models/meeting_cost.dart` | 신규: CostType + MeetingCost |
| `lib/models/member.dart` | 신규: Gender + Member |
| `lib/models/meeting.dart` | 선택 필드 description/nearestStation/cost + isFull |
| `lib/data/meeting_repository.dart` | _m 상세필드 생성 + 멤버풀 + participantsOf |
| `lib/features/meeting/meeting_detail_screen.dart` | 신규 |
| `lib/features/meeting/widgets/participant_card.dart` | 신규 |
| `lib/features/home/widgets/meeting_card.dart` | onTap 추가 |
| `lib/features/home/widgets/day_meetings_pager.dart` | 카드 탭 → 상세 push |
| 테스트 | meeting_cost / repository(추가) / meeting_detail_screen / day_meetings_pager(추가) |

---

## Task 1: 가격 모델 (`meeting_cost.dart`)

**Files:**
- Create: `lib/models/meeting_cost.dart`
- Test: `test/meeting_cost_test.dart`

- [ ] **Step 1: 실패 테스트**

`test/meeting_cost_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting_cost.dart';

void main() {
  test('paid shows comma-formatted amount', () {
    expect(const MeetingCost(CostType.paid, amountWon: 10000).display, '10,000원');
  });
  test('non-paid shows the type label', () {
    expect(const MeetingCost(CostType.split).display, '엔빵');
    expect(const MeetingCost(CostType.free).display, '무료');
    expect(const MeetingCost(CostType.hostPays).display, '호스트가 쏨');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_cost_test.dart`
Expected: FAIL — `MeetingCost` 없음.

- [ ] **Step 3: 구현**

`lib/models/meeting_cost.dart`:

```dart
/// 모임 비용 부담 방식.
enum CostType {
  split('엔빵'),
  hostPays('호스트가 쏨'),
  free('무료'),
  paid('유료');

  const CostType(this.label);
  final String label;
}

class MeetingCost {
  const MeetingCost(this.type, {this.amountWon});

  final CostType type;
  final int? amountWon;

  /// 유료면 천단위 콤마 금액, 그 외엔 유형 라벨.
  String get display {
    if (type == CostType.paid && amountWon != null) {
      final s = amountWon.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return '$buf원';
    }
    return type.label;
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/meeting_cost_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/models/meeting_cost.dart test/meeting_cost_test.dart && git commit -m "feat: add MeetingCost"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: 참가자 모델 + 모임 필드 + 저장소 (`member.dart`, `meeting.dart`, `meeting_repository.dart`)

**Files:**
- Create: `lib/models/member.dart`
- Modify: `lib/models/meeting.dart` (필드 추가)
- Modify: `lib/data/meeting_repository.dart` (생성·멤버풀·participantsOf)
- Modify: `test/meeting_repository_test.dart` (participantsOf 테스트 추가)

- [ ] **Step 1: 저장소 테스트 추가(실패 유도)**

`test/meeting_repository_test.dart`의 `void main() {` 안 마지막 `});` 다음(닫는 `}` 직전)에 추가:

```dart
  test('participantsOf returns currentMembers participants, deterministically',
      () {
    final t1 = repo.allMeetings.firstWhere((m) => m.id == 't1'); // cur 4
    final a = repo.participantsOf(t1);
    final b = repo.participantsOf(t1);
    expect(a.length, 4);
    expect(a.map((m) => m.nickname).toList(),
        b.map((m) => m.nickname).toList());
  });

  test('repository meetings get a derived cost and description', () {
    final t1 = repo.allMeetings.firstWhere((m) => m.id == 't1');
    expect(t1.description, isNotEmpty);
    expect(t1.nearestStation, isNotEmpty);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_repository_test.dart`
Expected: FAIL — `participantsOf` 없음.

- [ ] **Step 3: `member.dart` 생성**

```dart
/// 성별.
enum Gender {
  male('남'),
  female('여');

  const Gender(this.label);
  final String label;
}

/// 모임 참가자 프로필.
class Member {
  const Member({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.mannerScore,
    required this.totalActivities,
    required this.timesMetWithMe,
    required this.intro,
  });

  final String nickname;
  final int birthYear;
  final Gender gender;
  final double mannerScore; // 0~5
  final int totalActivities;
  final int timesMetWithMe;
  final String intro;
}
```

- [ ] **Step 4: `meeting.dart` 전체 교체(선택 필드 추가)**

```dart
import 'meeting_category.dart';
import 'meeting_cost.dart';

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.location,
    required this.region,
    required this.locationId,
    required this.currentMembers,
    required this.maxMembers,
    this.description = '',
    this.nearestStation = '',
    this.cost = const MeetingCost(CostType.split),
  });

  final String id;
  final String title;
  final MeetingCategory category;
  final DateTime startTime;
  final String location;

  /// 달력 칩에 쓰는 짧은 지역명(예: "신림").
  final String region;

  /// 장소 카탈로그 노드 id(예: "seoul-line2"). 장소 필터에 사용.
  final String locationId;

  final int currentMembers;
  final int maxMembers;

  /// 상세 화면 정보(저장소가 채움).
  final String description;
  final String nearestStation;
  final MeetingCost cost;

  int get spotsLeft => maxMembers - currentMembers;
  bool get isFull => spotsLeft <= 0;
}
```

- [ ] **Step 5: `meeting_repository.dart` 수정(상세필드 생성 + 멤버풀 + participantsOf)**

(a) 파일 상단 import에 추가:
```dart
import '../models/meeting_cost.dart';
import '../models/member.dart';
```

(b) `_m` 헬퍼를 다음으로 교체(반환 시 description/nearestStation/cost 채움):
```dart
  static Meeting _m(
    String id,
    String title,
    MeetingCategory c,
    DateTime start,
    String location,
    String region,
    String locationId,
    int cur,
    int max,
  ) =>
      Meeting(
        id: id,
        title: title,
        category: c,
        startTime: start,
        location: location,
        region: region,
        locationId: locationId,
        currentMembers: cur,
        maxMembers: max,
        description:
            '$region에서 즐기는 ${c.label} 모임이에요. 부담 없이 신청해 주세요!',
        nearestStation: '$region 인근',
        cost: _costFor(c),
      );

  static MeetingCost _costFor(MeetingCategory c) {
    switch (c) {
      case MeetingCategory.hiking:
      case MeetingCategory.swimming:
        return const MeetingCost(CostType.free);
      case MeetingCategory.escapeRoom:
        return const MeetingCost(CostType.paid, amountWon: 22000);
      case MeetingCategory.etc:
        return const MeetingCost(CostType.hostPays);
      default:
        return const MeetingCost(CostType.split);
    }
  }
```

(c) 클래스 안(예: `meetingsOn` 다음)에 멤버풀과 participantsOf 추가:
```dart
  static const List<Member> _memberPool = [
    Member(nickname: '재호', birthYear: 1996, gender: Gender.male, mannerScore: 4.8, totalActivities: 32, timesMetWithMe: 3, intro: '주말마다 모임 다니는 걸 좋아해요!'),
    Member(nickname: '민지', birthYear: 1999, gender: Gender.female, mannerScore: 4.5, totalActivities: 18, timesMetWithMe: 1, intro: '조용히 즐기는 편이에요 :)'),
    Member(nickname: '수빈', birthYear: 2001, gender: Gender.female, mannerScore: 4.9, totalActivities: 47, timesMetWithMe: 5, intro: '새로운 사람 만나는 거 좋아합니다'),
    Member(nickname: '도윤', birthYear: 1994, gender: Gender.male, mannerScore: 4.2, totalActivities: 12, timesMetWithMe: 0, intro: '처음이라 조금 떨리네요!'),
    Member(nickname: '하늘', birthYear: 1998, gender: Gender.female, mannerScore: 5.0, totalActivities: 60, timesMetWithMe: 8, intro: '모임 자주 열어요. 편하게 오세요'),
    Member(nickname: '준영', birthYear: 1992, gender: Gender.male, mannerScore: 4.6, totalActivities: 25, timesMetWithMe: 2, intro: '맛집·카페 탐방 좋아함'),
    Member(nickname: '서연', birthYear: 2000, gender: Gender.female, mannerScore: 4.7, totalActivities: 21, timesMetWithMe: 1, intro: '운동 모임 위주로 나가요'),
    Member(nickname: '태현', birthYear: 1997, gender: Gender.male, mannerScore: 4.3, totalActivities: 9, timesMetWithMe: 0, intro: '게임·보드게임 환영!'),
  ];

  /// 모임 참가자(결정적). 첫 번째가 호스트.
  List<Member> participantsOf(Meeting m) {
    final n = m.currentMembers.clamp(0, _memberPool.length);
    final offset = m.id.hashCode.abs() % _memberPool.length;
    return List.unmodifiable([
      for (var i = 0; i < n; i++) _memberPool[(offset + i) % _memberPool.length],
    ]);
  }
```

- [ ] **Step 6: 통과 확인 + 전체**

Run: `flutter test test/meeting_repository_test.dart && flutter analyze && flutter test`
Expected: 저장소 테스트 PASS, 분석 No issues, 전체 PASS. (Meeting 새 필드는 선택·기본값이라 기존 직접 생성 테스트 영향 없음)

- [ ] **Step 7: 커밋**

```bash
git add lib/models/member.dart lib/models/meeting.dart lib/data/meeting_repository.dart test/meeting_repository_test.dart && git commit -m "feat: add Member, meeting detail fields, participantsOf"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: 참가자 카드 (`participant_card.dart`)

**Files:**
- Create: `lib/features/meeting/widgets/participant_card.dart`

- [ ] **Step 1: 위젯 작성**

`lib/features/meeting/widgets/participant_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../models/member.dart';
import '../../../theme/app_colors.dart';

class ParticipantCard extends StatelessWidget {
  const ParticipantCard({super.key, required this.member, this.isHost = false});

  final Member member;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final initial = member.nickname.isNotEmpty
        ? member.nickname.substring(0, 1)
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.bgInfo, shape: BoxShape.circle),
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textInfo)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.nickname,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.textInfo,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('HOST',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.star, size: 13, color: Color(0xFFE6A700)),
                    const SizedBox(width: 2),
                    Text(member.mannerScore.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${member.birthYear}년생 · ${member.gender.label}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                    '활동 ${member.totalActivities}회 · 나와 ${member.timesMetWithMe}번 만남',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text(member.intro,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 분석 확인**

Run: `flutter analyze lib/features/meeting/widgets/participant_card.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/meeting/widgets/participant_card.dart && git commit -m "feat: add ParticipantCard"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 4: 상세 화면 (`meeting_detail_screen.dart`)

**Files:**
- Create: `lib/features/meeting/meeting_detail_screen.dart`
- Test: `test/meeting_detail_screen_test.dart`

- [ ] **Step 1: 실패 테스트**

`test/meeting_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/meeting_detail_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('renders meeting info, participants, and join CTA',
      (tester) async {
    final repo = MeetingRepository();
    final meeting = repo.allMeetings.firstWhere((m) => m.id == 't1');
    await tester.pumpWidget(MaterialApp(
      home: MeetingDetailScreen(meeting: meeting, repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('참가 신청하기'), findsOneWidget);
    expect(find.text('수락 시 50 다이아 사용'), findsOneWidget);
    expect(find.text('참가자 4명'), findsOneWidget);
    expect(find.text('모집중'), findsOneWidget);
    expect(find.text('HOST'), findsOneWidget);
    expect(find.textContaining('나와'), findsWidgets);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_detail_screen_test.dart`
Expected: FAIL — `MeetingDetailScreen` 없음.

- [ ] **Step 3: 구현**

`lib/features/meeting/meeting_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../theme/app_colors.dart';
import 'widgets/participant_card.dart';

class MeetingDetailScreen extends StatelessWidget {
  const MeetingDetailScreen({
    super.key,
    required this.meeting,
    required this.repository,
  });

  final Meeting meeting;
  final MeetingRepository repository;

  @override
  Widget build(BuildContext context) {
    final participants = repository.participantsOf(meeting);
    final dateTime =
        DateFormat('y년 M월 d일 (E) HH:mm', 'ko_KR').format(meeting.startTime);
    final spots = meeting.spotsLeft;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.share_outlined, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Icon(Icons.flag_outlined, color: AppColors.textSecondary),
          SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              _categoryChip(),
              const SizedBox(width: 8),
              _statusBadge(meeting.isFull),
            ],
          ),
          const SizedBox(height: 12),
          Text(meeting.title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _infoRow(Icons.schedule, dateTime),
          _infoRow(Icons.location_on_outlined,
              '${meeting.nearestStation} · ${meeting.location}'),
          _infoRow(Icons.payments_outlined, meeting.cost.display),
          _infoRow(Icons.people_outline,
              '${meeting.currentMembers}/${meeting.maxMembers}명 · ${spots > 0 ? '$spots자리 남음' : '마감'}'),
          const SizedBox(height: 16),
          Text(meeting.description,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderTertiary, height: 1),
          const SizedBox(height: 16),
          Text('참가자 ${participants.length}명',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (var i = 0; i < participants.length; i++)
            ParticipantCard(member: participants[i], isHost: i == 0),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {},
                  child: const Text('참가 신청하기',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond, size: 13, color: AppColors.textInfo),
                  SizedBox(width: 4),
                  Text('수락 시 50 다이아 사용',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: meeting.category.chipBackground,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meeting.category.icon,
                size: 14, color: meeting.category.chipForeground),
            const SizedBox(width: 4),
            Text(meeting.category.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: meeting.category.chipForeground)),
          ],
        ),
      );

  Widget _statusBadge(bool full) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: full ? AppColors.bgTertiary : AppColors.bgSuccess,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(full ? '마감' : '모집중',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: full ? AppColors.textSecondary : AppColors.textSuccess)),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary))),
          ],
        ),
      );
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/meeting_detail_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/meeting/meeting_detail_screen.dart test/meeting_detail_screen_test.dart && git commit -m "feat: add MeetingDetailScreen"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 5: 카드 탭 → 상세 진입 (`meeting_card.dart`, `day_meetings_pager.dart`)

**Files:**
- Modify: `lib/features/home/widgets/meeting_card.dart` (onTap 추가)
- Modify: `lib/features/home/widgets/day_meetings_pager.dart` (push)
- Modify: `test/day_meetings_pager_test.dart` (탭→상세 테스트)

- [ ] **Step 1: 카드 탭 테스트 추가(실패 유도)**

`test/day_meetings_pager_test.dart` 상단 import에 추가:
```dart
import 'package:moija/features/meeting/meeting_detail_screen.dart';
```
그리고 `void main() {` 안 마지막 `});` 다음(닫는 `}` 직전)에 추가:

```dart
  testWidgets('tapping a meeting card opens the detail screen',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onDayChanged: (_) {},
        ),
      ),
    ));

    await tester.tap(find.text('퇴근 후 볼링'));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailScreen), findsOneWidget);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/day_meetings_pager_test.dart`
Expected: FAIL — 카드 탭에 동작 없음(상세 미표시).

- [ ] **Step 3: `meeting_card.dart`에 onTap 추가**

`lib/features/home/widgets/meeting_card.dart`:
(a) 생성자/필드:
```dart
  const MeetingCard({super.key, required this.meeting, this.onTap});

  final Meeting meeting;
  final VoidCallback? onTap;
```
(b) `build`의 `return Container(...)`를 `GestureDetector`로 감싼다:
```dart
  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(meeting.startTime);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // ... 기존 Container 내용 그대로 ...
      ),
    );
  }
```
(나머지 Container/Row/_spotsLabel은 그대로 둔다.)

- [ ] **Step 4: `day_meetings_pager.dart`에서 push 연결**

(a) import 추가:
```dart
import '../../meeting/meeting_detail_screen.dart';
```
(b) `itemBuilder`의 `MeetingCard(meeting: m)`를 다음으로 변경:
```dart
                children: [
                  for (final m in meetings)
                    MeetingCard(
                      meeting: m,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailScreen(
                              meeting: m, repository: widget.repository),
                        ),
                      ),
                    ),
                ],
```

- [ ] **Step 5: 통과 확인 + 전체**

Run: `flutter test test/day_meetings_pager_test.dart && flutter analyze && flutter test`
Expected: 카드 탭 테스트 PASS, 분석 No issues, 전체 PASS.

- [ ] **Step 6: 커밋**

```bash
git add lib/features/home/widgets/meeting_card.dart lib/features/home/widgets/day_meetings_pager.dart test/day_meetings_pager_test.dart && git commit -m "feat: open meeting detail on card tap"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시): 모임 카드 탭 → 상세(제목·카테고리·설명·가격·장소·일시·인원·모집상태 + 참가자 프로필 + 호스트 배지) → 하단 "참가 신청하기" / "수락 시 50 다이아 사용".

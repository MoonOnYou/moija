# 당기기 새로고침 + 시간순 정렬 + 모임 데이터 추가 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 모임 리스트에 당기기 새로고침을 넣고, 모임을 시작 시각 순으로 정렬하며, 5~6월에 다양한 모임을 추가한다.

**Architecture:** `meetingsOn`이 시간순 정렬해 반환하고 시드를 확충한다. `DayMeetingsPager`는 선택적 `onRefresh`가 있으면 각 페이지를 `RefreshIndicator`로 감싼다. 홈이 새로고침 콜백(지연 후 setState)을 제공한다.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-21-pull-refresh-and-data-design.md`
**고정 "오늘":** 2026-05-16.

> 제약: 기존 테스트가 의존하는 5/16·5/17·5/19 모임은 변경/추가하지 않는다.

---

## Task 1: 시간순 정렬 + 모임 데이터 추가 (`meeting_repository.dart`)

**Files:**
- Modify: `lib/data/meeting_repository.dart` (전체 교체)
- Modify: `test/meeting_repository_test.dart` (전체 교체)

- [ ] **Step 1: 테스트 전체 교체(실패 유도)**

`test/meeting_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';

void main() {
  final repo = MeetingRepository();

  test('meetingsOn returns the day sorted by start time', () {
    final may20 = repo.meetingsOn(DateTime(2026, 5, 20));
    final times = may20.map((m) => m.startTime).toList();
    final sorted = [...times]..sort();
    expect(times, sorted);
    expect(may20.length, greaterThan(1));
  });

  test('meetingsOn 5/19 has 2 meetings, earliest first', () {
    final may19 = repo.meetingsOn(DateTime(2026, 5, 19));
    expect(may19, hasLength(2));
    expect(may19.first.title, '코노 1시간'); // 19:00 < 20:00
  });

  test('meetingsOn returns empty list for a day with no meetings', () {
    expect(repo.meetingsOn(DateTime(2026, 5, 11)), isEmpty);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_repository_test.dart`
Expected: FAIL — 정렬 미적용이라 5/19 first가 '방탈출 호러 테마 같이!'.

- [ ] **Step 3: 저장소 전체 교체(정렬 + 데이터 추가)**

`lib/data/meeting_repository.dart`:

```dart
import '../models/meeting.dart';
import '../models/meeting_category.dart';

/// 인메모리 목 데이터 저장소.
class MeetingRepository {
  MeetingRepository() {
    _byDay = {};
    for (final m in _seed) {
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
  }

  late final Map<DateTime, List<Meeting>> _byDay;

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Meeting> get allMeetings => List.unmodifiable(_seed);

  /// 해당 날짜 모임을 시작 시각 오름차순으로 반환한다.
  List<Meeting> meetingsOn(DateTime day) {
    final list = [...?_byDay[_key(day)]];
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return List.unmodifiable(list);
  }

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
      );

  static final List<Meeting> _seed = [
    // --- 기존 시드 (변경 금지: 5/16·5/17·5/19) ---
    _m('p1', '아침 코딩 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 12, 9, 0), '신림 스타벅스', '신림', 'seoul-line2', 2, 5),
    _m('p2', '공포 테마 도전', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 14, 20, 0), '강남 비밀의방', '강남', 'seoul-line2', 3, 4),
    _m('t1', '퇴근 후 볼링', MeetingCategory.bowling,
        DateTime(2026, 5, 16, 20, 0), '신림 볼링장', '신림', 'seoul-line2', 4, 6),
    _m('t2', '불금 한잔', MeetingCategory.drink,
        DateTime(2026, 5, 16, 21, 0), '신림 포차거리', '신림', 'seoul-line2', 3, 6),
    _m('a1', '주말 관악산 등반', MeetingCategory.hiking,
        DateTime(2026, 5, 17, 8, 0), '관악산 입구', '신림', 'seoul-line2', 5, 10),
    _m('b1', '방탈출 호러 테마 같이!', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 19, 20, 0), '강남 비밀의방', '강남', 'seoul-line2', 2, 4),
    _m('b2', '코노 1시간', MeetingCategory.karaoke,
        DateTime(2026, 5, 19, 19, 0), '신림 코인노래방', '신림', 'seoul-line2', 2, 6),
    _m('c1', '보드게임 정모', MeetingCategory.boardGame,
        DateTime(2026, 5, 20, 19, 0), '신림 보드카페', '신림', 'seoul-line2', 3, 6),
    _m('c2', '롤 한판', MeetingCategory.lol,
        DateTime(2026, 5, 20, 20, 0), '신림 PC방', '신림', 'seoul-line2', 4, 5),
    _m('c3', '심야 모임', MeetingCategory.etc,
        DateTime(2026, 5, 20, 22, 0), '신림 어딘가', '신림', 'seoul-line2', 2, 4),
    _m('c4', '라떼 한잔', MeetingCategory.cafe,
        DateTime(2026, 5, 20, 15, 0), '신림 카페거리', '신림', 'seoul-line2', 1, 4),
    _m('c5', '소맥 모임', MeetingCategory.drink,
        DateTime(2026, 5, 20, 21, 0), '신림 술집', '신림', 'seoul-line2', 5, 8),
    _m('c6', '노래방 직행', MeetingCategory.karaoke,
        DateTime(2026, 5, 20, 23, 0), '신림 노래타운', '신림', 'seoul-line2', 2, 6),
    _m('d1', '수영 모임', MeetingCategory.swimming,
        DateTime(2026, 5, 21, 7, 0), '강남 수영장', '강남', 'seoul-line2', 3, 5),
    _m('e1', '오후 카페 수다', MeetingCategory.cafe,
        DateTime(2026, 5, 22, 14, 0), '홍대 카페', '홍대', 'seoul-line2', 2, 4),
    _m('f1', '토요 볼링 정모', MeetingCategory.bowling,
        DateTime(2026, 5, 23, 18, 0), '잠실 볼링센터', '잠실', 'seoul-line2', 5, 8),

    // --- 추가 (이번달 후반·다음달, 필터 테스트용) ---
    _m('n1', '서면 코인노래방', MeetingCategory.karaoke,
        DateTime(2026, 5, 21, 19, 0), '부산 서면', '서면', 'busan-line2', 2, 6),
    _m('n2', '광교산 등반', MeetingCategory.hiking,
        DateTime(2026, 5, 21, 6, 30), '수원 광교산', '수원', '경기-수원시', 4, 10),
    _m('n3', '판교 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 5, 22, 20, 0), '성남 판교', '판교', '경기-성남시', 3, 6),
    _m('n4', '부산 PC방 정모', MeetingCategory.lol,
        DateTime(2026, 5, 23, 22, 0), '부산 남포동', '남포', 'busan-line1', 4, 5),
    _m('n5', '제주 오션뷰 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 23, 10, 0), '제주 애월', '애월', '제주-제주시', 2, 4),
    _m('n6', '대구 방탈출', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 25, 13, 0), '대구 동성로', '동성로', 'daegu-line1', 3, 6),
    _m('n7', '강남 포차 한잔', MeetingCategory.drink,
        DateTime(2026, 5, 26, 21, 0), '강남 포차', '강남', 'seoul-line2', 5, 8),
    _m('n8', '인천 새벽 수영', MeetingCategory.swimming,
        DateTime(2026, 5, 27, 8, 0), '인천 수영장', '인천', 'incheon-line1', 2, 6),
    _m('n9', '광화문 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 5, 28, 19, 30), '광화문', '광화문', 'seoul-line5', 3, 6),
    _m('n10', '창원 무학산', MeetingCategory.hiking,
        DateTime(2026, 5, 28, 7, 0), '창원 무학산', '창원', '경남-창원시', 6, 12),
    _m('n11', '신촌 심야 코노', MeetingCategory.karaoke,
        DateTime(2026, 5, 29, 23, 0), '신촌', '신촌', 'seoul-line2', 4, 8),
    _m('n12', '청주 디저트 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 30, 15, 0), '청주', '청주', '충북-청주시', 2, 5),
    _m('n13', '광주 롤 모임', MeetingCategory.lol,
        DateTime(2026, 5, 31, 20, 0), '광주 충장로', '충장로', 'gwangju-line1', 3, 5),
    _m('n14', '압구정 방탈출', MeetingCategory.escapeRoom,
        DateTime(2026, 6, 1, 14, 0), '압구정', '압구정', 'seoul-line3', 2, 6),
    _m('n15', '수원 점심 볼링', MeetingCategory.bowling,
        DateTime(2026, 6, 2, 12, 30), '수원역', '수원', '경기-수원시', 4, 8),
    _m('n16', '광안리 술 한잔', MeetingCategory.drink,
        DateTime(2026, 6, 3, 20, 0), '부산 광안리', '광안리', 'busan-line2', 4, 8),
    _m('n17', '춘천 삼악산', MeetingCategory.hiking,
        DateTime(2026, 6, 5, 6, 30), '춘천 삼악산', '춘천', '강원-춘천시', 5, 10),
    _m('n18', '대전 주말 볼링', MeetingCategory.bowling,
        DateTime(2026, 6, 7, 17, 0), '대전 둔산', '둔산', 'daejeon-line1', 4, 8),
    _m('n19', '여의도 브런치 카페', MeetingCategory.cafe,
        DateTime(2026, 6, 10, 11, 0), '여의도', '여의도', 'seoul-line9', 2, 4),
    _m('n20', '일산 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 6, 12, 19, 0), '고양 일산', '일산', '경기-고양시', 3, 6),
    _m('n21', '주말 수영 클래스', MeetingCategory.swimming,
        DateTime(2026, 6, 14, 9, 0), '강남 수영장', '강남', 'seoul-line7', 2, 6),
    _m('n22', '대구 밤 코노', MeetingCategory.karaoke,
        DateTime(2026, 6, 16, 22, 0), '대구 반월당', '반월당', 'daegu-line2', 3, 8),
    _m('n23', '인천 번개 모임', MeetingCategory.etc,
        DateTime(2026, 6, 20, 18, 0), '인천 송도', '송도', 'incheon-line2', 2, 4),
    _m('n24', '강남 심야 롤', MeetingCategory.lol,
        DateTime(2026, 6, 25, 21, 0), '강남 PC방', '강남', 'seoul-line2', 5, 5),
    _m('n25', '서귀포 한잔', MeetingCategory.drink,
        DateTime(2026, 6, 28, 20, 30), '서귀포', '서귀포', '제주-서귀포시', 3, 6),
  ];
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/meeting_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: 전체 테스트 확인(정렬·추가 영향 없음)**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 전체 PASS. (5/16·5/17·5/19 불변이라 home_screen_test 등 유지)

- [ ] **Step 6: 커밋**

```bash
git add lib/data/meeting_repository.dart test/meeting_repository_test.dart && git commit -m "feat: sort meetings by start time + add May/June mock meetings"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: 당기기 새로고침 (`day_meetings_pager.dart`)

**Files:**
- Modify: `lib/features/home/widgets/day_meetings_pager.dart` (전체 교체)
- Modify: `test/day_meetings_pager_test.dart` (테스트 추가)

- [ ] **Step 1: 새로고침 테스트 추가(실패 유도)**

`test/day_meetings_pager_test.dart`의 `void main() {` 안, 마지막 `});` 다음(닫는 `}` 직전)에 추가한다(기존 테스트·`_Host`·import 유지):

```dart
  testWidgets('pull-to-refresh invokes onRefresh', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onRefresh: () async {
            called = true;
          },
          onDayChanged: (_) {},
        ),
      ),
    ));

    await tester.fling(find.byType(ListView).first, const Offset(0, 350), 1200);
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/day_meetings_pager_test.dart`
Expected: FAIL — `onRefresh` 명명 인자 없음(컴파일 에러).

- [ ] **Step 3: 위젯 전체 교체**

`lib/features/home/widgets/day_meetings_pager.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../models/meeting_filter.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'meeting_card.dart';

/// 모임 리스트를 가로 스와이프로 날짜 단위 전환하는 페이저.
/// 왼쪽 스와이프=다음 날, 오른쪽=이전 날(오늘에서 멈춤).
/// [onRefresh]가 주어지면 각 페이지를 당겨서 새로고침할 수 있다.
class DayMeetingsPager extends StatefulWidget {
  const DayMeetingsPager({
    super.key,
    required this.selectedDay,
    required this.today,
    required this.repository,
    this.filter = const MeetingFilter.empty(),
    this.onRefresh,
    required this.onDayChanged,
  });

  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final MeetingFilter filter;
  final Future<void> Function()? onRefresh;
  final ValueChanged<DateTime> onDayChanged;

  @override
  State<DayMeetingsPager> createState() => _DayMeetingsPagerState();
}

class _DayMeetingsPagerState extends State<DayMeetingsPager> {
  // page 0 = 오늘. 음수 페이지가 없어 오늘 이전으로 스와이프 불가.
  late final DateTime _epoch =
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.selectedDay));

  int _pageOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.difference(_epoch).inDays;
  }

  DateTime _dateOf(int page) => _epoch.add(Duration(days: page));

  @override
  void didUpdateWidget(DayMeetingsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(달력 탭)에서 선택일이 바뀌면 즉시 이동(중간 페이지 휩쓸기 방지).
    final target = _pageOf(widget.selectedDay);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.jumpToPage(target);
    }
  }

  void _onPageChanged(int page) {
    final day = _dateOf(page);
    if (!isSameDay(day, widget.selectedDay)) {
      widget.onDayChanged(day);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, page) {
        final meetings = widget.repository
            .meetingsOn(_dateOf(page))
            .where(widget.filter.matches)
            .toList();

        final Widget list = meetings.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 120), _EmptyDay()],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [for (final m in meetings) MeetingCard(meeting: m)],
              );

        final onRefresh = widget.onRefresh;
        if (onRefresh == null) return list;
        return RefreshIndicator(onRefresh: onRefresh, child: list);
      },
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '이 날에는 모임이 없어요',
        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
      ),
    );
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/day_meetings_pager_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/widgets/day_meetings_pager.dart test/day_meetings_pager_test.dart && git commit -m "feat: pull-to-refresh on the day meeting list"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: 홈 새로고침 배선 (`home_screen.dart`)

**Files:**
- Modify: `lib/features/home/home_screen.dart`

- [ ] **Step 1: `_refresh` 추가 + 페이저에 전달**

`lib/features/home/home_screen.dart`에서:

(a) `_openFilter` 메서드 다음에 새 메서드를 추가한다:

```dart
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() {});
  }
```

(b) `DayMeetingsPager(...)` 호출에 `onRefresh: _refresh,`를 추가한다(`filter: _filter,` 다음 줄):

```dart
              child: DayMeetingsPager(
                selectedDay: _selectedDay,
                today: _today,
                repository: _repository,
                filter: _filter,
                onRefresh: _refresh,
                onDayChanged: _goToDay,
              ),
```

- [ ] **Step 2: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 전체 PASS.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/home_screen.dart && git commit -m "feat: wire pull-to-refresh into home"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시): 모임 리스트를 아래로 당기면 스피너 후 새로고침; 같은 날 모임이 시각 순; 필터에서 5~6월의 다양한 카테고리·장소·시간대 모임으로 테스트.

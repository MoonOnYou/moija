# 모임 리스트 좌우 스와이프 날짜 이동 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 달력 아래 모임 리스트를 좌우 스와이프하면 이전/다음 날짜 리스트로 슬라이드 전환되고, 선택일이 2주 창 밖으로 나가면 달력 창이 따라 이동한다.

**Architecture:** 리스트 영역을 `PageView.builder` 기반 `DayMeetingsPager`로 교체(페이지↔날짜 매핑). 달력 탭과 리스트 스와이프를 `home_screen`의 단일 `_goToDay`로 통일하고, 창 따라가기는 `calendar_grid`의 순수 함수 `windowFollowing`으로 처리한다.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-list-swipe-day-nav-design.md`
**고정 "오늘":** 2026-05-16. 초기 창 시작(일요일) = 2026-05-10.

---

## File Structure

| 파일 | 변경 |
|------|------|
| `lib/features/home/calendar_grid.dart` | `windowFollowing` 순수 함수 추가 |
| `lib/features/home/widgets/day_meetings_pager.dart` | 신규: PageView 기반 날짜 페이저 |
| `lib/features/home/home_screen.dart` | `_goToDay` 통일 + 페이저 사용 + `_EmptyState` 제거 |
| `test/calendar_grid_test.dart` | `windowFollowing` 테스트 추가 |
| `test/day_meetings_pager_test.dart` | 신규 |
| `test/home_screen_test.dart` | 리스트 스와이프 테스트 추가 |

---

## Task 1: 창 따라가기 순수 함수 (`windowFollowing`)

**Files:**
- Modify: `lib/features/home/calendar_grid.dart` (함수 추가)
- Modify: `test/calendar_grid_test.dart` (그룹 추가)

- [ ] **Step 1: 실패하는 테스트 추가**

`test/calendar_grid_test.dart`의 `void main() {` 바로 다음 줄에 아래 그룹을 추가한다(기존 그룹들은 그대로 둔다):

```dart
  group('windowFollowing', () {
    // 초기 창: 2026-05-10(일) ~ 2026-05-23(토)
    final start = DateTime(2026, 5, 10);

    test('keeps the window when the day is inside it', () {
      expect(windowFollowing(start, DateTime(2026, 5, 16)), start);
      expect(windowFollowing(start, DateTime(2026, 5, 23)), start);
    });

    test('shifts forward by a week when the day is past the end', () {
      // 5/24는 창 끝(5/23) 다음 → +7 → 5/17(일)
      final w = windowFollowing(start, DateTime(2026, 5, 24));
      expect(w, DateTime(2026, 5, 17));
      expect(w.weekday, DateTime.sunday);
    });

    test('shifts backward by a week when the day is before the start', () {
      // 5/9는 창 시작(5/10) 이전 → -7 → 5/3(일)
      final w = windowFollowing(start, DateTime(2026, 5, 9));
      expect(w, DateTime(2026, 5, 3));
      expect(w.weekday, DateTime.sunday);
    });

    test('shifts multiple weeks when the day is far outside', () {
      // 6/7은 +14일 이상 → 두 번 이동 → 5/31(일), 창 5/31~6/13에 포함
      final w = windowFollowing(start, DateTime(2026, 6, 7));
      expect(w, DateTime(2026, 5, 31));
    });
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: FAIL — `windowFollowing` 정의되지 않음.

- [ ] **Step 3: 함수 추가**

`lib/features/home/calendar_grid.dart` 끝에 아래 함수를 추가한다(기존 함수는 그대로 둔다):

```dart
/// 선택일이 2주 창 [windowStart, windowStart+13] 안에 들어오도록
/// windowStart를 7일 단위로 이동시켜 반환한다. windowStart가 일요일이면
/// 결과도 항상 일요일을 유지한다.
DateTime windowFollowing(DateTime windowStart, DateTime selectedDay) {
  var w = DateTime(windowStart.year, windowStart.month, windowStart.day);
  final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
  while (d.isBefore(w)) {
    w = w.subtract(const Duration(days: 7));
  }
  while (d.isAfter(w.add(const Duration(days: 13)))) {
    w = w.add(const Duration(days: 7));
  }
  return w;
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: PASS (기존 + windowFollowing 4개).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/calendar_grid.dart test/calendar_grid_test.dart && git commit -m "feat: add windowFollowing helper"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: 날짜 페이저 위젯 (`day_meetings_pager.dart`)

**Files:**
- Create: `lib/features/home/widgets/day_meetings_pager.dart`
- Test: `test/day_meetings_pager_test.dart`

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

`test/day_meetings_pager_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Future<DateTime?> _swipe(WidgetTester tester, Offset offset) async {
    DateTime? changed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onDayChanged: (d) => changed = d,
        ),
      ),
    ));
    await tester.fling(find.byType(PageView), offset, 1000);
    await tester.pumpAndSettle();
    return changed;
  }

  testWidgets('swiping left advances to the next day', (tester) async {
    final changed = await _swipe(tester, const Offset(-400, 0));
    expect(changed, DateTime(2026, 5, 17));
  });

  testWidgets('swiping right goes to the previous day', (tester) async {
    final changed = await _swipe(tester, const Offset(400, 0));
    expect(changed, DateTime(2026, 5, 15));
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/day_meetings_pager_test.dart`
Expected: FAIL — `DayMeetingsPager` 없음.

- [ ] **Step 3: 위젯 작성**

`lib/features/home/widgets/day_meetings_pager.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'meeting_card.dart';

/// 모임 리스트를 가로 스와이프로 날짜 단위 전환하는 페이저.
/// 왼쪽 스와이프=다음 날, 오른쪽=이전 날.
class DayMeetingsPager extends StatefulWidget {
  const DayMeetingsPager({
    super.key,
    required this.selectedDay,
    required this.repository,
    required this.onDayChanged,
  });

  final DateTime selectedDay;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDayChanged;

  @override
  State<DayMeetingsPager> createState() => _DayMeetingsPagerState();
}

class _DayMeetingsPagerState extends State<DayMeetingsPager> {
  // 페이지 인덱스 ↔ 날짜 매핑 기준.
  static final DateTime _epoch = DateTime(2026, 5, 16);
  static const int _basePage = 100000;

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.selectedDay));

  static int _pageOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return _basePage + day.difference(_epoch).inDays;
  }

  static DateTime _dateOf(int page) =>
      _epoch.add(Duration(days: page - _basePage));

  @override
  void didUpdateWidget(DayMeetingsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(달력 탭)에서 선택일이 바뀌면 해당 페이지로 애니메이션 이동.
    final target = _pageOf(widget.selectedDay);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
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
        final meetings = widget.repository.meetingsOn(_dateOf(page));
        if (meetings.isEmpty) return const _EmptyDay();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [for (final m in meetings) MeetingCard(meeting: m)],
        );
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
Expected: PASS (2 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/widgets/day_meetings_pager.dart test/day_meetings_pager_test.dart && git commit -m "feat: add DayMeetingsPager with swipe day navigation"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: 홈 화면 통합 (`home_screen.dart`) + 테스트

**Files:**
- Modify: `lib/features/home/home_screen.dart` (전체 교체)
- Modify: `test/home_screen_test.dart` (전체 교체)

- [ ] **Step 1: 홈 화면 테스트 전체 교체(실패 확인용 — 새 스와이프 테스트 포함)**

`test/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';
import 'package:moija/features/home/widgets/two_week_calendar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  }

  testWidgets('shows the single-month label for the initial window',
      (tester) async {
    await pump(tester);
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('tapping a day updates the meeting list', (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('selecting an empty day shows the empty state', (tester) async {
    await pump(tester);
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text('모임 0개'), findsOneWidget);
    expect(find.text('이 날에는 모임이 없어요'), findsOneWidget);
  });

  testWidgets('swiping the calendar pages the window by two weeks',
      (tester) async {
    await pump(tester);
    await tester.fling(
        find.byType(TwoWeekCalendar), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2026년 5–6월'), findsOneWidget);
  });

  testWidgets('past days are dimmed', (tester) async {
    await pump(tester);
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.45),
      findsWidgets,
    );
  });

  testWidgets('swiping the meeting list moves to the next day',
      (tester) async {
    await pump(tester);
    // 초기 선택일 5/16 → "퇴근 후 볼링".
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    await tester.fling(
        find.byType(DayMeetingsPager), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    // 5/17 → 요약과 리스트가 갱신.
    expect(find.textContaining('5월 17일'), findsOneWidget);
    expect(find.text('주말 관악산 등반'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — `DayMeetingsPager` 미사용/미import (HomeScreen이 아직 리스트를 직접 그림).

- [ ] **Step 3: 홈 화면 전체 교체**

`lib/features/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../theme/app_colors.dart';
import 'calendar_grid.dart';
import 'widgets/day_meetings_pager.dart';
import 'widgets/filter_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/selected_day_summary.dart';
import 'widgets/two_week_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 목 데이터의 고정 "오늘".
  static final DateTime _today = DateTime(2026, 5, 16);

  final MeetingRepository _repository = MeetingRepository();
  late DateTime _windowStart = weekStartOf(_today);
  late DateTime _selectedDay = _today;

  /// 달력 탭과 리스트 스와이프 공통 진입점.
  void _goToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _windowStart = windowFollowing(_windowStart, day);
    });
  }

  void _shiftWindow(int days) {
    setState(() => _windowStart = _windowStart.add(Duration(days: days)));
  }

  String _monthLabel() {
    final days = twoWeekGridFrom(_windowStart);
    final first = days.first;
    final last = days.last;
    if (first.month == last.month) {
      return DateFormat('y년 M월', 'ko_KR').format(first);
    }
    // 두 달에 걸치면 "2026년 5–6월" 형태.
    return '${first.year}년 ${first.month}–${last.month}월';
  }

  @override
  Widget build(BuildContext context) {
    final dayMeetings = _repository.meetingsOn(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(monthLabel: _monthLabel()),
            const SizedBox(height: 8),
            const FilterBar(),
            TwoWeekCalendar(
              windowStart: _windowStart,
              selectedDay: _selectedDay,
              today: _today,
              repository: _repository,
              onDaySelected: _goToDay,
              onWindowDelta: _shiftWindow,
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _selectedDay,
                repository: _repository,
                onDayChanged: _goToDay,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.bgPrimary,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

주: 기존의 `_EmptyState`/`MeetingCard` 직접 사용은 제거된다(빈 상태·카드는 `DayMeetingsPager`가 담당). import에서 `meeting_card.dart`는 더 이상 필요 없다.

- [ ] **Step 4: 홈 화면 테스트 통과 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 "No issues found!", 모든 테스트 PASS.

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "feat: swipe meeting list to change day, window follows selection"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시) 시각 확인: 리스트를 좌우로 스와이프하면 슬라이드 애니메이션과 함께 이전/다음 날짜 리스트로 전환되고, 위 요약·달력 강조가 함께 갱신되며, 선택일이 2주 창 밖으로 나가면 달력이 따라 이동한다.

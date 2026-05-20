# 달력/리스트 내비게이션 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 달력 탭 전환 jank 제거(jumpToPage), 오늘 이전 날짜 선택·스와이프 차단, 달력 좌우 스와이프에 슬라이드 애니메이션(PageView) 적용.

**Architecture:** 리스트 페이저는 page0=오늘으로 바운드하고 외부 변경 시 jumpToPage. 달력은 2주 윈도우 PageView(page0=오늘 주)로 전환해 네이티브 슬라이드 + 과거 차단. windowFollowing은 14일 단위로 페이지 정렬. 과거 날짜 셀은 onTap=null.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-calendar-nav-polish-design.md`
**고정 "오늘":** 2026-05-16. 오늘 주 시작(일요일) = 2026-05-10.

> 주의: T3·T4는 `home_screen.dart`가 아직 옛 인터페이스를 호출하므로 **전체** `flutter analyze`/`flutter test`가 깨진다. 해당 태스크는 **지정된 단일 파일만** 분석/테스트한다. 전체 검증은 T5에서 수행한다.

---

## File Structure

| 파일 | 변경 |
|------|------|
| `lib/features/home/calendar_grid.dart` | `windowFollowing` 7→14일 |
| `lib/features/home/widgets/day_cell.dart` | `onTap` → `VoidCallback?` |
| `lib/features/home/widgets/day_meetings_pager.dart` | `today` 추가, page0=today, jumpToPage |
| `lib/features/home/widgets/two_week_calendar.dart` | PageView 윈도우(Stateful), `onWindowChanged` |
| `lib/features/home/home_screen.dart` | 배선 갱신 |
| `test/calendar_grid_test.dart` | windowFollowing 14일 기대값 |
| `test/day_meetings_pager_test.dart` | today/차단/회귀 |
| `test/home_screen_test.dart` | 과거탭·과거창 차단 추가 |

---

## Task 1: windowFollowing 14일 단위 (`calendar_grid.dart`)

**Files:**
- Modify: `lib/features/home/calendar_grid.dart`
- Modify: `test/calendar_grid_test.dart` (windowFollowing 그룹 교체)

- [ ] **Step 1: windowFollowing 테스트 그룹 교체(실패 유도)**

`test/calendar_grid_test.dart`에서 기존 `group('windowFollowing', ...)` 블록 전체를 아래로 교체한다(다른 그룹은 그대로):

```dart
  group('windowFollowing', () {
    final start = DateTime(2026, 5, 10);

    test('keeps the window when the day is inside it', () {
      expect(windowFollowing(start, DateTime(2026, 5, 16)), start);
      expect(windowFollowing(start, DateTime(2026, 5, 23)), start);
    });

    test('shifts forward by two weeks when the day is past the end', () {
      // 5/24는 [5/10,5/23] 다음 → +14 → 5/24
      final w = windowFollowing(start, DateTime(2026, 5, 24));
      expect(w, DateTime(2026, 5, 24));
      expect(w.weekday, DateTime.sunday);
    });

    test('shifts backward by two weeks when the day is before the start', () {
      // 5/23은 [5/24,6/6] 이전 → -14 → 5/10
      final w = windowFollowing(DateTime(2026, 5, 24), DateTime(2026, 5, 23));
      expect(w, DateTime(2026, 5, 10));
      expect(w.weekday, DateTime.sunday);
    });

    test('shifts multiple windows when the day is far ahead', () {
      // 6/7: 5/10→+14→5/24→+14→6/7
      expect(windowFollowing(start, DateTime(2026, 6, 7)), DateTime(2026, 6, 7));
    });
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: FAIL — 7일 단위 동작이라 14일 기대값과 불일치.

- [ ] **Step 3: 함수 수정**

`lib/features/home/calendar_grid.dart`의 `windowFollowing` 함수 본문에서 두 `Duration(days: 7)`을 `Duration(days: 14)`로 바꾼다. 최종 함수는 다음과 같다:

```dart
/// 선택일이 2주 창 [windowStart, windowStart+13] 안에 들어오도록
/// windowStart를 14일(2주) 단위로 이동시켜 반환한다. windowStart가 일요일이면
/// 결과도 항상 일요일을 유지하고, 2주 페이지 그리드에 정렬된다.
DateTime windowFollowing(DateTime windowStart, DateTime selectedDay) {
  var w = DateTime(windowStart.year, windowStart.month, windowStart.day);
  final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
  while (d.isBefore(w)) {
    w = w.subtract(const Duration(days: 14));
  }
  while (d.isAfter(w.add(const Duration(days: 13)))) {
    w = w.add(const Duration(days: 14));
  }
  return w;
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: PASS (전체).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/calendar_grid.dart test/calendar_grid_test.dart && git commit -m "feat: windowFollowing shifts by two-week pages"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: DayCell onTap nullable (`day_cell.dart`)

**Files:**
- Modify: `lib/features/home/widgets/day_cell.dart`

과거 날짜 탭 무반응을 위해 `onTap`을 nullable로 만든다. `GestureDetector`는 `onTap`이 null이면 탭에 반응하지 않는다.

- [ ] **Step 1: 타입 변경**

`lib/features/home/widgets/day_cell.dart`에서 필드 선언을 변경한다:

```dart
  final VoidCallback? onTap;
```

(생성자의 `required this.onTap`은 그대로 둔다 — null을 명시적으로 전달받는다. `GestureDetector(onTap: onTap, ...)` 부분은 수정 불필요.)

- [ ] **Step 2: 단일 파일 분석**

Run: `flutter analyze lib/features/home/widgets/day_cell.dart`
Expected: No issues.

- [ ] **Step 3: 기존 셀 테스트 통과 확인**

Run: `flutter test test/day_cell_test.dart`
Expected: PASS (2 tests — 기존 테스트는 non-null 콜백을 넘기므로 영향 없음).

- [ ] **Step 4: 커밋**

```bash
git add lib/features/home/widgets/day_cell.dart && git commit -m "feat: allow DayCell.onTap to be null (non-tappable cells)"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: DayMeetingsPager — today 바운드 + jumpToPage (`day_meetings_pager.dart`)

**Files:**
- Modify: `lib/features/home/widgets/day_meetings_pager.dart` (전체 교체)
- Modify: `test/day_meetings_pager_test.dart` (전체 교체)

> 단일 파일만 테스트한다(`home_screen.dart`는 T5까지 깨진 상태).

- [ ] **Step 1: 테스트 전체 교체(실패 유도)**

`test/day_meetings_pager_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onDayChanged});
  final ValueChanged<DateTime> onDayChanged;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  DateTime _sel = DateTime(2026, 5, 16);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () => setState(() => _sel = DateTime(2026, 5, 20)),
              child: const Text('go'),
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _sel,
                today: DateTime(2026, 5, 16),
                repository: MeetingRepository(),
                onDayChanged: widget.onDayChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Future<DateTime?> swipe(WidgetTester tester, Offset offset) async {
    DateTime? changed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 16),
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
    expect(await swipe(tester, const Offset(-400, 0)), DateTime(2026, 5, 17));
  });

  testWidgets('cannot swipe before today', (tester) async {
    expect(await swipe(tester, const Offset(400, 0)), isNull);
  });

  testWidgets('external multi-day change does not fire intermediate days',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(_Host(onDayChanged: changes.add));
    await tester.tap(find.text('go')); // selectedDay 5/16 → 5/20
    await tester.pumpAndSettle();
    final intermediates = changes.where((d) =>
        d == DateTime(2026, 5, 17) ||
        d == DateTime(2026, 5, 18) ||
        d == DateTime(2026, 5, 19));
    expect(intermediates, isEmpty);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/day_meetings_pager_test.dart`
Expected: FAIL — `today` 명명 인자 없음(컴파일 에러).

- [ ] **Step 3: 위젯 전체 교체**

`lib/features/home/widgets/day_meetings_pager.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'meeting_card.dart';

/// 모임 리스트를 가로 스와이프로 날짜 단위 전환하는 페이저.
/// 왼쪽 스와이프=다음 날, 오른쪽=이전 날(오늘에서 멈춤).
class DayMeetingsPager extends StatefulWidget {
  const DayMeetingsPager({
    super.key,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDayChanged,
  });

  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
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
Expected: PASS (3 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/widgets/day_meetings_pager.dart test/day_meetings_pager_test.dart && git commit -m "fix: jumpToPage on external change; bound pager at today"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 4: TwoWeekCalendar — PageView 윈도우 (`two_week_calendar.dart`)

**Files:**
- Modify: `lib/features/home/widgets/two_week_calendar.dart` (전체 교체)

> 단일 파일만 분석한다(`home_screen.dart`는 T5까지 옛 인터페이스 호출로 깨진 상태).

- [ ] **Step 1: 위젯 전체 교체**

`lib/features/home/widgets/two_week_calendar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

/// 2주 윈도우를 좌우 스와이프(슬라이드 애니메이션)로 페이징하는 달력.
/// page 0 = 오늘 주 → 과거 창으로는 넘길 수 없다. 과거 날짜는 선택 불가.
class TwoWeekCalendar extends StatefulWidget {
  const TwoWeekCalendar({
    super.key,
    required this.windowStart,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDaySelected,
    required this.onWindowChanged,
  });

  final DateTime windowStart;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onWindowChanged;

  @override
  State<TwoWeekCalendar> createState() => _TwoWeekCalendarState();
}

class _TwoWeekCalendarState extends State<TwoWeekCalendar> {
  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const double _rowHeight = 104;

  late final DateTime _baseWindow = weekStartOf(widget.today);

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.windowStart));

  int _pageOf(DateTime windowStart) {
    final ws = DateTime(windowStart.year, windowStart.month, windowStart.day);
    return ws.difference(_baseWindow).inDays ~/ 14;
  }

  DateTime _windowOf(int page) => _baseWindow.add(Duration(days: 14 * page));

  bool _isPast(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(widget.today.year, widget.today.month, widget.today.day);
    return day.isBefore(t);
  }

  @override
  void didUpdateWidget(TwoWeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(windowFollowing 등)에서 창이 바뀌면 즉시 이동.
    final target = _pageOf(widget.windowStart);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.jumpToPage(target);
    }
  }

  void _onPageChanged(int page) {
    final ws = _windowOf(page);
    if (!isSameDay(ws, widget.windowStart)) {
      widget.onWindowChanged(ws);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _weekdayHeader(),
        SizedBox(
          height: _rowHeight * 2,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, page) {
              final days = twoWeekGridFrom(_windowOf(page));
              return Column(
                children: [
                  _weekRow(days.sublist(0, 7)),
                  _weekRow(days.sublist(7, 14)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _weekRow(List<DateTime> week) {
    return SizedBox(
      height: _rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final date in week)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: DayCell(
                    date: date,
                    meetings: widget.repository.meetingsOn(date),
                    isPast: _isPast(date),
                    isToday: isSameDay(date, widget.today),
                    isSelected: isSameDay(date, widget.selectedDay),
                    onTap: _isPast(date)
                        ? null
                        : () => widget.onDaySelected(date),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: List.generate(7, (i) {
          Color color = AppColors.textTertiary;
          if (i == 0) color = AppColors.textDanger;
          if (i == 6) color = AppColors.textInfo;
          return Expanded(
            child: Center(
              child: Text(
                _weekdayLabels[i],
                style: TextStyle(fontSize: 11, color: color),
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

- [ ] **Step 2: 단일 파일 분석**

Run: `flutter analyze lib/features/home/widgets/two_week_calendar.dart`
Expected: No issues. (home_screen.dart의 옛 호출 에러는 다른 파일이라 여기 표시되지 않음)

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/widgets/two_week_calendar.dart && git commit -m "feat: TwoWeekCalendar as bounded window PageView with slide animation"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 5: home_screen 배선 + 테스트 + 전체 검증

**Files:**
- Modify: `lib/features/home/home_screen.dart` (전체 교체)
- Modify: `test/home_screen_test.dart` (전체 교체)

- [ ] **Step 1: 홈 테스트 전체 교체(실패 유도 — 과거탭/과거창 차단 추가)**

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

  testWidgets('tapping a future day updates the meeting list', (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('selecting an empty future day shows the empty state',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text('모임 0개'), findsOneWidget);
    expect(find.text('이 날에는 모임이 없어요'), findsOneWidget);
  });

  testWidgets('tapping a past day does nothing', (tester) async {
    await pump(tester);
    // 5/14는 과거(흐림, 선택 불가). 탭해도 선택일/리스트 그대로.
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5월 16일'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
  });

  testWidgets('swiping the calendar left pages two weeks forward',
      (tester) async {
    await pump(tester);
    await tester.fling(
        find.byType(TwoWeekCalendar), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2026년 5–6월'), findsOneWidget);
  });

  testWidgets('cannot swipe the calendar into a past window', (tester) async {
    await pump(tester);
    await tester.fling(
        find.byType(TwoWeekCalendar), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2026년 5월'), findsOneWidget);
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
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    await tester.fling(
        find.byType(DayMeetingsPager), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.textContaining('5월 17일'), findsOneWidget);
    expect(find.text('주말 관악산 등반'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — HomeScreen이 아직 `onWindowDelta`/`today` 미전달 옛 인터페이스 사용.

- [ ] **Step 3: home_screen 전체 교체**

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

  /// 달력 탭(미래/오늘 날짜)과 리스트 스와이프 공통 진입점.
  void _goToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _windowStart = windowFollowing(_windowStart, day);
    });
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
              onWindowChanged: (ws) => setState(() => _windowStart = ws),
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _selectedDay,
                today: _today,
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

- [ ] **Step 4: 홈 테스트 통과 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 "No issues found!", 모든 테스트 PASS.

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "feat: wire bounded list pager + window PageView calendar into home"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시): 떨어진 날짜 탭이 즉시(매끄럽게) 전환, 과거 날짜 탭/오른쪽 리스트 스와이프 불가, 달력 좌우 스와이프가 슬라이드 애니메이션으로 동작하며 오늘 주 이전으로는 안 넘어감.

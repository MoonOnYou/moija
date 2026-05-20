# 홈 캘린더 2주 뷰 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 캘린더를 2주(오늘 주 + 다음 주) 뷰로 바꾸고, 카테고리 확장·풍부한 칩 표시(카테고리·지역·제목 + 자동 +N)·필터 정리를 적용한다.

**Architecture:** 기존 기능 폴더 구조 유지. 6주 월간 그리드를 2주 그리드 함수로 교체하고, `MonthCalendar`를 고정 높이 행 기반 `TwoWeekCalendar`로 대체. `DayCell`은 `LayoutBuilder`로 칩을 높이에 맞춰 자동 채운다. 인메모리 `MeetingRepository`에 `region`이 포함된 풍부한 목 데이터를 둔다.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`(ko_KR), `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-calendar-2week-refinements-design.md`
**고정 "오늘":** 2026-05-16 (토). 그 주 일요일 = 2026-05-10.

---

## File Structure

| 파일 | 변경 |
|------|------|
| `lib/models/meeting_category.dart` | 카테고리 10개로 확장 |
| `lib/models/meeting.dart` | `region` 필드 추가 |
| `lib/data/meeting_repository.dart` | region 포함 풍부한 목 데이터로 교체 |
| `lib/features/home/calendar_grid.dart` | 월 그리드 제거, 2주 그리드 함수 추가 |
| `lib/features/home/widgets/filter_bar.dart` | 칩 정리(신림, 항목 제거) |
| `lib/features/home/widgets/day_cell.dart` | isPast + 한 줄 칩 + 자동 +N |
| `lib/features/home/widgets/two_week_calendar.dart` | `month_calendar.dart` 대체(이름 변경) |
| `lib/features/home/widgets/month_calendar.dart` | 삭제 |
| `lib/features/home/home_screen.dart` | 2주 창 상태/페이징/라벨 |
| `test/calendar_grid_test.dart` | 2주 그리드 테스트로 교체 |
| `test/day_cell_test.dart` | 신규: +N 표시 테스트 |
| `test/home_screen_test.dart` | 2주 뷰 동작으로 갱신 |
| `test/meeting_test.dart` | region 인자 추가 |

---

## Task 1: 카테고리 10개 확장 (`meeting_category.dart`)

**Files:**
- Modify: `lib/models/meeting_category.dart` (전체 교체)

- [ ] **Step 1: 파일 전체 교체**

`lib/models/meeting_category.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 모임 카테고리. 칩/아이콘/색상 정보를 함께 갖는다.
enum MeetingCategory {
  escapeRoom('방탈출', Icons.vpn_key, AppColors.bgInfo, AppColors.textInfo),
  bowling('볼링', Icons.sports_handball, AppColors.bgInfo, AppColors.textInfo),
  karaoke('노래방', Icons.mic, AppColors.bgWarning, AppColors.textWarning),
  drink('술한잔', Icons.local_bar, AppColors.bgWarning, AppColors.textWarning),
  boardGame('보드게임', Icons.casino, AppColors.bgSuccess, AppColors.textSuccess),
  game('게임', Icons.sports_esports, AppColors.bgSuccess, AppColors.textSuccess),
  hiking('등산', Icons.terrain, AppColors.bgSuccess, AppColors.textSuccess),
  movie('영화', Icons.movie, AppColors.bgInfo, AppColors.textInfo),
  cafe('카페', Icons.local_cafe, AppColors.bgWarning, AppColors.textWarning),
  etc('기타', Icons.more_horiz, AppColors.bgTertiary, AppColors.textSecondary);

  const MeetingCategory(
    this.label,
    this.icon,
    this.chipBackground,
    this.chipForeground,
  );

  final String label;
  final IconData icon;
  final Color chipBackground;
  final Color chipForeground;
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `flutter analyze lib/models/meeting_category.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/models/meeting_category.dart && git commit -m "feat: expand meeting categories to 10"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: 모임 모델에 region 추가 (`meeting.dart`)

**Files:**
- Modify: `lib/models/meeting.dart` (전체 교체)
- Modify: `test/meeting_test.dart` (region 인자 추가)

- [ ] **Step 1: 기존 테스트에 region 추가**

`test/meeting_test.dart` 전체 교체:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

void main() {
  test('spotsLeft = max - current', () {
    final m = Meeting(
      id: '1',
      title: '방탈출 호러 테마 같이!',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: '강남 비밀의방',
      region: '강남',
      currentMembers: 2,
      maxMembers: 4,
    );
    expect(m.spotsLeft, 2);
    expect(m.region, '강남');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_test.dart`
Expected: FAIL — `region` 명명 인자 없음(컴파일 에러).

- [ ] **Step 3: 모델에 region 추가**

`lib/models/meeting.dart` 전체 교체:

```dart
import 'meeting_category.dart';

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.location,
    required this.region,
    required this.currentMembers,
    required this.maxMembers,
  });

  final String id;
  final String title;
  final MeetingCategory category;
  final DateTime startTime;
  final String location;

  /// 달력 칩에 쓰는 짧은 지역명(예: "신림").
  final String region;

  final int currentMembers;
  final int maxMembers;

  int get spotsLeft => maxMembers - currentMembers;
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/meeting_test.dart`
Expected: PASS.

- [ ] **Step 5: 커밋**

```bash
git add lib/models/meeting.dart test/meeting_test.dart && git commit -m "feat: add region field to Meeting"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: 2주 그리드 함수 (`calendar_grid.dart`)

**Files:**
- Modify: `lib/features/home/calendar_grid.dart` (전체 교체)
- Modify: `test/calendar_grid_test.dart` (전체 교체)

- [ ] **Step 1: 테스트 전체 교체**

`test/calendar_grid_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/calendar_grid.dart';

void main() {
  group('weekStartOf', () {
    test('returns the Sunday of that week', () {
      // 2026-05-16 is Saturday → Sunday is 2026-05-10.
      expect(weekStartOf(DateTime(2026, 5, 16)), DateTime(2026, 5, 10));
    });
    test('a Sunday returns itself', () {
      expect(weekStartOf(DateTime(2026, 5, 10)), DateTime(2026, 5, 10));
    });
  });

  group('twoWeekGridFrom', () {
    final grid = twoWeekGridFrom(DateTime(2026, 5, 10));
    test('returns 14 consecutive days', () {
      expect(grid, hasLength(14));
      expect(grid.first, DateTime(2026, 5, 10));
      expect(grid.last, DateTime(2026, 5, 23));
    });
  });

  group('buildTwoWeekGrid', () {
    final grid = buildTwoWeekGrid(DateTime(2026, 5, 16));
    test('starts on the Sunday of today\'s week', () {
      expect(grid.first, DateTime(2026, 5, 10));
    });
    test('today is in the first row', () {
      expect(grid.sublist(0, 7).contains(DateTime(2026, 5, 16)), isTrue);
    });
    test('has 14 days', () {
      expect(grid, hasLength(14));
    });
  });

  group('isSameDay', () {
    test('ignores time component', () {
      expect(
        isSameDay(DateTime(2026, 5, 16, 9), DateTime(2026, 5, 16, 21)),
        isTrue,
      );
      expect(isSameDay(DateTime(2026, 5, 16), DateTime(2026, 5, 17)), isFalse);
    });
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: FAIL — `weekStartOf`/`twoWeekGridFrom`/`buildTwoWeekGrid` 없음.

- [ ] **Step 3: 그리드 함수 전체 교체**

`lib/features/home/calendar_grid.dart` 전체 교체:

```dart
/// [day]가 속한 주의 일요일(00:00)을 반환한다.
/// Dart weekday: Mon=1..Sun=7. 일요일 시작이므로 Sun→0 으로 변환.
DateTime weekStartOf(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return d.subtract(Duration(days: d.weekday % 7));
}

/// [weekStart](일요일)부터 14일(2주) 그리드를 생성한다.
/// 반환되는 각 DateTime은 시각이 00:00인 날짜 키다.
List<DateTime> twoWeekGridFrom(DateTime weekStart) {
  final s = DateTime(weekStart.year, weekStart.month, weekStart.day);
  return List.generate(
    14,
    (i) => DateTime(s.year, s.month, s.day + i),
  );
}

/// 오늘이 포함된 주를 첫째 줄로 하는 2주 그리드.
List<DateTime> buildTwoWeekGrid(DateTime today) =>
    twoWeekGridFrom(weekStartOf(today));

/// 두 날짜가 같은 '날'(연/월/일)인지.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: PASS (전체).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/calendar_grid.dart test/calendar_grid_test.dart && git commit -m "feat: replace month grid with two-week grid"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 4: 필터 바 정리 (`filter_bar.dart`)

**Files:**
- Modify: `lib/features/home/widgets/filter_bar.dart` (전체 교체)

- [ ] **Step 1: 파일 전체 교체**

`lib/features/home/widgets/filter_bar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderTertiary, width: 0.5),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterButton(),
          _chip('방탈출', AppColors.bgInfo, AppColors.textInfo),
          _chip('볼링', AppColors.bgInfo, AppColors.textInfo),
          _chip('신림', AppColors.bgSuccess, AppColors.textSuccess),
        ],
      ),
    );
  }

  Widget _filterButton() {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.filter_list, size: 14, color: AppColors.bgPrimary),
          SizedBox(width: 6),
          Text('필터',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bgPrimary)),
          SizedBox(width: 6),
          _Badge(),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('3',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `flutter analyze lib/features/home/widgets/filter_bar.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/widgets/filter_bar.dart && git commit -m "feat: trim filter bar (remove clear-all/this-week, 강남→신림)"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 5: 날짜 셀 — isPast + 한 줄 칩 + 자동 +N (`day_cell.dart`)

**Files:**
- Modify: `lib/features/home/widgets/day_cell.dart` (전체 교체)
- Test: `test/day_cell_test.dart` (신규)

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

`test/day_cell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/widgets/day_cell.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

Meeting _meeting(int i) => Meeting(
      id: '$i',
      title: '모임$i',
      category: MeetingCategory.game,
      startTime: DateTime(2026, 5, 20, 19),
      location: '신림 어딘가',
      region: '신림',
      currentMembers: 1,
      maxMembers: 4,
    );

Widget _host(List<Meeting> meetings) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 50,
            height: 104,
            child: DayCell(
              date: DateTime(2026, 5, 20),
              meetings: meetings,
              isPast: false,
              isToday: false,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows +N when meetings exceed available chip slots',
      (tester) async {
    await tester.pumpWidget(_host(List.generate(6, _meeting)));
    expect(find.textContaining('+'), findsOneWidget);
  });

  testWidgets('shows no +N when a single meeting fits', (tester) async {
    await tester.pumpWidget(_host([_meeting(0)]));
    expect(find.textContaining('+'), findsNothing);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/day_cell_test.dart`
Expected: FAIL — `DayCell`이 `isPast`/`region` 기반이 아니거나 `+N` 미표시(현재는 `inFocusedMonth` 파라미터라 컴파일 에러).

- [ ] **Step 3: `day_cell.dart` 전체 교체**

```dart
import 'package:flutter/material.dart';
import '../../../models/meeting.dart';
import '../../../theme/app_colors.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.meetings,
    required this.isPast,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final List<Meeting> meetings;
  final bool isPast;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _numberRow = 22;
  static const double _gapAfterNumber = 3;
  static const double _chipHeight = 18;
  static const double _chipGap = 2;

  Color _numberColor() {
    if (isSelected) return Colors.white;
    if (isToday) return AppColors.textInfo;
    switch (date.weekday) {
      case DateTime.sunday:
        return AppColors.textDanger;
      case DateTime.saturday:
        return AppColors.textInfo;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = Text(
      '${date.day}',
      style: TextStyle(
        fontSize: 12,
        color: _numberColor(),
        fontWeight: (isToday || isSelected) ? FontWeight.w500 : FontWeight.w400,
      ),
    );

    Widget numberWidget = number;
    if (isSelected) {
      numberWidget = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.textInfo,
          shape: BoxShape.circle,
        ),
        child: number,
      );
    } else if (isToday) {
      numberWidget = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textInfo, width: 1.5),
        ),
        child: number,
      );
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected ? AppColors.bgInfo : null,
        border: isSelected ? Border.all(color: AppColors.borderInfo) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: _numberRow, child: Center(child: numberWidget)),
          const SizedBox(height: _gapAfterNumber),
          Expanded(child: _buildChips()),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(opacity: isPast ? 0.45 : 1.0, child: content),
    );
  }

  Widget _buildChips() {
    if (meetings.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        var maxRows = ((h + _chipGap) / (_chipHeight + _chipGap)).floor();
        if (maxRows < 1) maxRows = 1;

        final n = meetings.length;
        final int visible = (n <= maxRows) ? n : (maxRows - 1).clamp(0, n);
        final remaining = n - visible;

        final children = <Widget>[];
        for (var i = 0; i < visible; i++) {
          if (i > 0) children.add(const SizedBox(height: _chipGap));
          children.add(_chip(meetings[i]));
        }
        if (remaining > 0) {
          if (children.isNotEmpty) children.add(const SizedBox(height: _chipGap));
          children.add(_moreLabel(remaining));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Widget _chip(Meeting m) {
    final text = '${m.category.label}·${m.region}·${m.title}';
    return Container(
      height: _chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgPrimary : m.category.chipBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: m.category.chipForeground),
      ),
    );
  }

  Widget _moreLabel(int remaining) {
    return SizedBox(
      height: _chipHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '+$remaining',
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/day_cell_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/widgets/day_cell.dart test/day_cell_test.dart && git commit -m "feat: DayCell with past dimming and auto-fit category·region·title chips"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 6: 2주 캘린더 위젯 (`two_week_calendar.dart`)

**Files:**
- Create: `lib/features/home/widgets/two_week_calendar.dart`

주: 옛 `month_calendar.dart`는 아직 `home_screen.dart`가 import 중이므로 이 태스크에서는 삭제하지 않는다(Task 7에서 삭제). 두 파일이 잠시 공존하지만 analyze는 깨끗하다.

- [ ] **Step 1: 새 위젯 작성**

`lib/features/home/widgets/two_week_calendar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

class TwoWeekCalendar extends StatelessWidget {
  const TwoWeekCalendar({
    super.key,
    required this.windowStart,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDaySelected,
    required this.onWindowDelta,
  });

  final DateTime windowStart;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onWindowDelta; // 일 단위, -14 또는 +14

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const double _rowHeight = 104;

  bool _isPast(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    return day.isBefore(t);
  }

  @override
  Widget build(BuildContext context) {
    final days = twoWeekGridFrom(windowStart);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 0) {
          onWindowDelta(-14); // 오른쪽으로 스와이프 → 이전 2주
        } else if (v < 0) {
          onWindowDelta(14); // 왼쪽으로 스와이프 → 다음 2주
        }
      },
      child: Column(
        children: [
          _weekdayHeader(),
          _weekRow(days.sublist(0, 7)),
          _weekRow(days.sublist(7, 14)),
        ],
      ),
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
                    meetings: repository.meetingsOn(date),
                    isPast: _isPast(date),
                    isToday: isSameDay(date, today),
                    isSelected: isSameDay(date, selectedDay),
                    onTap: () => onDaySelected(date),
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

- [ ] **Step 2: 새 파일 분석 확인**

Run: `flutter analyze lib/features/home/widgets/two_week_calendar.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/widgets/two_week_calendar.dart && git commit -m "feat: add TwoWeekCalendar widget"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 7: 홈 화면 2주 창 상태/페이징/라벨 + 풍부한 목 데이터

**Files:**
- Modify: `lib/data/meeting_repository.dart` (전체 교체 — region 포함 풍부한 데이터)
- Modify: `lib/features/home/home_screen.dart` (전체 교체)
- Modify: `test/home_screen_test.dart` (전체 교체)

- [ ] **Step 1: 저장소 전체 교체(풍부한 목 데이터)**

`lib/data/meeting_repository.dart`:

```dart
import '../models/meeting.dart';
import '../models/meeting_category.dart';

/// 인메모리 목 데이터 저장소. 후일 백엔드 구현으로 교체 가능하도록
/// 단순한 조회 인터페이스만 노출한다.
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

  List<Meeting> meetingsOn(DateTime day) =>
      List.unmodifiable(_byDay[_key(day)] ?? const []);

  static Meeting _m(
    String id,
    String title,
    MeetingCategory c,
    DateTime start,
    String location,
    String region,
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
        currentMembers: cur,
        maxMembers: max,
      );

  static final List<Meeting> _seed = [
    // 과거(흐림) — 오늘 주의 지난 날들
    _m('p1', '아침 코딩 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 12, 9, 0), '신림 스타벅스', '신림', 2, 5),
    _m('p2', '공포 테마 도전', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 14, 20, 0), '강남 비밀의방', '강남', 3, 4),
    // 오늘 (5/16)
    _m('t1', '퇴근 후 볼링', MeetingCategory.bowling,
        DateTime(2026, 5, 16, 20, 0), '신림 볼링장', '신림', 4, 6),
    _m('t2', '불금 한잔', MeetingCategory.drink,
        DateTime(2026, 5, 16, 21, 0), '신림 포차거리', '신림', 3, 6),
    // 5/17
    _m('a1', '주말 관악산 등반', MeetingCategory.hiking,
        DateTime(2026, 5, 17, 8, 0), '관악산 입구', '신림', 5, 10),
    // 5/18 — 비움(빈 상태 시연)
    // 5/19
    _m('b1', '방탈출 호러 테마 같이!', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 19, 20, 0), '강남 비밀의방', '강남', 2, 4),
    _m('b2', '코노 1시간', MeetingCategory.karaoke,
        DateTime(2026, 5, 19, 19, 0), '신림 코인노래방', '신림', 2, 6),
    // 5/20 — 6개(+N 시연)
    _m('c1', '보드게임 정모', MeetingCategory.boardGame,
        DateTime(2026, 5, 20, 19, 0), '신림 보드카페', '신림', 3, 6),
    _m('c2', '롤 한판', MeetingCategory.game,
        DateTime(2026, 5, 20, 20, 0), '신림 PC방', '신림', 4, 5),
    _m('c3', '심야 영화', MeetingCategory.movie,
        DateTime(2026, 5, 20, 22, 0), '신림 CGV', '신림', 2, 4),
    _m('c4', '라떼 한잔', MeetingCategory.cafe,
        DateTime(2026, 5, 20, 15, 0), '신림 카페거리', '신림', 1, 4),
    _m('c5', '소맥 모임', MeetingCategory.drink,
        DateTime(2026, 5, 20, 21, 0), '신림 술집', '신림', 5, 8),
    _m('c6', '노래방 직행', MeetingCategory.karaoke,
        DateTime(2026, 5, 20, 23, 0), '신림 노래타운', '신림', 2, 6),
    // 5/21
    _m('d1', '심야 영화 모임', MeetingCategory.movie,
        DateTime(2026, 5, 21, 22, 0), '강남 메가박스', '강남', 3, 5),
    // 5/22
    _m('e1', '오후 카페 수다', MeetingCategory.cafe,
        DateTime(2026, 5, 22, 14, 0), '홍대 카페', '홍대', 2, 4),
    // 5/23
    _m('f1', '토요 볼링 정모', MeetingCategory.bowling,
        DateTime(2026, 5, 23, 18, 0), '잠실 볼링센터', '잠실', 5, 8),
  ];
}
```

- [ ] **Step 2: 홈 화면 테스트 전체 교체(실패 확인용)**

`test/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/two_week_calendar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // 실제 휴대폰 뷰포트(390x844)로 렌더한다.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  }

  testWidgets('shows the single-month label for the initial window',
      (tester) async {
    await pump(tester);
    // 초기 창 5/10~5/23 → 같은 달.
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('tapping a day updates the meeting list', (tester) async {
    await pump(tester);
    // 기본 선택일은 오늘(5/16) → "퇴근 후 볼링"이 보인다.
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('selecting an empty day shows the empty state', (tester) async {
    await pump(tester);
    // 5/18에는 모임이 없다.
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text('모임 0개'), findsOneWidget);
    expect(find.text('이 날에는 모임이 없어요'), findsOneWidget);
  });

  testWidgets('swiping pages the window by two weeks', (tester) async {
    await pump(tester);
    await tester.fling(
        find.byType(TwoWeekCalendar), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    // 다음 창 5/24~6/6 → 두 달에 걸침.
    expect(find.text('2026년 5–6월'), findsOneWidget);
  });

  testWidgets('past days are dimmed', (tester) async {
    await pump(tester);
    // 오늘 주의 지난 날(5/10~5/15)은 Opacity 0.45로 흐리게.
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.45),
      findsWidgets,
    );
  });
}
```

- [ ] **Step 3: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — `two_week_calendar.dart` import 또는 `HomeScreen`의 새 동작 미구현.

- [ ] **Step 4: 홈 화면 전체 교체**

`lib/features/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../theme/app_colors.dart';
import 'calendar_grid.dart';
import 'widgets/filter_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/meeting_card.dart';
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

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
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
              onDaySelected: _selectDay,
              onWindowDelta: _shiftWindow,
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
            ),
            Expanded(
              child: dayMeetings.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        for (final m in dayMeetings) MeetingCard(meeting: m),
                      ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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

- [ ] **Step 5: 홈 화면 테스트 통과 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: 더 이상 쓰지 않는 옛 위젯 삭제**

이제 `home_screen.dart`가 `month_calendar.dart`를 import하지 않으므로 안전하게 삭제한다.

Run: `git rm lib/features/home/widgets/month_calendar.dart`
Expected: 파일 삭제됨. (혹시 남아있는 import가 없는지 확인)

- [ ] **Step 7: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 "No issues found!", 모든 테스트 PASS.

- [ ] **Step 8: 커밋**

```bash
git add -A && git commit -m "feat: two-week window home with paging, rich mock data"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시) 시각 확인: 2주 캘린더(오늘 주가 첫 줄, 과거 흐림), 칩이 `카테고리·지역·제목`로 보이고 5/20에 `+N`, 필터 바 `방탈출/볼링/신림`, 리스트 스크롤, 좌우 스와이프로 2주 페이징.

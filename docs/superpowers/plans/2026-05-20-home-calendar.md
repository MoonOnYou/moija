# 홈 캘린더 화면 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 목업 `docs/page/01_홈.html`과 일치하는 모이자 홈(월간 캘린더) 화면을, 인메모리 목 데이터로 날짜 선택·월 이동이 동작하도록 구현한다.

**Architecture:** 기능 단위 폴더 구조(theme/models/data/features/shell). 캘린더는 외부 패키지 없이 직접 구현. `HomeScreen`이 `StatefulWidget`으로 `focusedMonth`/`selectedDay` 두 상태만 관리하고, 표현 위젯들은 stateless로 분리. 목 데이터는 `MeetingRepository`(인메모리)에 격리해 후일 백엔드 교체를 쉽게 한다. Flutter는 목업의 절대 위치 대신 자연스러운 `Column` 레이아웃을 사용한다.

**Tech Stack:** Flutter 3.38.x / Dart 3.10, `intl`(ko_KR 날짜 포맷), `flutter_test`. Material Icons.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-home-calendar-design.md`

**고정 기준일(목 데이터의 "오늘"):** 2026-05-16

---

## File Structure

| 파일 | 책임 |
|------|------|
| `lib/theme/app_colors.dart` | 목업 색상 토큰 상수 |
| `lib/models/meeting_category.dart` | 카테고리 enum + 라벨/아이콘/색상 |
| `lib/models/meeting.dart` | 모임 모델 + 남은자리 계산 |
| `lib/data/meeting_repository.dart` | 인메모리 목 데이터 + 날짜별 조회 |
| `lib/features/home/calendar_grid.dart` | 월 그리드 날짜 계산 순수 함수 |
| `lib/features/home/widgets/day_cell.dart` | 날짜 셀 1칸 |
| `lib/features/home/widgets/month_calendar.dart` | 요일 헤더 + 6주 그리드 |
| `lib/features/home/widgets/home_header.dart` | 타이틀·다이아·검색·알림 |
| `lib/features/home/widgets/filter_bar.dart` | 필터 칩(표시 전용) |
| `lib/features/home/widgets/selected_day_summary.dart` | 선택일 요약 줄 |
| `lib/features/home/widgets/meeting_card.dart` | 모임 리스트 카드 |
| `lib/features/home/home_screen.dart` | 홈 조립 + 상태 |
| `lib/shell/app_shell.dart` | 하단 4탭 셸(홈만 구현) |
| `lib/main.dart` | 진입점·테마·intl 초기화 |
| `test/calendar_grid_test.dart` | 그리드 계산 단위 테스트 |
| `test/home_screen_test.dart` | 날짜 선택·월 이동 위젯 테스트 |

---

## Task 0: 프로젝트 셋업 (git init + intl + 카운터 제거)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart` (임시로 빈 앱)
- Delete: `test/widget_test.dart` 내용 교체

- [ ] **Step 1: git 저장소 초기화**

Run:
```bash
cd /Users/onyoumoon/Documents/workspace/onyou/moija && git init && git add -A && git commit -m "chore: initial Flutter project snapshot"
```
Expected: `Initialized empty Git repository` 후 커밋 성공.

- [ ] **Step 2: intl 의존성 추가**

Run:
```bash
flutter pub add intl
```
Expected: `pubspec.yaml`의 `dependencies:`에 `intl:` 추가, `pub get` 성공.

- [ ] **Step 3: main.dart를 임시 최소 앱으로 교체**

`lib/main.dart` 전체를 다음으로 교체(이후 Task 12에서 완성):

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MoijaApp());
}

class MoijaApp extends StatelessWidget {
  const MoijaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}
```

- [ ] **Step 4: 카운터 테스트 제거(임시 스모크 테스트로 교체)**

`test/widget_test.dart` 전체를 다음으로 교체:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const MoijaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

- [ ] **Step 5: 분석 & 테스트 통과 확인**

Run: `flutter analyze && flutter test`
Expected: 분석 0 issues, 테스트 PASS.

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "chore: add intl, remove counter demo"
```

---

## Task 1: 색상 토큰 (`app_colors.dart`)

**Files:**
- Create: `lib/theme/app_colors.dart`

- [ ] **Step 1: 색상 상수 작성**

`lib/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// 목업(docs/page/01_홈.html)의 CSS 변수에 대응하는 색상 토큰.
abstract final class AppColors {
  // 배경
  static const bgPrimary = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF7F6F3);
  static const bgTertiary = Color(0xFFF1EFE8);
  static const bgInfo = Color(0xFFE6F1FB);
  static const bgWarning = Color(0xFFFAEEDA);
  static const bgSuccess = Color(0xFFEAF3DE);

  // 텍스트
  static const textPrimary = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textTertiary = Color(0xFF888780);
  static const textInfo = Color(0xFF185FA5);
  static const textWarning = Color(0xFF854F0B);
  static const textSuccess = Color(0xFF3B6D11);
  static const textDanger = Color(0xFFA32D2D);

  // 보더
  static const borderTertiary = Color(0x26000000); // rgba(0,0,0,0.15)
  static const borderInfo = Color(0xFFB5D4F4);
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `flutter analyze lib/theme/app_colors.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/theme/app_colors.dart && git commit -m "feat: add color tokens from mockup"
```

---

## Task 2: 카테고리 모델 (`meeting_category.dart`)

**Files:**
- Create: `lib/models/meeting_category.dart`

- [ ] **Step 1: enum + 속성 작성**

`lib/models/meeting_category.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 모임 카테고리. 칩/아이콘/색상 정보를 함께 갖는다.
enum MeetingCategory {
  escapeRoom('방탈출', Icons.vpn_key, AppColors.bgInfo, AppColors.textInfo),
  bowling('볼링', Icons.sports_handball, AppColors.bgInfo, AppColors.textInfo);

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
git add lib/models/meeting_category.dart && git commit -m "feat: add MeetingCategory"
```

---

## Task 3: 모임 모델 (`meeting.dart`)

**Files:**
- Create: `lib/models/meeting.dart`
- Test: `test/meeting_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/meeting_test.dart`:

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
      currentMembers: 2,
      maxMembers: 4,
    );
    expect(m.spotsLeft, 2);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_test.dart`
Expected: FAIL — `Meeting`을 찾을 수 없음(컴파일 에러).

- [ ] **Step 3: 모델 구현**

`lib/models/meeting.dart`:

```dart
import 'meeting_category.dart';

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.location,
    required this.currentMembers,
    required this.maxMembers,
  });

  final String id;
  final String title;
  final MeetingCategory category;
  final DateTime startTime;
  final String location;
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
git add lib/models/meeting.dart test/meeting_test.dart && git commit -m "feat: add Meeting model"
```

---

## Task 4: 목 데이터 저장소 (`meeting_repository.dart`)

**Files:**
- Create: `lib/data/meeting_repository.dart`
- Test: `test/meeting_repository_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/meeting_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';

void main() {
  final repo = MeetingRepository();

  test('meetingsOn returns meetings for that day only', () {
    final may19 = repo.meetingsOn(DateTime(2026, 5, 19));
    expect(may19, hasLength(1));
    expect(may19.first.title, '방탈출 호러 테마 같이!');
  });

  test('meetingsOn returns empty list for a day with no meetings', () {
    expect(repo.meetingsOn(DateTime(2026, 5, 11)), isEmpty);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_repository_test.dart`
Expected: FAIL — `MeetingRepository` 없음.

- [ ] **Step 3: 저장소 구현**

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

  static final List<Meeting> _seed = [
    Meeting(
      id: 'm1',
      title: '주말 볼링 한 게임',
      category: MeetingCategory.bowling,
      startTime: DateTime(2026, 5, 10, 19, 0),
      location: '강남 볼링장',
      currentMembers: 3,
      maxMembers: 6,
    ),
    Meeting(
      id: 'm2',
      title: '방탈출 입문 모임',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 14, 19, 30),
      location: '홍대 키이스케이프',
      currentMembers: 2,
      maxMembers: 4,
    ),
    Meeting(
      id: 'm3',
      title: '퇴근 후 볼링',
      category: MeetingCategory.bowling,
      startTime: DateTime(2026, 5, 16, 20, 0),
      location: '강남 볼링장',
      currentMembers: 4,
      maxMembers: 6,
    ),
    Meeting(
      id: 'm4',
      title: '방탈출 호러 테마 같이!',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: '강남 비밀의방',
      currentMembers: 2,
      maxMembers: 4,
    ),
    Meeting(
      id: 'm5',
      title: '토요일 볼링 정모',
      category: MeetingCategory.bowling,
      startTime: DateTime(2026, 5, 23, 18, 0),
      location: '잠실 볼링센터',
      currentMembers: 5,
      maxMembers: 8,
    ),
    Meeting(
      id: 'm6',
      title: 'SF 테마 방탈출',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 28, 20, 30),
      location: '강남 비밀의방',
      currentMembers: 1,
      maxMembers: 4,
    ),
  ];
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/meeting_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/data/meeting_repository.dart test/meeting_repository_test.dart && git commit -m "feat: add in-memory MeetingRepository with mock data"
```

---

## Task 5: 월 그리드 계산 순수 함수 (`calendar_grid.dart`)

**Files:**
- Create: `lib/features/home/calendar_grid.dart`
- Test: `test/calendar_grid_test.dart`

주: 주 시작 요일은 **일요일**(목업 헤더 일~토). 항상 6주(42칸)를 반환한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`test/calendar_grid_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/calendar_grid.dart';

void main() {
  group('buildMonthGrid', () {
    final grid = buildMonthGrid(DateTime(2026, 5, 1));

    test('returns 42 days', () {
      expect(grid, hasLength(42));
    });

    test('starts on the Sunday on/before the 1st', () {
      // 2026-05-01 is Friday; the grid starts on 2026-04-26 (Sunday).
      expect(grid.first, DateTime(2026, 4, 26));
    });

    test('contains the 1st of the focused month', () {
      expect(grid.contains(DateTime(2026, 5, 1)), isTrue);
    });

    test('last cell is 41 days after the first', () {
      expect(grid.last, DateTime(2026, 6, 6));
    });
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: FAIL — `buildMonthGrid` 없음.

- [ ] **Step 3: 함수 구현**

`lib/features/home/calendar_grid.dart`:

```dart
/// [month]가 속한 달을 그리는 6주(42칸) 그리드를 생성한다.
/// 주 시작은 일요일. 앞뒤로 이웃 달 날짜가 채워진다.
/// 반환되는 각 DateTime은 시각이 00:00인 날짜 키다.
List<DateTime> buildMonthGrid(DateTime month) {
  final firstOfMonth = DateTime(month.year, month.month, 1);
  // Dart weekday: Mon=1..Sun=7. 일요일 시작이므로 Sun→0 으로 변환.
  final leading = firstOfMonth.weekday % 7;
  final start = firstOfMonth.subtract(Duration(days: leading));
  return List.generate(
    42,
    (i) => DateTime(start.year, start.month, start.day + i),
  );
}

/// 두 날짜가 같은 '날'(연/월/일)인지.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/calendar_grid_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/calendar_grid.dart test/calendar_grid_test.dart && git commit -m "feat: add month grid calculation"
```

---

## Task 6: 날짜 셀 위젯 (`day_cell.dart`)

**Files:**
- Create: `lib/features/home/widgets/day_cell.dart`

날짜 1칸을 그린다. 오늘=링, 선택일=채운 원+셀 배경, 이웃 달=흐림, 일/토 색상, 모임 칩(최대 1개 + "+N").

- [ ] **Step 1: 위젯 작성**

`lib/features/home/widgets/day_cell.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../models/meeting.dart';
import '../../../theme/app_colors.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.meetings,
    required this.inFocusedMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final List<Meeting> meetings;
  final bool inFocusedMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

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

    final cell = Opacity(
      opacity: inFocusedMonth ? 1.0 : 0.45,
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? AppColors.bgInfo : null,
          border: isSelected
              ? Border.all(color: AppColors.borderInfo)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 22, child: Center(child: numberWidget)),
            const SizedBox(height: 3),
            if (meetings.isNotEmpty) _chip(meetings.first),
            if (meetings.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${meetings.length - 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }

  Widget _chip(Meeting m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgPrimary : m.category.chipBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        m.category.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          color: m.category.chipForeground,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `flutter analyze lib/features/home/widgets/day_cell.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/widgets/day_cell.dart && git commit -m "feat: add DayCell widget"
```

---

## Task 7: 월간 캘린더 위젯 (`month_calendar.dart`)

**Files:**
- Create: `lib/features/home/widgets/month_calendar.dart`

요일 헤더 + 7열 그리드. 좌우 스와이프로 월 이동. 셀 탭으로 날짜 선택.

- [ ] **Step 1: 위젯 작성**

`lib/features/home/widgets/month_calendar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDaySelected,
    required this.onMonthDelta,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onMonthDelta; // -1 이전달, +1 다음달

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final days = buildMonthGrid(focusedMonth);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 0) {
          onMonthDelta(-1); // 오른쪽으로 스와이프 → 이전 달
        } else if (v < 0) {
          onMonthDelta(1); // 왼쪽으로 스와이프 → 다음 달
        }
      },
      child: Column(
        children: [
          _weekdayHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, i) {
                final date = days[i];
                return DayCell(
                  date: date,
                  meetings: repository.meetingsOn(date),
                  inFocusedMonth: date.month == focusedMonth.month,
                  isToday: isSameDay(date, today),
                  isSelected: isSameDay(date, selectedDay),
                  onTap: () => onDaySelected(date),
                );
              },
            ),
          ),
        ],
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

- [ ] **Step 2: 분석 통과 확인**

Run: `flutter analyze lib/features/home/widgets/month_calendar.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/widgets/month_calendar.dart && git commit -m "feat: add MonthCalendar widget"
```

---

## Task 8: 헤더 & 필터 바 (`home_header.dart`, `filter_bar.dart`)

**Files:**
- Create: `lib/features/home/widgets/home_header.dart`
- Create: `lib/features/home/widgets/filter_bar.dart`

둘 다 표시 전용(상호작용 없음).

- [ ] **Step 1: 헤더 작성**

`lib/features/home/widgets/home_header.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.monthLabel});

  /// 예: "2026년 5월"
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '모이자',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bgInfo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.diamond, size: 15, color: AppColors.textInfo),
                SizedBox(width: 4),
                Text(
                  '1,000',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textInfo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_none,
              size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 필터 바 작성**

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
          _chip('강남', AppColors.bgSuccess, AppColors.textSuccess),
          _chip('이번 주', AppColors.bgWarning, AppColors.textWarning),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '모두 지우기',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
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
      child: const Text('4',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }
}
```

- [ ] **Step 3: 분석 통과 확인**

Run: `flutter analyze lib/features/home/widgets/home_header.dart lib/features/home/widgets/filter_bar.dart`
Expected: No issues.

- [ ] **Step 4: 커밋**

```bash
git add lib/features/home/widgets/home_header.dart lib/features/home/widgets/filter_bar.dart && git commit -m "feat: add HomeHeader and FilterBar"
```

---

## Task 9: 선택일 요약 & 모임 카드 (`selected_day_summary.dart`, `meeting_card.dart`)

**Files:**
- Create: `lib/features/home/widgets/selected_day_summary.dart`
- Create: `lib/features/home/widgets/meeting_card.dart`

- [ ] **Step 1: 요약 위젯 작성**

`lib/features/home/widgets/selected_day_summary.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

class SelectedDaySummary extends StatelessWidget {
  const SelectedDaySummary({
    super.key,
    required this.selectedDay,
    required this.meetingCount,
  });

  final DateTime selectedDay;
  final int meetingCount;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('M월 d일 (E)', 'ko_KR').format(selectedDay);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderTertiary, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('모임 $meetingCount개',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 카드 위젯 작성**

`lib/features/home/widgets/meeting_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/meeting.dart';
import '../../../theme/app_colors.dart';

class MeetingCard extends StatelessWidget {
  const MeetingCard({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(meeting.startTime);
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: meeting.category.chipBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(meeting.category.icon,
                size: 28, color: meeting.category.chipForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const Text('  ·  ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(meeting.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${meeting.currentMembers} / ${meeting.maxMembers}명 · ${_spotsLabel(meeting.spotsLeft)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textInfo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _spotsLabel(int spots) =>
      spots > 0 ? '$spots자리 남음' : '마감';
}
```

- [ ] **Step 3: 분석 통과 확인**

Run: `flutter analyze lib/features/home/widgets/selected_day_summary.dart lib/features/home/widgets/meeting_card.dart`
Expected: No issues.

- [ ] **Step 4: 커밋**

```bash
git add lib/features/home/widgets/selected_day_summary.dart lib/features/home/widgets/meeting_card.dart && git commit -m "feat: add SelectedDaySummary and MeetingCard"
```

---

## Task 10: 홈 화면 조립 + 상태 (`home_screen.dart`)

**Files:**
- Create: `lib/features/home/home_screen.dart`
- Test: `test/home_screen_test.dart`

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

`test/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/month_calendar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Widget wrap() => const MaterialApp(home: HomeScreen());

  testWidgets('shows the fixed-today month label', (tester) async {
    await tester.pumpWidget(wrap());
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('tapping a day updates the meeting list', (tester) async {
    await tester.pumpWidget(wrap());
    // 기본 선택일은 오늘(5/16) → "퇴근 후 볼링"이 보인다.
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    // 5월 19일 셀 탭 → "방탈출 호러 테마 같이!"로 갱신.
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('month navigation updates the header label', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.fling(
        find.byType(MonthCalendar), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2026년 6월'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — `HomeScreen` 없음.

- [ ] **Step 3: 홈 화면 구현**

`lib/features/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../theme/app_colors.dart';
import 'widgets/filter_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/meeting_card.dart';
import 'widgets/month_calendar.dart';
import 'widgets/selected_day_summary.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 목 데이터의 고정 "오늘".
  static final DateTime _today = DateTime(2026, 5, 16);

  final MeetingRepository _repository = MeetingRepository();
  late DateTime _focusedMonth = DateTime(_today.year, _today.month);
  late DateTime _selectedDay = _today;

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedMonth = DateTime(day.year, day.month);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('y년 M월', 'ko_KR').format(_focusedMonth);
    final dayMeetings = _repository.meetingsOn(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(monthLabel: monthLabel),
            const SizedBox(height: 8),
            const FilterBar(),
            MonthCalendar(
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              today: _today,
              repository: _repository,
              onDaySelected: _selectDay,
              onMonthDelta: _changeMonth,
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

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/home/home_screen.dart test/home_screen_test.dart && git commit -m "feat: assemble HomeScreen with date selection and month nav"
```

---

## Task 11: 하단 탭 셸 (`app_shell.dart`)

**Files:**
- Create: `lib/shell/app_shell.dart`

홈만 실제 구현, 나머지 3탭은 플레이스홀더.

- [ ] **Step 1: 셸 작성**

`lib/shell/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _placeholders = ['채팅', '내모임', '프로필'];

  @override
  Widget build(BuildContext context) {
    final Widget body = _index == 0
        ? const HomeScreen()
        : _Placeholder(label: _placeholders[_index - 1]);

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: '내모임'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Text('$label (준비 중)',
            style: const TextStyle(
                fontSize: 15, color: AppColors.textTertiary)),
      ),
    );
  }
}
```

- [ ] **Step 2: 분석 통과 확인**

Run: `flutter analyze lib/shell/app_shell.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/shell/app_shell.dart && git commit -m "feat: add bottom-tab AppShell"
```

---

## Task 12: 앱 진입점 마무리 (`main.dart`) + 스모크 테스트

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: main.dart 완성**

`lib/main.dart` 전체 교체:

```dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'shell/app_shell.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  runApp(const MoijaApp());
}

class MoijaApp extends StatelessWidget {
  const MoijaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모이자',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgPrimary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.textInfo),
        fontFamily: 'Pretendard',
      ),
      home: const AppShell(),
    );
  }
}
```

주: `fontFamily: 'Pretendard'`는 폰트 미등록 시 시스템 기본으로 폴백된다(에러 아님). 별도 폰트 등록은 범위 밖.

- [ ] **Step 2: 스모크 테스트 갱신**

`test/widget_test.dart` 전체 교체:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/main.dart';
import 'package:moija/features/home/home_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('app boots into HomeScreen', (tester) async {
    await tester.pumpWidget(const MoijaApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('모이자'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 전체 분석 & 테스트 통과 확인**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 모든 테스트 PASS.

- [ ] **Step 4: 커밋**

```bash
git add lib/main.dart test/widget_test.dart && git commit -m "feat: wire MoijaApp entry point into AppShell"
```

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시)으로 홈 화면 시각 확인: 헤더/필터/캘린더/요약/카드/FAB/하단탭이 목업과 일치, 날짜 탭·월 스와이프 동작
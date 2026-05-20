# 필터 영구 저장 · 장소 뒤로가기 · 요약 필터 개수 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 필터를 앱 재시작 후에도 유지하고(shared_preferences), 장소 화면에서 뒤로가기 시 지역 목록으로 복귀하며, 홈 요약에 "필터 N개 · 모임 M개"를 표시한다.

**Architecture:** `MeetingFilter`에 직렬화(toMap/fromMap)를 더하고 `FilterStorage`가 shared_preferences에 저장/복원한다. `LocationPickerScreen`은 `PopScope`로 시스템 back을 가로채 지역 목록으로 복귀한다. `SelectedDaySummary`는 필터 개수를 받아 표시하고, 홈이 시작 시 필터를 로드·적용한다.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `shared_preferences`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-filter-persistence-design.md`
**고정 "오늘":** 2026-05-16.

---

## File Structure

| 파일 | 변경 |
|------|------|
| `lib/models/meeting_filter.dart` | `toMap`/`fromMap` 추가 |
| `pubspec.yaml` | `shared_preferences` 추가 |
| `lib/data/filter_storage.dart` | 신규: 저장/복원 |
| `lib/features/filter/location_picker_screen.dart` | `PopScope`로 back 가로채기 |
| `lib/features/home/widgets/selected_day_summary.dart` | `filterCount` 추가 |
| `lib/features/home/home_screen.dart` | 로드/저장 + filterCount 전달 |
| 테스트 | meeting_filter(추가), filter_storage(신규), location_picker(추가), home_screen(갱신) |

---

## Task 1: MeetingFilter 직렬화 (`meeting_filter.dart`)

**Files:**
- Modify: `lib/models/meeting_filter.dart`
- Modify: `test/meeting_filter_test.dart` (테스트 추가)

- [ ] **Step 1: 실패 테스트 추가**

`test/meeting_filter_test.dart`의 `void main() {` 안, 마지막 `});` 다음(닫는 `}` 직전)에 아래 두 테스트를 추가한다(기존 테스트는 그대로):

```dart
  test('toMap/fromMap round-trip', () {
    const f = MeetingFilter(
      categories: {MeetingCategory.bowling, MeetingCategory.cafe},
      locationIds: {'seoul-line2'},
      timeBands: {TimeBand.evening},
      customCategories: {'플로깅'},
    );
    final restored = MeetingFilter.fromMap(f.toMap());
    expect(restored.categories, f.categories);
    expect(restored.locationIds, f.locationIds);
    expect(restored.timeBands, f.timeBands);
    expect(restored.customCategories, f.customCategories);
  });

  test('fromMap ignores unknown enum names', () {
    final f = MeetingFilter.fromMap({
      'categories': ['bowling', 'unknownCat'],
      'timeBands': ['evening', 'nope'],
    });
    expect(f.categories, {MeetingCategory.bowling});
    expect(f.timeBands, {TimeBand.evening});
    expect(f.locationIds, isEmpty);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_filter_test.dart`
Expected: FAIL — `toMap`/`fromMap` 없음.

- [ ] **Step 3: 직렬화 추가**

`lib/models/meeting_filter.dart`의 `matches(...)` 메서드 바로 다음(클래스 닫는 `}` 직전)에 추가한다:

```dart
  Map<String, dynamic> toMap() => {
        'categories': categories.map((c) => c.name).toList(),
        'locationIds': locationIds.toList(),
        'timeBands': timeBands.map((b) => b.name).toList(),
        'customCategories': customCategories.toList(),
      };

  /// 관대한 파싱: 알 수 없는 enum name은 건너뛴다.
  factory MeetingFilter.fromMap(Map<String, dynamic> map) {
    Set<E> parseEnum<E extends Enum>(Object? raw, List<E> values) {
      final names = (raw as List?)?.cast<String>() ?? const <String>[];
      final out = <E>{};
      for (final name in names) {
        for (final v in values) {
          if (v.name == name) {
            out.add(v);
            break;
          }
        }
      }
      return out;
    }

    Set<String> parseStrings(Object? raw) =>
        ((raw as List?)?.cast<String>() ?? const <String>[]).toSet();

    return MeetingFilter(
      categories: parseEnum(map['categories'], MeetingCategory.values),
      locationIds: parseStrings(map['locationIds']),
      timeBands: parseEnum(map['timeBands'], TimeBand.values),
      customCategories: parseStrings(map['customCategories']),
    );
  }
```

(주: 파일 상단에는 이미 `meeting_category.dart`, `time_band.dart` import가 있다.)

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/meeting_filter_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/models/meeting_filter.dart test/meeting_filter_test.dart && git commit -m "feat: add MeetingFilter serialization"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: FilterStorage (`filter_storage.dart`)

**Files:**
- Modify: `pubspec.yaml` (의존성)
- Create: `lib/data/filter_storage.dart`
- Test: `test/filter_storage_test.dart`

- [ ] **Step 1: shared_preferences 추가**

Run: `flutter pub add shared_preferences`
Expected: `pubspec.yaml` dependencies에 `shared_preferences:` 추가, pub get 성공.

- [ ] **Step 2: 실패 테스트 작성**

`test/filter_storage_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moija/data/filter_storage.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_filter.dart';
import 'package:moija/models/time_band.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load returns empty when nothing saved', () async {
    final f = await FilterStorage().load();
    expect(f.isEmpty, isTrue);
  });

  test('save then load restores the filter', () async {
    const filter = MeetingFilter(
      categories: {MeetingCategory.bowling},
      locationIds: {'seoul-line2'},
      timeBands: {TimeBand.evening},
    );
    final storage = FilterStorage();
    await storage.save(filter);
    final restored = await storage.load();
    expect(restored.categories, {MeetingCategory.bowling});
    expect(restored.locationIds, {'seoul-line2'});
    expect(restored.timeBands, {TimeBand.evening});
  });
}
```

- [ ] **Step 3: 실패 확인**

Run: `flutter test test/filter_storage_test.dart`
Expected: FAIL — `FilterStorage` 없음.

- [ ] **Step 4: 구현**

`lib/data/filter_storage.dart`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting_filter.dart';

/// 필터를 기기 저장소에 영구 보관한다.
class FilterStorage {
  static const _key = 'meeting_filter';

  Future<void> save(MeetingFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(filter.toMap()));
  }

  Future<MeetingFilter> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const MeetingFilter.empty();
    return MeetingFilter.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }
}
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/filter_storage_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: 커밋**

```bash
git add pubspec.yaml pubspec.lock lib/data/filter_storage.dart test/filter_storage_test.dart && git commit -m "feat: add FilterStorage backed by shared_preferences"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: 장소 화면 뒤로가기 (`location_picker_screen.dart`)

**Files:**
- Modify: `lib/features/filter/location_picker_screen.dart`
- Modify: `test/location_picker_screen_test.dart` (테스트 추가)

- [ ] **Step 1: 실패 테스트 추가**

`test/location_picker_screen_test.dart`의 `void main() {` 안, 마지막 `});` 다음(닫는 `}` 직전)에 추가한다:

```dart
  testWidgets('system back from region detail returns to the region list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push<Set<String>>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen(initial: {}),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대구'));
    await tester.pumpAndSettle();
    expect(find.text('대구1호선'), findsOneWidget);

    // 시스템(기기) 뒤로가기.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('대구1호선'), findsNothing); // 지역 상세 닫힘
    expect(find.text('장소 선택'), findsOneWidget); // 시/도 목록으로 복귀(picker 유지)
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: FAIL — 시스템 back이 picker 전체를 닫아 `장소 선택` 타이틀이 사라지거나 `대구1호선`이 남는다.

- [ ] **Step 3: PopScope 적용**

`lib/features/filter/location_picker_screen.dart`의 `build`에서 `return Scaffold(`를 `return PopScope(...)`로 감싼다. `build` 메서드를 다음으로 교체한다(기존 `Scaffold(...)` 본문은 그대로 `child:`에 둔다):

```dart
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_region != null) {
          setState(() => _region = null);
        } else {
          Navigator.pop(context, _selected);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_region != null) {
                setState(() => _region = null);
              } else {
                Navigator.pop(context, _selected);
              }
            },
          ),
          title: Text(_region ?? '장소 선택'),
        ),
        body: Column(
          children: [
            if (_selected.isNotEmpty) _selectedChips(),
            Expanded(
                child: _region == null ? _regionList() : _nodeList(_region!)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.bgPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('완료'),
              ),
            ),
          ),
        ),
      ),
    );
  }
```

(나머지 메서드 `_selectedChips`, `_regionList`, `_nodeList`, `_toggle`, 필드는 그대로 둔다.)

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/filter/location_picker_screen.dart test/location_picker_screen_test.dart && git commit -m "feat: system back returns to region list in location picker"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 4: 요약 필터 개수 + 홈 영구 저장 (통합)

**Files:**
- Modify: `lib/features/home/widgets/selected_day_summary.dart` (전체 교체)
- Modify: `lib/features/home/home_screen.dart` (전체 교체)
- Modify: `test/home_screen_test.dart` (전체 교체)

- [ ] **Step 1: 홈 테스트 전체 교체(실패 유도 — prefs 목 + 영구 저장 + 요약)**

`test/home_screen_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moija/features/filter/filter_screen.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the single-month label for the initial window',
      (tester) async {
    await pump(tester);
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('summary shows filter and meeting counts', (tester) async {
    await pump(tester);
    // 오늘(5/16) 모임 2개("퇴근 후 볼링","불금 한잔"), 필터 0개.
    expect(find.text('필터 0개 · 모임 2개'), findsOneWidget);
  });

  testWidgets('tapping a future day updates the meeting list', (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
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

  testWidgets('tapping the filter bar opens the FilterScreen', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('filter-bar')));
    await tester.pumpAndSettle();
    expect(find.byType(FilterScreen), findsOneWidget);
  });

  testWidgets('applying a category filter hides non-matching meetings',
      (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('볼링'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsNothing);
  });

  testWidgets('restores a persisted filter on launch', (tester) async {
    SharedPreferences.setMockInitialValues({
      'meeting_filter': jsonEncode({
        'categories': ['bowling'],
      }),
    });
    await pump(tester);
    // 저장된 필터(볼링)가 시작 시 적용 → 5/16의 "불금 한잔"(술 한잔) 숨김.
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsNothing);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — `SelectedDaySummary`에 `filterCount` 없음 / 영구 저장 미구현.

- [ ] **Step 3: `selected_day_summary.dart` 전체 교체**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

class SelectedDaySummary extends StatelessWidget {
  const SelectedDaySummary({
    super.key,
    required this.selectedDay,
    required this.meetingCount,
    required this.filterCount,
  });

  final DateTime selectedDay;
  final int meetingCount;
  final int filterCount;

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
          Text('필터 $filterCount개 · 모임 $meetingCount개',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: `home_screen.dart` 전체 교체**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/filter_storage.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting_filter.dart';
import '../../theme/app_colors.dart';
import '../filter/filter_screen.dart';
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
  static final DateTime _today = DateTime(2026, 5, 16);

  final MeetingRepository _repository = MeetingRepository();
  final FilterStorage _storage = FilterStorage();
  late DateTime _windowStart = weekStartOf(_today);
  late DateTime _selectedDay = _today;
  MeetingFilter _filter = const MeetingFilter.empty();

  @override
  void initState() {
    super.initState();
    _loadFilter();
  }

  Future<void> _loadFilter() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _filter = loaded);
  }

  void _goToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _windowStart = windowFollowing(_windowStart, day);
    });
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push<MeetingFilter>(
      context,
      MaterialPageRoute(builder: (_) => FilterScreen(initial: _filter)),
    );
    if (result != null) {
      setState(() => _filter = result);
      await _storage.save(result);
    }
  }

  String _monthLabel() {
    final days = twoWeekGridFrom(_windowStart);
    final first = days.first;
    final last = days.last;
    if (first.month == last.month) {
      return DateFormat('y년 M월', 'ko_KR').format(first);
    }
    return '${first.year}년 ${first.month}–${last.month}월';
  }

  @override
  Widget build(BuildContext context) {
    final dayMeetings =
        _repository.meetingsOn(_selectedDay).where(_filter.matches).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(monthLabel: _monthLabel()),
            const SizedBox(height: 8),
            FilterBar(activeCount: _filter.activeCount, onTap: _openFilter),
            TwoWeekCalendar(
              windowStart: _windowStart,
              selectedDay: _selectedDay,
              today: _today,
              repository: _repository,
              filter: _filter,
              onDaySelected: _goToDay,
              onWindowChanged: (ws) => setState(() => _windowStart = ws),
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
              filterCount: _filter.activeCount,
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _selectedDay,
                today: _today,
                repository: _repository,
                filter: _filter,
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

- [ ] **Step 5: 홈 테스트 통과 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 6: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 전체 PASS.

- [ ] **Step 7: 커밋**

```bash
git add -A && git commit -m "feat: persist filter on launch and show filter count in summary"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시): 필터 저장 후 앱 재시작에도 유지, 장소 상세에서 기기 뒤로가기 시 시/도 목록 복귀, 홈 요약이 "필터 N개 · 모임 M개"로 표시.

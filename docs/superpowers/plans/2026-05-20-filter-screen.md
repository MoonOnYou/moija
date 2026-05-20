# 필터 화면 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 필터 바를 누르면 카테고리·장소(드릴다운 다중)·시간대를 고르는 필터 화면으로 이동하고, 저장 시 홈의 달력·리스트 모임이 실제로 걸러진다.

**Architecture:** 순수 데이터/모델(TimeBand, LocationCatalog, MeetingFilter)을 먼저 만들고, 화면(LocationPicker, FilterScreen)을 새 파일로 추가한 뒤, 마지막에 홈에 배선·적용한다. 필터 적용은 위젯에 `MeetingFilter`(기본 빈=전체)를 내려 `repository.meetingsOn(date)` 결과를 거른다.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-filter-screen-design.md`
**고정 "오늘":** 2026-05-16.

> 데이터 마이그레이션(T3)은 공유 모델을 바꾸므로 전체 테스트를 실행한다. T5·T6는 새 파일이라 단일 파일 테스트. T7(통합)에서 전체 검증.

---

## File Structure

| 파일 | 변경 |
|------|------|
| `lib/models/time_band.dart` | 신규: 시간대 enum |
| `lib/models/location_node.dart` | 신규: 장소 리프 노드 |
| `lib/data/location_catalog.dart` | 신규: 대표 서브셋 카탈로그 |
| `lib/models/meeting_category.dart` | 10종으로 교체 |
| `lib/models/meeting.dart` | `locationId` 추가 |
| `lib/data/meeting_repository.dart` | 카테고리 재매핑 + locationId 태그 |
| `lib/models/meeting_filter.dart` | 신규: 필터 모델 + matches |
| `lib/features/filter/location_picker_screen.dart` | 신규 |
| `lib/features/filter/filter_screen.dart` | 신규 |
| `lib/features/home/widgets/filter_bar.dart` | 탭 가능 + 활성 개수 |
| `lib/features/home/widgets/two_week_calendar.dart` | `filter` 적용 |
| `lib/features/home/widgets/day_meetings_pager.dart` | `filter` 적용 |
| `lib/features/home/home_screen.dart` | 필터 상태·내비·적용 |
| 테스트 | time_band/location_catalog/meeting_filter/filter_screen/location_picker + home_screen 갱신 |

---

## Task 1: 시간대 enum (`time_band.dart`)

**Files:**
- Create: `lib/models/time_band.dart`
- Test: `test/time_band_test.dart`

- [ ] **Step 1: 실패 테스트**

`test/time_band_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/time_band.dart';

void main() {
  test('containsHour boundaries', () {
    expect(TimeBand.morning.containsHour(6), isTrue);
    expect(TimeBand.morning.containsHour(5), isFalse);
    expect(TimeBand.morning.containsHour(12), isFalse);
    expect(TimeBand.afternoon.containsHour(12), isTrue);
    expect(TimeBand.afternoon.containsHour(18), isFalse);
    expect(TimeBand.evening.containsHour(18), isTrue);
    expect(TimeBand.evening.containsHour(21), isFalse);
    expect(TimeBand.night.containsHour(21), isTrue);
    expect(TimeBand.night.containsHour(23), isTrue);
  });

  test('labels and ranges', () {
    expect(TimeBand.morning.label, '오전');
    expect(TimeBand.afternoon.range, '12–18시');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/time_band_test.dart`
Expected: FAIL — `TimeBand` 없음.

- [ ] **Step 3: 구현**

`lib/models/time_band.dart`:

```dart
/// 하루를 4개 시간대로 나눈다.
enum TimeBand {
  morning('오전', '06–12시', 6, 12),
  afternoon('오후', '12–18시', 12, 18),
  evening('저녁', '18–21시', 18, 21),
  night('밤', '21–24시', 21, 24);

  const TimeBand(this.label, this.range, this.startHour, this.endHour);

  final String label;
  final String range;
  final int startHour;
  final int endHour;

  /// [hour]가 이 시간대에 속하는지. (시작 포함, 끝 제외)
  bool containsHour(int hour) => hour >= startHour && hour < endHour;
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/time_band_test.dart`
Expected: PASS.

- [ ] **Step 5: 커밋**

```bash
git add lib/models/time_band.dart test/time_band_test.dart && git commit -m "feat: add TimeBand"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: 장소 노드 + 카탈로그 (`location_node.dart`, `location_catalog.dart`)

**Files:**
- Create: `lib/models/location_node.dart`
- Create: `lib/data/location_catalog.dart`
- Test: `test/location_catalog_test.dart`

- [ ] **Step 1: 실패 테스트**

`test/location_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/location_catalog.dart';

void main() {
  test('regions are the 8 시/도 in order', () {
    expect(LocationCatalog.regions.first, '서울');
    expect(LocationCatalog.regions.length, 8);
  });

  test('서울 has 9 subway lines', () {
    final seoul = LocationCatalog.nodesIn('서울');
    expect(seoul.length, 9);
    expect(seoul.any((n) => n.id == 'seoul-line2'), isTrue);
  });

  test('전라 is grouped into 2 권역', () {
    expect(LocationCatalog.nodesIn('전라').length, 2);
  });

  test('nodeById resolves label', () {
    expect(LocationCatalog.nodeById('seoul-line2')?.label, '2호선');
    expect(LocationCatalog.nodeById('nope'), isNull);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/location_catalog_test.dart`
Expected: FAIL — `LocationCatalog` 없음.

- [ ] **Step 3: 구현**

`lib/models/location_node.dart`:

```dart
/// 장소 트리의 리프 노드(지하철 호선/구/권역).
class LocationNode {
  const LocationNode({
    required this.id,
    required this.label,
    required this.region,
  });

  final String id;
  final String label;
  final String region;
}
```

`lib/data/location_catalog.dart`:

```dart
import '../models/location_node.dart';

/// 대표 서브셋 장소 카탈로그(하드코딩). 전국 전수 데이터는 범위 밖.
class LocationCatalog {
  static const List<String> regions = [
    '서울', '경기', '인천', '대전', '대구', '부산', '광주', '전라',
  ];

  static const Map<String, List<LocationNode>> _byRegion = {
    '서울': [
      LocationNode(id: 'seoul-line1', label: '1호선', region: '서울'),
      LocationNode(id: 'seoul-line2', label: '2호선', region: '서울'),
      LocationNode(id: 'seoul-line3', label: '3호선', region: '서울'),
      LocationNode(id: 'seoul-line4', label: '4호선', region: '서울'),
      LocationNode(id: 'seoul-line5', label: '5호선', region: '서울'),
      LocationNode(id: 'seoul-line6', label: '6호선', region: '서울'),
      LocationNode(id: 'seoul-line7', label: '7호선', region: '서울'),
      LocationNode(id: 'seoul-line8', label: '8호선', region: '서울'),
      LocationNode(id: 'seoul-line9', label: '9호선', region: '서울'),
    ],
    '경기': [
      LocationNode(id: 'gg-suwon', label: '수원시', region: '경기'),
      LocationNode(id: 'gg-seongnam', label: '성남시', region: '경기'),
      LocationNode(id: 'gg-goyang', label: '고양시', region: '경기'),
      LocationNode(id: 'gg-yongin', label: '용인시', region: '경기'),
    ],
    '인천': [
      LocationNode(id: 'incheon-line1', label: '인천1호선', region: '인천'),
      LocationNode(id: 'incheon-line2', label: '인천2호선', region: '인천'),
    ],
    '대전': [
      LocationNode(id: 'daejeon-line1', label: '대전1호선', region: '대전'),
    ],
    '대구': [
      LocationNode(id: 'daegu-line1', label: '대구1호선', region: '대구'),
      LocationNode(id: 'daegu-line2', label: '대구2호선', region: '대구'),
    ],
    '부산': [
      LocationNode(id: 'busan-line1', label: '부산1호선', region: '부산'),
      LocationNode(id: 'busan-line2', label: '부산2호선', region: '부산'),
    ],
    '광주': [
      LocationNode(id: 'gwangju-line1', label: '광주1호선', region: '광주'),
    ],
    '전라': [
      LocationNode(id: 'jeolla-jeonju', label: '전주권', region: '전라'),
      LocationNode(id: 'jeolla-yeosuncheon', label: '여수·순천권', region: '전라'),
    ],
  };

  static List<LocationNode> nodesIn(String region) =>
      _byRegion[region] ?? const [];

  static LocationNode? nodeById(String id) {
    for (final list in _byRegion.values) {
      for (final node in list) {
        if (node.id == id) return node;
      }
    }
    return null;
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/location_catalog_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/models/location_node.dart lib/data/location_catalog.dart test/location_catalog_test.dart && git commit -m "feat: add location catalog (representative subset)"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 3: 카테고리 10종 + Meeting.locationId + 시드 (데이터 마이그레이션)

**Files:**
- Modify: `lib/models/meeting_category.dart` (전체 교체)
- Modify: `lib/models/meeting.dart` (전체 교체)
- Modify: `lib/data/meeting_repository.dart` (전체 교체)
- Modify: `test/meeting_test.dart` (locationId 추가)
- Modify: `test/day_cell_test.dart` (헬퍼에 locationId 추가)

> 공유 모델 변경. 한 번에 바꿔 트리를 컴파일 가능하게 유지하고 전체 테스트로 검증.

- [ ] **Step 1: `meeting_test.dart` 갱신(실패 유도)**

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
      locationId: 'seoul-line2',
      currentMembers: 2,
      maxMembers: 4,
    );
    expect(m.spotsLeft, 2);
    expect(m.locationId, 'seoul-line2');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_test.dart`
Expected: FAIL — `locationId` 명명 인자 없음.

- [ ] **Step 3: `meeting_category.dart` 전체 교체(10종)**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 모임 카테고리. 칩/아이콘/색상 정보를 함께 갖는다.
enum MeetingCategory {
  escapeRoom('방탈출', Icons.vpn_key, AppColors.bgInfo, AppColors.textInfo),
  bowling('볼링', Icons.sports_handball, AppColors.bgInfo, AppColors.textInfo),
  karaoke('노래방', Icons.mic, AppColors.bgWarning, AppColors.textWarning),
  drink('술 한잔', Icons.local_bar, AppColors.bgWarning, AppColors.textWarning),
  cafe('카페', Icons.local_cafe, AppColors.bgWarning, AppColors.textWarning),
  hiking('등산', Icons.terrain, AppColors.bgSuccess, AppColors.textSuccess),
  swimming('수영', Icons.pool, AppColors.bgSuccess, AppColors.textSuccess),
  boardGame('보드게임', Icons.casino, AppColors.bgSuccess, AppColors.textSuccess),
  lol('롤', Icons.sports_esports, AppColors.bgInfo, AppColors.textInfo),
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

- [ ] **Step 4: `meeting.dart` 전체 교체(locationId 추가)**

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
    required this.locationId,
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

  /// 장소 카탈로그 노드 id(예: "seoul-line2"). 장소 필터에 사용.
  final String locationId;

  final int currentMembers;
  final int maxMembers;

  int get spotsLeft => maxMembers - currentMembers;
}
```

- [ ] **Step 5: `meeting_repository.dart` 전체 교체(카테고리 재매핑 + locationId 태그)**

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

  List<Meeting> meetingsOn(DateTime day) =>
      List.unmodifiable(_byDay[_key(day)] ?? const []);

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

  // 시드의 region(신림/강남/홍대/잠실)은 모두 서울 2호선 권역 → locationId 'seoul-line2'.
  static final List<Meeting> _seed = [
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
  ];
}
```

- [ ] **Step 6: `day_cell_test.dart` 헬퍼에 locationId 추가**

`test/day_cell_test.dart`의 `_meeting` 헬퍼에서 `Meeting(...)` 생성자에 `region: '신림',` 다음 줄에 `locationId: 'seoul-line2',`를 추가한다. (다른 부분은 그대로)

- [ ] **Step 7: 전체 테스트 통과 확인**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 전체 PASS. (home_screen_test의 "방탈출 호러 테마 같이!"·"주말 관악산 등반"·"퇴근 후 볼링"·5/18 빈 날짜는 그대로 유지됨)

- [ ] **Step 8: 커밋**

```bash
git add -A && git commit -m "feat: 10 categories + meeting locationId tags"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 4: 필터 모델 (`meeting_filter.dart`)

**Files:**
- Create: `lib/models/meeting_filter.dart`
- Test: `test/meeting_filter_test.dart`

- [ ] **Step 1: 실패 테스트**

`test/meeting_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_filter.dart';
import 'package:moija/models/time_band.dart';

Meeting _m({
  MeetingCategory category = MeetingCategory.bowling,
  String locationId = 'seoul-line2',
  int hour = 20,
}) =>
    Meeting(
      id: 'x',
      title: 't',
      category: category,
      startTime: DateTime(2026, 5, 16, hour),
      location: 'loc',
      region: 'r',
      locationId: locationId,
      currentMembers: 1,
      maxMembers: 4,
    );

void main() {
  test('empty filter matches everything', () {
    const f = MeetingFilter.empty();
    expect(f.isEmpty, isTrue);
    expect(f.matches(_m()), isTrue);
  });

  test('category filter', () {
    const f = MeetingFilter(categories: {MeetingCategory.bowling});
    expect(f.matches(_m(category: MeetingCategory.bowling)), isTrue);
    expect(f.matches(_m(category: MeetingCategory.cafe)), isFalse);
  });

  test('location filter', () {
    const f = MeetingFilter(locationIds: {'seoul-line2'});
    expect(f.matches(_m(locationId: 'seoul-line2')), isTrue);
    expect(f.matches(_m(locationId: 'seoul-line3')), isFalse);
  });

  test('time band filter', () {
    const f = MeetingFilter(timeBands: {TimeBand.evening});
    expect(f.matches(_m(hour: 19)), isTrue); // 18-21
    expect(f.matches(_m(hour: 9)), isFalse);
  });

  test('combined filter requires all sections', () {
    const f = MeetingFilter(
      categories: {MeetingCategory.bowling},
      timeBands: {TimeBand.evening},
    );
    expect(f.matches(_m(category: MeetingCategory.bowling, hour: 19)), isTrue);
    expect(f.matches(_m(category: MeetingCategory.bowling, hour: 9)), isFalse);
  });

  test('activeCount sums selections', () {
    const f = MeetingFilter(
      categories: {MeetingCategory.bowling, MeetingCategory.cafe},
      timeBands: {TimeBand.evening},
    );
    expect(f.activeCount, 3);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_filter_test.dart`
Expected: FAIL — `MeetingFilter` 없음.

- [ ] **Step 3: 구현**

`lib/models/meeting_filter.dart`:

```dart
import 'meeting.dart';
import 'meeting_category.dart';
import 'time_band.dart';

/// 모임 필터 선택값 + 매칭 로직(순수).
class MeetingFilter {
  const MeetingFilter({
    this.categories = const {},
    this.locationIds = const {},
    this.timeBands = const {},
    this.customCategories = const {},
  });

  const MeetingFilter.empty()
      : categories = const {},
        locationIds = const {},
        timeBands = const {},
        customCategories = const {};

  final Set<MeetingCategory> categories;
  final Set<String> locationIds;
  final Set<TimeBand> timeBands;

  /// 직접 입력한 카테고리. 저장·표시되나 목 데이터 매칭엔 미적용.
  final Set<String> customCategories;

  bool get isEmpty =>
      categories.isEmpty &&
      locationIds.isEmpty &&
      timeBands.isEmpty &&
      customCategories.isEmpty;

  int get activeCount =>
      categories.length +
      locationIds.length +
      timeBands.length +
      customCategories.length;

  /// 빈 섹션은 제약 없음. 채워진 섹션은 모두(AND) 만족해야 통과.
  bool matches(Meeting m) {
    if (categories.isNotEmpty && !categories.contains(m.category)) {
      return false;
    }
    if (locationIds.isNotEmpty && !locationIds.contains(m.locationId)) {
      return false;
    }
    if (timeBands.isNotEmpty &&
        !timeBands.any((b) => b.containsHour(m.startTime.hour))) {
      return false;
    }
    return true;
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/meeting_filter_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/models/meeting_filter.dart test/meeting_filter_test.dart && git commit -m "feat: add MeetingFilter with matching logic"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 5: 장소 선택 화면 (`location_picker_screen.dart`)

**Files:**
- Create: `lib/features/filter/location_picker_screen.dart`
- Test: `test/location_picker_screen_test.dart`

> 새 파일. 단일 파일 테스트.

- [ ] **Step 1: 실패 테스트**

`test/location_picker_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/filter/location_picker_screen.dart';

void main() {
  testWidgets('drill into 서울, select 2호선, 완료 returns the node id',
      (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LocationPickerScreen(initial: {}),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2'));
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: FAIL — `LocationPickerScreen` 없음.

- [ ] **Step 3: 구현**

`lib/features/filter/location_picker_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../data/location_catalog.dart';
import '../../theme/app_colors.dart';

/// 시/도 목록 ↔ 지역 상세(리프 다중 체크) 드릴다운. 완료 시 선택 id 집합 반환.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.initial});

  final Set<String> initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final Set<String> _selected = {...widget.initial};
  String? _region; // null = 시/도 목록, else 해당 지역 상세

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Expanded(child: _region == null ? _regionList() : _nodeList(_region!)),
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
    );
  }

  Widget _selectedChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderTertiary, width: 0.5),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final id in _selected)
            GestureDetector(
              onTap: () => _toggle(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.textInfo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${LocationCatalog.nodeById(id)?.label ?? id} ✕',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _regionList() {
    return ListView(
      children: [
        for (final region in LocationCatalog.regions)
          ListTile(
            title: Text(region),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () => setState(() => _region = region),
          ),
      ],
    );
  }

  Widget _nodeList(String region) {
    final nodes = LocationCatalog.nodesIn(region);
    return ListView(
      children: [
        for (final node in nodes)
          CheckboxListTile(
            value: _selected.contains(node.id),
            title: Text(node.label),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (_) => _toggle(node.id),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/filter/location_picker_screen.dart test/location_picker_screen_test.dart && git commit -m "feat: add LocationPickerScreen"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 6: 필터 화면 (`filter_screen.dart`)

**Files:**
- Create: `lib/features/filter/filter_screen.dart`
- Test: `test/filter_screen_test.dart`

> 새 파일. 단일 파일 테스트.

- [ ] **Step 1: 실패 테스트**

`test/filter_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/filter/filter_screen.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_filter.dart';
import 'package:moija/models/time_band.dart';

class _Holder {
  MeetingFilter? value;
}

Widget _host(_Holder holder) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                holder.value = await Navigator.push<MeetingFilter>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FilterScreen(initial: MeetingFilter.empty()),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('selecting category + time band and saving returns them',
      (tester) async {
    final holder = _Holder();
    await tester.pumpWidget(_host(holder));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방탈출'));
    await tester.pump();
    await tester.tap(find.text('저녁'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(holder.value!.categories, contains(MeetingCategory.escapeRoom));
    expect(holder.value!.timeBands, contains(TimeBand.evening));
  });

  testWidgets('reset clears selections before saving', (tester) async {
    final holder = _Holder();
    await tester.pumpWidget(_host(holder));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방탈출'));
    await tester.pump();
    await tester.tap(find.text('초기화'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(holder.value!.isEmpty, isTrue);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/filter_screen_test.dart`
Expected: FAIL — `FilterScreen` 없음.

- [ ] **Step 3: 구현**

`lib/features/filter/filter_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../data/location_catalog.dart';
import '../../models/meeting_category.dart';
import '../../models/meeting_filter.dart';
import '../../models/time_band.dart';
import '../../theme/app_colors.dart';
import 'location_picker_screen.dart';

/// 카테고리·장소·시간대 필터 화면. 저장 시 MeetingFilter를 pop으로 반환.
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key, required this.initial});

  final MeetingFilter initial;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late final Set<MeetingCategory> _categories = {...widget.initial.categories};
  late final Set<String> _locationIds = {...widget.initial.locationIds};
  late final Set<TimeBand> _timeBands = {...widget.initial.timeBands};
  late final Set<String> _customCategories = {...widget.initial.customCategories};

  void _reset() {
    setState(() {
      _categories.clear();
      _locationIds.clear();
      _timeBands.clear();
      _customCategories.clear();
    });
  }

  void _save() {
    Navigator.pop(
      context,
      MeetingFilter(
        categories: {..._categories},
        locationIds: {..._locationIds},
        timeBands: {..._timeBands},
        customCategories: {..._customCategories},
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _locationIds),
      ),
    );
    if (result != null) {
      setState(() {
        _locationIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('직접 입력'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      setState(() => _customCategories.add(text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('필터'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('카테고리 (여러 개 선택)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in MeetingCategory.values)
                _chip(
                  c.label,
                  _categories.contains(c),
                  () => setState(() {
                    if (!_categories.add(c)) _categories.remove(c);
                  }),
                ),
              for (final custom in _customCategories)
                _chip(custom, true,
                    () => setState(() => _customCategories.remove(custom))),
              _dashedChip('+ 직접 입력하기', _addCustom),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('장소'),
          GestureDetector(
            onTap: _openLocationPicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderTertiary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _locationIds.isEmpty
                          ? '지역 선택'
                          : _locationIds
                              .map((id) =>
                                  LocationCatalog.nodeById(id)?.label ?? id)
                              .join(', '),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('시간대 (여러 개 선택)'),
          Row(
            children: [
              for (final b in TimeBand.values) ...[
                Expanded(child: _timeChip(b)),
                if (b != TimeBand.night) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('저장하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.textInfo : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          selected ? '$label ✓' : label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _dashedChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textTertiary),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _timeChip(TimeBand band) {
    final selected = _timeBands.contains(band);
    return GestureDetector(
      onTap: () => setState(() {
        if (!_timeBands.add(band)) _timeBands.remove(band);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.textInfo : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(band.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(band.range,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white70 : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/filter_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/filter/filter_screen.dart test/filter_screen_test.dart && git commit -m "feat: add FilterScreen"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## Task 7: 홈 배선 + 필터 적용 (통합)

**Files:**
- Modify: `lib/features/home/widgets/filter_bar.dart` (전체 교체)
- Modify: `lib/features/home/widgets/two_week_calendar.dart` (filter 적용)
- Modify: `lib/features/home/widgets/day_meetings_pager.dart` (filter 적용)
- Modify: `lib/features/home/home_screen.dart` (전체 교체)
- Modify: `test/home_screen_test.dart` (필터 적용/바 탭 테스트 추가)

- [ ] **Step 1: 홈 테스트 갱신(실패 유도 — 필터 적용/바 탭)**

`test/home_screen_test.dart` 전체 교체:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/filter/filter_screen.dart';
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
    // 오늘(5/16) 모임: "퇴근 후 볼링"(볼링), "불금 한잔"(술 한잔).
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsOneWidget);

    // 필터 열기 → 볼링만 선택 → 저장.
    await tester.tap(find.byKey(const Key('filter-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('볼링'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsNothing);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — FilterBar에 key/onTap 없음, 필터 미적용.

- [ ] **Step 3: `filter_bar.dart` 전체 교체(탭 가능 + 활성 개수)**

```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// 홈 상단 필터 진입 바. 탭하면 필터 화면으로 이동. 활성 필터 개수를 배지로 표시.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('filter-bar'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderTertiary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Text('필터',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            if (activeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.textInfo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$activeCount',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            const Spacer(),
            const Text('카테고리 · 장소 · 시간',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: `two_week_calendar.dart`에 filter 적용**

`lib/features/home/widgets/two_week_calendar.dart`에 필터를 추가한다:
1) import 추가: 파일 상단 import 목록에 `import '../../../models/meeting_filter.dart';` 추가.
2) 위젯에 필드/생성자 인자 추가 — 생성자에 `this.filter = const MeetingFilter.empty(),` 추가하고, 필드 선언부에 `final MeetingFilter filter;` 추가.
3) `_weekRow`에서 `meetings:` 인자를 필터 적용 결과로 바꾼다:

from:
```dart
                    meetings: widget.repository.meetingsOn(date),
```
to:
```dart
                    meetings: widget.repository
                        .meetingsOn(date)
                        .where(widget.filter.matches)
                        .toList(),
```

- [ ] **Step 5: `day_meetings_pager.dart`에 filter 적용**

`lib/features/home/widgets/day_meetings_pager.dart`:
1) import 추가: `import '../../../models/meeting_filter.dart';`
2) 생성자에 `this.filter = const MeetingFilter.empty(),` 추가, 필드 `final MeetingFilter filter;` 추가.
3) `itemBuilder` 안의 meetings 계산을 필터 적용으로 변경:

from:
```dart
        final meetings = widget.repository.meetingsOn(_dateOf(page));
```
to:
```dart
        final meetings = widget.repository
            .meetingsOn(_dateOf(page))
            .where(widget.filter.matches)
            .toList();
```

- [ ] **Step 6: `home_screen.dart` 전체 교체**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late DateTime _windowStart = weekStartOf(_today);
  late DateTime _selectedDay = _today;
  MeetingFilter _filter = const MeetingFilter.empty();

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
    if (result != null) setState(() => _filter = result);
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

- [ ] **Step 7: 홈 테스트 통과 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 8: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 전체 PASS.

- [ ] **Step 9: 커밋**

```bash
git add -A && git commit -m "feat: wire filter screen into home and apply filtering"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시): 필터 바 탭 → 필터 화면 이동, 카테고리/장소(드릴다운 다중)/시간대 선택, 직접 입력 추가, 초기화·저장, 저장 후 홈 달력·리스트가 선택대로 걸러짐.
```

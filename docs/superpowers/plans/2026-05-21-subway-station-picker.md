# 지하철 노선 → 역 3단계 선택 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 위치 선택 화면에서 지하철 노선을 고르면 한 단계 더 들어가 역까지 고를 수 있게 하고(필터·모임 만들기 공용), "노선 전체" 옵션 + 접두사 계층 매칭으로 기존 시드와 호환되게 한다.

**Architecture:** 역 데이터는 새 파일 `subway_stations.dart`(노선 id→역 이름 목록)에 두고, `LocationCatalog`이 역 노드를 생성하며 `childrenOf`/`nodeById`를 확장한다. `LocationPickerScreen`을 2단계→3단계로 일반화한다(시/도 → 노선/리프 → 역). 필터 매칭은 `MeetingFilter.matches`에서 접두사 규칙으로 계층화한다. 모임 생성/시드 코드는 변경 없음(피커가 반환하는 id를 그대로 사용).

**Tech Stack:** Flutter (Material 3), Dart, flutter_test 위젯 테스트.

---

## File Structure

- Create: `lib/data/subway_stations.dart` — 노선 id별 실제 역 이름 목록(`kSubwayStations`)
- Modify: `lib/data/location_catalog.dart` — 역 노드 생성 + `childrenOf` + `nodeById` 확장
- Modify: `lib/models/meeting_filter.dart` — 위치 접두사 계층 매칭
- Modify: `lib/features/filter/location_picker_screen.dart` — 3단계 드릴다운
- Modify (tests): `test/subway_stations_test.dart`(신규), `test/location_catalog_test.dart`, `test/meeting_filter_test.dart`, `test/location_picker_screen_test.dart`, `test/create_meeting_screen_test.dart`

---

## Task 1: 역 데이터 파일

**Files:**
- Create: `lib/data/subway_stations.dart`
- Test: `test/subway_stations_test.dart`

- [ ] **Step 1: Write the failing test**

`test/subway_stations_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/subway_stations.dart';

void main() {
  test('서울 2호선은 강남·시청 포함, 40역 이상', () {
    final line2 = kSubwayStations['seoul-line2']!;
    expect(line2, contains('강남'));
    expect(line2, contains('시청'));
    expect(line2.length, greaterThan(40));
  });

  test('모든 광역시 노선 id 키가 존재한다', () {
    expect(
      kSubwayStations.keys,
      containsAll(<String>[
        'seoul-line1', 'seoul-line2', 'seoul-line3', 'seoul-line4',
        'seoul-line5', 'seoul-line6', 'seoul-line7', 'seoul-line8', 'seoul-line9',
        'busan-line1', 'busan-line2', 'busan-line3', 'busan-line4',
        'daegu-line1', 'daegu-line2', 'daegu-line3',
        'incheon-line1', 'incheon-line2',
        'gwangju-line1', 'daejeon-line1',
      ]),
    );
  });

  test('역 이름에는 매칭 구분자 - 가 없다', () {
    for (final stations in kSubwayStations.values) {
      for (final s in stations) {
        expect(s.contains('-'), isFalse, reason: '역명에 - 포함: $s');
      }
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/subway_stations_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moija/data/subway_stations.dart'`

- [ ] **Step 3: Write the data file**

Create `lib/data/subway_stations.dart` with EXACTLY this content (키는 `location_catalog.dart`의 노선 노드 id와 일치, 값은 실제 운영 역명을 기점→종점 순으로 나열):

```dart
/// 노선 id → 역 이름 목록(기점→종점 순). 광역시 도시철도 실제 운영 역(목업 데이터).
/// 키는 LocationCatalog의 노선 노드 id와 일치해야 한다.
/// 역명에는 매칭 구분자 '-'를 포함하지 않는다.
const Map<String, List<String>> kSubwayStations = {
  // ── 서울 ──────────────────────────────────────────────
  'seoul-line1': [
    '소요산', '동두천', '보산', '동두천중앙', '지행', '덕정', '덕계', '양주',
    '녹양', '가능', '의정부', '회룡', '망월사', '도봉산', '도봉', '방학', '창동',
    '녹천', '월계', '광운대', '석계', '신이문', '외대앞', '회기', '청량리',
    '제기동', '신설동', '동묘앞', '동대문', '종로5가', '종로3가', '종각', '시청',
    '서울역', '남영', '용산', '노량진', '대방', '신길', '영등포', '신도림', '구로',
    '가산디지털단지', '독산', '금천구청', '석수', '관악', '안양', '명학', '금정',
    '군포', '당정', '의왕', '성균관대', '화서', '수원', '세류', '병점', '세마',
    '오산대', '오산', '진위', '송탄', '서정리', '평택지제', '평택', '성환', '직산',
    '두정', '천안', '봉명', '쌍용', '아산', '탕정', '배방', '온양온천', '신창',
  ],
  'seoul-line2': [
    '시청', '을지로입구', '을지로3가', '을지로4가', '동대문역사문화공원', '신당',
    '상왕십리', '왕십리', '한양대', '뚝섬', '성수', '건대입구', '구의', '강변',
    '잠실나루', '잠실', '잠실새내', '종합운동장', '삼성', '선릉', '역삼', '강남',
    '교대', '서초', '방배', '사당', '낙성대', '서울대입구', '봉천', '신림', '신대방',
    '구로디지털단지', '대림', '신도림', '문래', '영등포구청', '당산', '합정',
    '홍대입구', '신촌', '이대', '아현', '충정로',
    '용답', '신답', '용두', '신설동',
    '도림천', '양천구청', '신정네거리', '까치산',
  ],
  'seoul-line3': [
    '대화', '주엽', '정발산', '마두', '백석', '대곡', '화정', '원당', '원흥',
    '삼송', '지축', '구파발', '연신내', '불광', '녹번', '홍제', '무악재', '독립문',
    '경복궁', '안국', '종로3가', '을지로3가', '충무로', '동대입구', '약수', '금호',
    '옥수', '압구정', '신사', '잠원', '고속터미널', '교대', '남부터미널', '양재',
    '매봉', '도곡', '대치', '학여울', '대청', '일원', '수서', '가락시장', '경찰병원',
    '오금',
  ],
  'seoul-line4': [
    '당고개', '상계', '노원', '창동', '쌍문', '수유', '미아', '미아사거리', '길음',
    '성신여대입구', '한성대입구', '혜화', '동대문', '동대문역사문화공원', '충무로',
    '명동', '회현', '서울역', '숙대입구', '삼각지', '신용산', '이촌', '동작',
    '총신대입구', '사당', '남태령', '선바위', '경마공원', '대공원', '과천', '정부과천청사',
    '인덕원', '평촌', '범계', '금정', '산본', '수리산', '대야미', '반월', '상록수',
    '한대앞', '중앙', '고잔', '초지', '안산', '신길온천', '정왕', '오이도',
  ],
  'seoul-line5': [
    '방화', '개화산', '김포공항', '송정', '마곡', '발산', '우장산', '화곡', '까치산',
    '신정', '목동', '오목교', '양평', '영등포구청', '영등포시장', '신길', '여의도',
    '여의나루', '마포', '공덕', '애오개', '충정로', '서대문', '광화문', '종로3가',
    '을지로4가', '동대문역사문화공원', '청구', '신금호', '행당', '왕십리', '마장',
    '답십리', '장한평', '군자', '아차산', '광나루', '천호', '강동', '길동', '굽은다리',
    '명일', '고덕', '상일동', '강일', '미사', '하남풍산', '하남시청', '하남검단산',
    '둔촌동', '올림픽공원', '방이', '오금', '개롱', '거여', '마천',
  ],
  'seoul-line6': [
    '응암', '역촌', '불광', '독바위', '연신내', '구산', '새절', '증산', '디지털미디어시티',
    '월드컵경기장', '마포구청', '망원', '합정', '상수', '광흥창', '대흥', '공덕', '효창공원앞',
    '삼각지', '녹사평', '이태원', '한강진', '버티고개', '약수', '청구', '신당', '동묘앞',
    '창신', '보문', '안암', '고려대', '월곡', '상월곡', '돌곶이', '석계', '태릉입구',
    '화랑대', '봉화산', '신내',
  ],
  'seoul-line7': [
    '장암', '도봉산', '수락산', '마들', '노원', '중계', '하계', '공릉', '태릉입구',
    '먹골', '중화', '상봉', '면목', '사가정', '용마산', '중곡', '군자', '어린이대공원',
    '건대입구', '뚝섬유원지', '청담', '강남구청', '학동', '논현', '반포', '고속터미널',
    '내방', '이수', '남성', '숭실대입구', '상도', '장승배기', '신대방삼거리', '보라매',
    '신풍', '대림', '남구로', '가산디지털단지', '철산', '광명사거리', '천왕', '온수',
    '까치울', '부천종합운동장', '춘의', '신중동', '부천시청', '상동', '삼산체육관',
    '굴포천', '부평구청', '산곡', '석남',
  ],
  'seoul-line8': [
    '암사', '천호', '강동구청', '몽촌토성', '잠실', '석촌', '송파', '가락시장',
    '문정', '장지', '복정', '남위례', '산성', '남한산성입구', '단대오거리', '신흥',
    '수진', '모란',
  ],
  'seoul-line9': [
    '개화', '김포공항', '공항시장', '신방화', '마곡나루', '양천향교', '가양', '증미',
    '등촌', '염창', '신목동', '선유도', '당산', '국회의사당', '여의도', '샛강', '노량진',
    '노들', '흑석', '동작', '구반포', '신반포', '고속터미널', '사평', '신논현', '언주',
    '선정릉', '삼성중앙', '봉은사', '종합운동장', '삼전', '석촌고분', '석촌', '송파나루',
    '한성백제', '올림픽공원', '둔촌오륜', '중앙보훈병원',
  ],

  // ── 부산 ──────────────────────────────────────────────
  'busan-line1': [
    '다대포해수욕장', '다대포항', '낫개', '신장림', '장림', '동매', '신평', '하단',
    '당리', '사하', '괴정', '대티', '서대신', '동대신', '토성', '자갈치', '남포',
    '중앙', '부산역', '초량', '부산진', '좌천', '범일', '범내골', '서면', '부전',
    '양정', '시청', '연산', '교대', '동래', '명륜', '온천장', '부산대', '장전',
    '구서', '두실', '남산', '범어사', '노포',
  ],
  'busan-line2': [
    '장산', '중동', '해운대', '동백', '벡스코', '센텀시티', '민락', '수영', '광안',
    '금련산', '남천', '경성대부경대', '대연', '못골', '지게골', '문현', '국제금융센터부산은행',
    '전포', '서면', '부암', '가야', '동의대', '개금', '냉정', '주례', '감전', '사상',
    '덕포', '모덕', '모라', '구남', '구명', '덕천', '수정', '화명', '율리', '동원',
    '금곡', '호포', '증산', '부산대양산캠퍼스', '남양산', '양산',
  ],
  'busan-line3': [
    '수영', '망미', '배산', '물만골', '연산', '거제', '종합운동장', '사직', '미남',
    '만덕', '남산정', '숙등', '덕천', '구포', '강서구청', '체육공원', '대저',
  ],
  'busan-line4': [
    '미남', '동래', '수안', '낙민', '충렬사', '명장', '서동', '금사', '반여농산물시장',
    '석대', '영산대', '윗반송', '고촌', '안평',
  ],

  // ── 대구 ──────────────────────────────────────────────
  'daegu-line1': [
    '설화명곡', '화원', '대곡', '진천', '월배', '상인', '월촌', '송현', '서부정류장',
    '대명', '안지랑', '현충로', '영대병원', '교대', '명덕', '반월당', '중앙로', '대구역',
    '칠성시장', '신천', '동대구', '동구청', '아양교', '동촌', '해안', '방촌', '용계',
    '율하', '신기', '반야월', '각산', '안심',
  ],
  'daegu-line2': [
    '문양', '다사', '대실', '강창', '계명대', '성서산업단지', '이곡', '용산', '죽전',
    '감삼', '두류', '내당', '반고개', '청라언덕', '반월당', '경대병원', '대구은행',
    '범어', '수성구청', '만촌', '담티', '연호', '대공원', '고산', '신매', '사월',
    '정평', '임당', '영남대',
  ],
  'daegu-line3': [
    '칠곡경대병원', '학정', '팔거', '동천', '칠곡운암', '구암', '태전', '매천',
    '매천시장', '팔달', '공단', '만평', '팔달시장', '원대', '북구청', '달성공원',
    '서문시장', '신남', '청라언덕', '남산', '명덕', '건들바위', '대봉교', '수성시장',
    '수성구민운동장', '어린이회관', '황금', '수성못', '지산', '범물', '용지',
  ],

  // ── 인천 ──────────────────────────────────────────────
  'incheon-line1': [
    '계양', '귤현', '박촌', '임학', '계산', '경인교대입구', '작전', '갈산', '부평구청',
    '부평시장', '부평', '동수', '부평삼거리', '간석오거리', '인천시청', '예술회관',
    '인천터미널', '문학경기장', '선학', '신연수', '원인재', '동춘', '동막', '캠퍼스타운',
    '테크노파크', '지식정보단지', '인천대입구', '센트럴파크', '국제업무지구', '송도달빛축제공원',
  ],
  'incheon-line2': [
    '검단오류', '왕길', '검단사거리', '마전', '완정', '독정', '검바위', '아시아드경기장',
    '서구청', '가정', '가정중앙시장', '석남', '서부여성회관', '인천가좌', '가재울',
    '주안국가산단', '주안', '시민공원', '석바위시장', '인천시청', '석천사거리',
    '모래내시장', '만수', '남동구청', '인천대공원', '운연',
  ],

  // ── 광주 ──────────────────────────────────────────────
  'gwangju-line1': [
    '녹동', '소태', '학동증심사입구', '남광주', '문화전당', '금남로4가', '금남로5가',
    '양동시장', '돌고개', '농성', '화정', '쌍촌', '운천', '상무', '김대중컨벤션센터',
    '마륵', '서구문화센터', '공항', '송정공원', '광주송정역', '도산', '평동',
  ],

  // ── 대전 ──────────────────────────────────────────────
  'daejeon-line1': [
    '판암', '신흥', '대동', '대전역', '중앙로', '중구청', '서대전네거리', '오룡',
    '용문', '탄방', '시청', '정부청사', '갈마', '월평', '갑천', '유성온천', '구암',
    '현충원', '월드컵경기장', '노은', '지족', '반석',
  ],
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/subway_stations_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/subway_stations.dart test/subway_stations_test.dart
git commit -m "feat: 광역시 지하철 역 데이터(subway_stations)"
```

---

## Task 2: LocationCatalog 역 노드 + childrenOf + nodeById 확장

**Files:**
- Modify: `lib/data/location_catalog.dart`
- Test: `test/location_catalog_test.dart`

- [ ] **Step 1: Write the failing test**

`test/location_catalog_test.dart`의 `void main() {` 안, 마지막 test 뒤에 추가:
```dart
  test('childrenOf returns station nodes for a subway line', () {
    final stations = LocationCatalog.childrenOf('seoul-line2');
    expect(stations, isNotEmpty);
    expect(stations.any((n) => n.id == 'seoul-line2-강남'), isTrue);
    expect(stations.first.region, '서울');
  });

  test('childrenOf is empty for 시·군 leaves and unknown ids', () {
    expect(LocationCatalog.childrenOf('경기-수원시'), isEmpty);
    expect(LocationCatalog.childrenOf('nope'), isEmpty);
  });

  test('nodeById resolves a station node', () {
    final n = LocationCatalog.nodeById('seoul-line2-강남');
    expect(n?.label, '강남');
    expect(n?.region, '서울');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/location_catalog_test.dart`
Expected: FAIL — `The method 'childrenOf' isn't defined for the type 'LocationCatalog'`

- [ ] **Step 3: Write minimal implementation**

In `lib/data/location_catalog.dart`, 상단 import에 추가:
```dart
import 'subway_stations.dart';
```

`nodesIn` 메서드 바로 위(클래스 내부, `_byRegion` 맵 정의 다음)에 다음을 추가:
```dart
  /// 노선 노드 id가 속한 시/도를 _byRegion에서만 찾는다(역 노드 초기화 전 호출 안전).
  static String _regionOfLineId(String lineId) {
    for (final entry in _byRegion.entries) {
      if (entry.value.any((n) => n.id == lineId)) return entry.key;
    }
    return '';
  }

  /// 노선 id → 역 노드 목록. kSubwayStations로부터 생성(지연 초기화).
  static final Map<String, List<LocationNode>> _stationsByLine = {
    for (final entry in kSubwayStations.entries)
      entry.key: [
        for (final name in entry.value)
          LocationNode(
            id: '${entry.key}-$name',
            label: name,
            region: _regionOfLineId(entry.key),
          ),
      ],
  };

  /// 노선이면 역 노드 목록, 아니면(시·군/구·미지정) 빈 목록.
  static List<LocationNode> childrenOf(String nodeId) =>
      _stationsByLine[nodeId] ?? const [];
```

기존 `nodeById`를 다음으로 교체(역 노드까지 탐색):
```dart
  static LocationNode? nodeById(String id) {
    for (final list in _byRegion.values) {
      for (final node in list) {
        if (node.id == id) return node;
      }
    }
    for (final stations in _stationsByLine.values) {
      for (final node in stations) {
        if (node.id == id) return node;
      }
    }
    return null;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/location_catalog_test.dart`
Expected: PASS (기존 카탈로그 테스트 포함 전부)

- [ ] **Step 5: Commit**

```bash
git add lib/data/location_catalog.dart test/location_catalog_test.dart
git commit -m "feat: LocationCatalog 역 노드 + childrenOf + nodeById 확장"
```

---

## Task 3: 필터 접두사 계층 매칭

**Files:**
- Modify: `lib/models/meeting_filter.dart`
- Test: `test/meeting_filter_test.dart`

- [ ] **Step 1: Write the failing test**

`test/meeting_filter_test.dart`의 `void main() {` 안, 기존 'location filter' test 바로 뒤에 추가:
```dart
  test('location filter: 노선 전체 선택은 그 노선의 역·노선 모임을 매칭', () {
    const f = MeetingFilter(locationIds: {'seoul-line2'});
    expect(f.matches(_m(locationId: 'seoul-line2')), isTrue); // 노선 단위
    expect(f.matches(_m(locationId: 'seoul-line2-강남')), isTrue); // 역
    expect(f.matches(_m(locationId: 'seoul-line3-교대')), isFalse); // 다른 노선
  });

  test('location filter: 특정 역 선택은 그 역만 매칭', () {
    const f = MeetingFilter(locationIds: {'seoul-line2-강남'});
    expect(f.matches(_m(locationId: 'seoul-line2-강남')), isTrue);
    expect(f.matches(_m(locationId: 'seoul-line2')), isFalse); // 더 거친 단위
    expect(f.matches(_m(locationId: 'seoul-line2-역삼')), isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/meeting_filter_test.dart`
Expected: FAIL — '노선 전체' 케이스에서 `seoul-line2-강남`이 매칭되지 않아 기대 `isTrue`가 깨짐.

- [ ] **Step 3: Write minimal implementation**

In `lib/models/meeting_filter.dart`, `matches`의 위치 조건 블록을 교체.

기존:
```dart
    if (locationIds.isNotEmpty && !locationIds.contains(m.locationId)) {
      return false;
    }
```

교체 후:
```dart
    if (locationIds.isNotEmpty &&
        !locationIds.any((s) =>
            m.locationId == s || m.locationId.startsWith('$s-'))) {
      return false;
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/meeting_filter_test.dart`
Expected: PASS (기존 'location filter' 테스트 포함 전부)

- [ ] **Step 5: Commit**

```bash
git add lib/models/meeting_filter.dart test/meeting_filter_test.dart
git commit -m "feat: 필터 위치 접두사 계층 매칭(노선 전체/역)"
```

---

## Task 4: LocationPickerScreen 3단계 드릴다운

**Files:**
- Modify: `lib/features/filter/location_picker_screen.dart`
- Test: `test/location_picker_screen_test.dart`

> 노선 노드는 더 이상 직접 선택(체크/즉시 pop)되지 않고 역 목록으로 드릴다운된다. 따라서 기존 "노선을 선택"하던 테스트들을 "노선 드릴다운 → 노선 전체/역 선택"으로 갱신한다.

- [ ] **Step 1: Rewrite/extend the tests**

`test/location_picker_screen_test.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/filter/location_picker_screen.dart';

void main() {
  testWidgets('다중: 서울 → 2호선 드릴 → 강남 체크 → 완료 시 역 id 반환',
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
                    builder: (_) => const LocationPickerScreen(initial: {}),
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
    await tester.tap(find.text('2호선')); // 드릴다운
    await tester.pumpAndSettle();
    await tester.tap(find.text('강남')); // 역 체크
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2-강남'));
  });

  testWidgets('다중: 2호선 전체 체크 시 노선 id 반환', (tester) async {
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
                    builder: (_) => const LocationPickerScreen(initial: {}),
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
    await tester.tap(find.text('2호선 전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2'));
  });

  testWidgets('다중: 초기 선택 유지하며 누적', (tester) async {
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
                        const LocationPickerScreen(initial: {'seoul-line1'}),
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
    await tester.tap(find.text('2호선 전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, containsAll(<String>['seoul-line1', 'seoul-line2']));
  });

  testWidgets('시스템 back: 역 화면 → 노선 목록 → 시/도 목록', (tester) async {
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

    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    expect(find.text('강남'), findsOneWidget); // 역 화면

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('강남'), findsNothing);
    expect(find.text('9호선'), findsOneWidget); // 노선 목록

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('9호선'), findsNothing);
    expect(find.text('장소 선택'), findsOneWidget); // 시/도 목록
  });

  testWidgets('singleSelect: 서울 → 2호선 → 강남 탭 시 즉시 역 id pop',
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
                    builder: (_) => const LocationPickerScreen(
                        initial: {}, singleSelect: true),
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
    expect(find.text('완료'), findsNothing); // 단일 모드엔 완료 버튼 없음
    await tester.tap(find.text('강남'));
    await tester.pumpAndSettle();

    expect(result, {'seoul-line2-강남'});
  });

  testWidgets('singleSelect: 시·군 리프(경기 → 수원시)는 바로 pop', (tester) async {
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
                    builder: (_) => const LocationPickerScreen(
                        initial: {}, singleSelect: true),
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

    await tester.tap(find.text('경기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수원시'));
    await tester.pumpAndSettle();

    expect(result, {'경기-수원시'});
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: FAIL — 현재 피커는 '2호선' 탭 시 역 화면이 없어 '강남'을 찾지 못함.

- [ ] **Step 3: Implement the 3-level picker**

`lib/features/filter/location_picker_screen.dart`를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../../data/location_catalog.dart';
import '../../models/location_node.dart';
import '../../theme/app_colors.dart';

/// 시/도 → 노선/리프 → 역 3단계 드릴다운. 완료 시 선택 id 집합 반환.
/// [singleSelect]가 true이면 리프(역·시·군) 탭 즉시 단일 id로 pop.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initial,
    this.singleSelect = false,
  });

  final Set<String> initial;
  final bool singleSelect;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final Set<String> _selected = {...widget.initial};
  String? _region; // null = 시/도 목록
  LocationNode? _line; // null이 아니면 해당 노선의 역 목록

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _back() {
    if (_line != null) {
      setState(() => _line = null);
    } else if (_region != null) {
      setState(() => _region = null);
    } else {
      Navigator.pop(context, _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _line != null
        ? _stationList(_line!)
        : (_region == null ? _regionList() : _nodeList(_region!));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          title: Text(_line?.label ?? _region ?? '장소 선택'),
        ),
        body: Column(
          children: [
            if (!widget.singleSelect && _selected.isNotEmpty) _selectedChips(),
            Expanded(child: content),
          ],
        ),
        bottomNavigationBar: widget.singleSelect
            ? null
            : SafeArea(
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
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
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
          if (LocationCatalog.childrenOf(node.id).isNotEmpty)
            ListTile(
              title: Text(node.label),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
              onTap: () => setState(() => _line = node),
            )
          else if (widget.singleSelect)
            ListTile(
              title: Text(node.label),
              onTap: () => Navigator.pop(context, {node.id}),
            )
          else
            CheckboxListTile(
              value: _selected.contains(node.id),
              title: Text(node.label),
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => _toggle(node.id),
            ),
      ],
    );
  }

  Widget _stationList(LocationNode line) {
    final stations = LocationCatalog.childrenOf(line.id);
    Widget tile(String id, String label) => widget.singleSelect
        ? ListTile(
            title: Text(label),
            onTap: () => Navigator.pop(context, {id}),
          )
        : CheckboxListTile(
            value: _selected.contains(id),
            title: Text(label),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (_) => _toggle(id),
          );
    return ListView(
      children: [
        tile(line.id, '${line.label} 전체'),
        for (final s in stations) tile(s.id, s.label),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: PASS (6개 테스트 전부)

- [ ] **Step 5: Commit**

```bash
git add lib/features/filter/location_picker_screen.dart test/location_picker_screen_test.dart
git commit -m "feat: LocationPickerScreen 노선→역 3단계 드릴다운"
```

---

## Task 5: 모임 만들기 테스트의 장소 선택 갱신

**Files:**
- Modify: `test/create_meeting_screen_test.dart`

> 모임 만들기 화면 코드는 변경 없음(피커가 반환하는 id를 그대로 사용). 다만 `fillRequired` 헬퍼가 '2호선'을 탭해 바로 선택하던 부분이, 이제 드릴다운으로 바뀌었으므로 역까지 선택하도록 갱신한다.

- [ ] **Step 1: Update fillRequired**

`test/create_meeting_screen_test.dart`에서 다음 블록(지역 단일선택 부분):
```dart
    await tester.tap(find.byKey(const Key('location'))); // 지역(단일선택)
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place')), '강남역 2번 출구'); // 구체 장소(필수)
    await tester.pump();
```
를 다음으로 교체(노선 드릴 후 역까지 선택):
```dart
    await tester.tap(find.byKey(const Key('location'))); // 지역(단일선택)
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선')); // 노선 드릴다운
    await tester.pumpAndSettle();
    await tester.tap(find.text('강남')); // 역 선택 → 즉시 pop
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place')), '강남역 2번 출구'); // 구체 장소(필수)
    await tester.pump();
```

- [ ] **Step 2: Run the create-meeting tests**

Run: `flutter test test/create_meeting_screen_test.dart`
Expected: PASS (5개 테스트 전부)

- [ ] **Step 3: Commit**

```bash
git add test/create_meeting_screen_test.dart
git commit -m "test: 모임 만들기 장소 선택을 노선→역 드릴다운으로 갱신"
```

---

## Task 6: 전체 검증

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests passed!

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Fix any issues**

문제가 있으면 해당 태스크로 돌아가 수정 후 다시 `flutter test` / `flutter analyze` 실행. 특히 `location_node.dart` import가 picker에 추가되었는지(있어야 함), 역 id의 한글이 매칭/표시에 문제없는지 확인.

---

## Notes

- 역 id 형식 `'<노선id>-<역명>'`(예 `seoul-line2-강남`)이라 노선 id가 역 id의 strict prefix가 되고, 이것이 필터 접두사 매칭의 근거다. 역명에는 `-`가 없어야 하며(Task 1 테스트로 보장), 한글·괄호·중점(·)은 무방하다.
- 기존 시드 모임은 노선 단위 id를 유지하며 "노선 전체" 선택으로 매칭된다(재태깅 불필요).
- 모임 만들기에서 역을 고르면 `locationId`가 역 id가 되어 상세/달력 장소 표기가 역명으로 더 정확해진다(코드 변경 없음).
- 역 데이터는 실제 운영 역 기준 목업 데이터로, 최신 연장/신설역 일부 누락·오차 가능.
# 전국 장소 카탈로그 확장 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `LocationCatalog`를 전국 17개 시/도 + 모든 시·군(도) / 지하철 호선·구(광역시)로 확장한다.

**Architecture:** 순수 데이터 파일 `lib/data/location_catalog.dart`만 교체. API(regions/nodesIn/nodeById)와 모델/화면은 불변. 기존 모임 태그 `seoul-line2`는 서울에 그대로 유지되어 재매핑 불필요.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-20-full-location-catalog-design.md`

---

## Task 1: 전국 카탈로그 데이터 교체 (`location_catalog.dart`)

**Files:**
- Modify: `lib/data/location_catalog.dart` (전체 교체)
- Modify: `test/location_catalog_test.dart` (전체 교체)

- [ ] **Step 1: 테스트 전체 교체(실패 유도)**

`test/location_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/location_catalog.dart';

void main() {
  test('regions are the 17 시/도 in order', () {
    expect(LocationCatalog.regions.length, 17);
    expect(LocationCatalog.regions.first, '서울');
    expect(LocationCatalog.regions, contains('전북'));
    expect(LocationCatalog.regions, contains('전남'));
    expect(LocationCatalog.regions, contains('강원'));
    expect(LocationCatalog.regions, contains('경남'));
    expect(LocationCatalog.regions, contains('충북'));
    expect(LocationCatalog.regions, isNot(contains('전라')));
  });

  test('서울 has 9 subway lines', () {
    final seoul = LocationCatalog.nodesIn('서울');
    expect(seoul.length, 9);
    expect(seoul.any((n) => n.id == 'seoul-line2'), isTrue);
  });

  test('제주 has 2 cities', () {
    final jeju = LocationCatalog.nodesIn('제주');
    expect(jeju.length, 2);
    expect(jeju.map((n) => n.label), containsAll(['제주시', '서귀포시']));
  });

  test('경기 includes all listed 시·군', () {
    final gg = LocationCatalog.nodesIn('경기');
    expect(gg.length, greaterThanOrEqualTo(31));
    expect(gg.map((n) => n.label), containsAll(['수원시', '양평군']));
  });

  test('울산 uses 구/군 (no subway)', () {
    final ulsan = LocationCatalog.nodesIn('울산');
    expect(ulsan.map((n) => n.label), containsAll(['중구', '울주군']));
  });

  test('nodeById resolves labels', () {
    expect(LocationCatalog.nodeById('seoul-line2')?.label, '2호선');
    expect(LocationCatalog.nodeById('busan-line4')?.label, '4호선');
    expect(LocationCatalog.nodeById('경기-수원시')?.label, '수원시');
    expect(LocationCatalog.nodeById('nope'), isNull);
  });

  test('same 군 name in different 도 are distinct nodes', () {
    final gangwon = LocationCatalog.nodeById('강원-고성군');
    final gyeongnam = LocationCatalog.nodeById('경남-고성군');
    expect(gangwon?.region, '강원');
    expect(gyeongnam?.region, '경남');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/location_catalog_test.dart`
Expected: FAIL — 기존 8개 시/도/서브셋과 불일치.

- [ ] **Step 3: 카탈로그 전체 교체**

`lib/data/location_catalog.dart` 전체를 다음으로 교체:

```dart
import '../models/location_node.dart';

/// 전국 시/도 + 시·군(도) / 지하철 호선·구(광역시) 카탈로그.
class LocationCatalog {
  static const List<String> regions = [
    '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종',
    '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주',
  ];

  /// 도(道)의 시·군 라벨 목록으로 `<도>-<라벨>` id의 노드를 만든다.
  static List<LocationNode> _province(String region, List<String> labels) =>
      [
        for (final label in labels)
          LocationNode(id: '$region-$label', label: label, region: region),
      ];

  static final Map<String, List<LocationNode>> _byRegion = {
    '서울': const [
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
    '부산': const [
      LocationNode(id: 'busan-line1', label: '1호선', region: '부산'),
      LocationNode(id: 'busan-line2', label: '2호선', region: '부산'),
      LocationNode(id: 'busan-line3', label: '3호선', region: '부산'),
      LocationNode(id: 'busan-line4', label: '4호선', region: '부산'),
    ],
    '대구': const [
      LocationNode(id: 'daegu-line1', label: '1호선', region: '대구'),
      LocationNode(id: 'daegu-line2', label: '2호선', region: '대구'),
      LocationNode(id: 'daegu-line3', label: '3호선', region: '대구'),
    ],
    '인천': const [
      LocationNode(id: 'incheon-line1', label: '인천1호선', region: '인천'),
      LocationNode(id: 'incheon-line2', label: '인천2호선', region: '인천'),
    ],
    '광주': const [
      LocationNode(id: 'gwangju-line1', label: '광주1호선', region: '광주'),
    ],
    '대전': const [
      LocationNode(id: 'daejeon-line1', label: '대전1호선', region: '대전'),
    ],
    '울산': const [
      LocationNode(id: 'ulsan-junggu', label: '중구', region: '울산'),
      LocationNode(id: 'ulsan-namgu', label: '남구', region: '울산'),
      LocationNode(id: 'ulsan-donggu', label: '동구', region: '울산'),
      LocationNode(id: 'ulsan-bukgu', label: '북구', region: '울산'),
      LocationNode(id: 'ulsan-uljugun', label: '울주군', region: '울산'),
    ],
    '세종': const [
      LocationNode(id: 'sejong', label: '세종시', region: '세종'),
    ],
    '경기': _province('경기', const [
      '수원시', '성남시', '의정부시', '안양시', '부천시', '광명시', '평택시',
      '동두천시', '안산시', '고양시', '과천시', '구리시', '남양주시', '오산시',
      '시흥시', '군포시', '의왕시', '하남시', '용인시', '파주시', '이천시',
      '안성시', '김포시', '화성시', '광주시', '양주시', '포천시', '여주시',
      '연천군', '가평군', '양평군',
    ]),
    '강원': _province('강원', const [
      '춘천시', '원주시', '강릉시', '동해시', '태백시', '속초시', '삼척시',
      '홍천군', '횡성군', '영월군', '평창군', '정선군', '철원군', '화천군',
      '양구군', '인제군', '고성군', '양양군',
    ]),
    '충북': _province('충북', const [
      '청주시', '충주시', '제천시', '보은군', '옥천군', '영동군', '증평군',
      '진천군', '괴산군', '음성군', '단양군',
    ]),
    '충남': _province('충남', const [
      '천안시', '공주시', '보령시', '아산시', '서산시', '논산시', '계룡시',
      '당진시', '금산군', '부여군', '서천군', '청양군', '홍성군', '예산군',
      '태안군',
    ]),
    '전북': _province('전북', const [
      '전주시', '군산시', '익산시', '정읍시', '남원시', '김제시', '완주군',
      '진안군', '무주군', '장수군', '임실군', '순창군', '고창군', '부안군',
    ]),
    '전남': _province('전남', const [
      '목포시', '여수시', '순천시', '나주시', '광양시', '담양군', '곡성군',
      '구례군', '고흥군', '보성군', '화순군', '장흥군', '강진군', '해남군',
      '영암군', '무안군', '함평군', '영광군', '장성군', '완도군', '진도군',
      '신안군',
    ]),
    '경북': _province('경북', const [
      '포항시', '경주시', '김천시', '안동시', '구미시', '영주시', '영천시',
      '상주시', '문경시', '경산시', '의성군', '청송군', '영양군', '영덕군',
      '청도군', '고령군', '성주군', '칠곡군', '예천군', '봉화군', '울진군',
      '울릉군',
    ]),
    '경남': _province('경남', const [
      '창원시', '진주시', '통영시', '사천시', '김해시', '밀양시', '거제시',
      '양산시', '의령군', '함안군', '창녕군', '고성군', '남해군', '하동군',
      '산청군', '함양군', '거창군', '합천군',
    ]),
    '제주': _province('제주', const ['제주시', '서귀포시']),
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
Expected: PASS (7 tests).

- [ ] **Step 5: 전체 분석 & 전체 테스트**

Run: `flutter analyze && flutter test`
Expected: 분석 No issues, 전체 PASS. (서울에 line2가 그대로 있어 기존 필터/모임 테스트 영향 없음)

- [ ] **Step 6: 커밋**

```bash
git add lib/data/location_catalog.dart test/location_catalog_test.dart && git commit -m "feat: expand location catalog to full nationwide 시·군"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## 최종 검증

- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`(가능 시): 필터 → 장소에서 17개 시/도, 도 선택 시 모든 시·군 표시.

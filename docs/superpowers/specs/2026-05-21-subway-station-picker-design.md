# 지하철 노선 → 역 3단계 선택 설계

작성일: 2026-05-21

## 목표

위치 선택(필터·모임 만들기 공용 `LocationPickerScreen`)에서 지하철 **노선**을 고른 경우, 한 단계 더 들어가 **역**까지 선택할 수 있게 한다. 시·군/구 같은 기존 리프는 그대로 둔다.

결정 사항(브레인스토밍):
- 역 데이터: **실제 전체 역 목록** (모든 광역시 지하철 노선)
- 역 화면에 **"노선 전체"** 옵션 + **계층 매칭** (기존 시드 호환)
- 적용 대상: **모든 광역시 지하철** (서울·부산·대구·인천·광주·대전)

## 데이터 구조

### `LocationNode` (lib/models/location_node.dart)
변경 없음. `id`, `label`, `region` 그대로 사용한다. 부모/자식 관계는 카탈로그가 관리하고, 매칭은 id 접두사 규칙으로 처리하므로 노드에 `parentId`를 추가하지 않는다.

### 새 파일 `lib/data/subway_stations.dart`
노선 id별 전체 역 이름 목록을 보관한다.

```dart
/// 노선 id → 역 이름(상행/기점 순) 목록. 광역시 도시철도 실제 운영 역.
const Map<String, List<String>> kSubwayStations = {
  'seoul-line1': ['소요산', '동두천', ... '인천', ...],
  'seoul-line2': ['시청', '을지로입구', ... '강남', '역삼', ...],
  // ... 서울 1~9호선
  'busan-line1': [...], 'busan-line2': [...], 'busan-line3': [...], 'busan-line4': [...],
  'daegu-line1': [...], 'daegu-line2': [...], 'daegu-line3': [...],
  'incheon-line1': [...], 'incheon-line2': [...],
  'gwangju-line1': [...],
  'daejeon-line1': [...],
};
```

데이터 분량이 매우 크므로(서울만 300역 이상) 카탈로그 본체와 분리한다. 실제 운영 역명을 최대한 정확히 채우되, 최신 연장/신설역에서 일부 누락·오차가 있을 수 있다(목업 데이터 수준).

키는 `LocationCatalog._byRegion`에 이미 존재하는 노선 노드 id와 정확히 일치해야 한다(예: `seoul-line2`). `_province`로 만든 시·군 노드(`경기-수원시` 등)와 울산 구 노드에는 역이 없으므로 키를 두지 않는다.

### `LocationCatalog` (lib/data/location_catalog.dart) API 추가
- 역 노드 생성: 각 `kSubwayStations[lineId]`의 역 이름으로 `LocationNode(id: '$lineId-$역이름', label: 역이름, region: <노선의 region>)`를 만들어 `Map<String lineId, List<LocationNode>>` 형태로 캐시한다.
  - 역 id 예: `seoul-line2-강남`. (region 접두 기반 노선 id가 역 id의 strict prefix가 됨 → 매칭 규칙의 근거)
- `static List<LocationNode> childrenOf(String nodeId)`: 노선 id면 역 노드 목록, 아니면 `const []`.
- `static LocationNode? nodeById(String id)`: 기존 시/도 노드뿐 아니라 역 노드까지 탐색하도록 확장.

> 시·군/구 노드는 `childrenOf`가 빈 목록을 반환하므로 리프로 동작한다.

## 선택 화면 — `LocationPickerScreen` (lib/features/filter/location_picker_screen.dart)

2단계(시/도 ↔ 리프)를 3단계로 일반화한다.

### 상태
- `String? _region` — null이면 시/도 목록, 아니면 해당 시/도의 노드 목록(2단계)
- `LocationNode? _line` — null이 아니면 해당 노선의 역 목록(3단계)

### 단계별 동작
- **1단계 (시/도 목록)**: 항목 탭 → `_region` 설정.
- **2단계 (`nodesIn(_region)`)**: 각 노드에 대해
  - `LocationCatalog.childrenOf(node.id)`가 비어있지 않으면(=노선) → 탭 시 `_line = node`로 3단계 진입. 우측 chevron 표시.
  - 비어있으면(=시·군/구 리프) → 기존 동작: 다중 모드면 체크박스 토글, 단일 모드면 `Navigator.pop(context, {node.id})`.
- **3단계 (`_line`의 역 목록)**:
  - 맨 위 **"노선 전체"** 항목(선택 시 id = `_line!.id`).
  - 이어서 개별 역 노드들.
  - 다중 모드: 체크박스 토글. 단일 모드: 탭 즉시 `Navigator.pop(context, {id})`.

### 뒤로가기 / PopScope
한 단계씩 되돌아간다:
- `_line != null` → `_line = null` (역 → 노선 목록)
- 아니고 `_region != null` → `_region = null` (노선/시·군 목록 → 시/도 목록)
- 둘 다 null → `Navigator.pop(context, _selected)` (다중) 또는 그냥 닫힘.

appBar title: 3단계에서는 `_line!.label`(예: "2호선"), 2단계에서는 `_region`, 1단계에서는 "장소 선택".

선택 칩(다중 모드)·"완료" 버튼·단일 모드 규칙(완료 버튼 숨김 등)은 기존 그대로. 칩 라벨은 `nodeById`가 역 id를 해석하므로 역명이 정상 표시된다.

## 필터 매칭 — `MeetingFilter.matches` (lib/models/meeting_filter.dart)

위치 조건을 **접두사 기반 계층 매칭**으로 변경한다.

```dart
if (locationIds.isNotEmpty &&
    !locationIds.any((s) =>
        m.locationId == s || m.locationId.startsWith('$s-'))) {
  return false;
}
```

동작:
- "노선 전체"(= 노선 id, 예 `seoul-line2`) 선택 → 그 노선 역 모임(`seoul-line2-강남`)은 `startsWith('seoul-line2-')`로, 노선 단위 모임(`seoul-line2`)은 정확 일치로 매칭. → **기존 시드(노선 단위) 그대로 호환.**
- 특정 역(`seoul-line2-강남`) 선택 → 해당 역 모임만 정확 일치. 노선 단위 모임은 매칭 안 됨(더 거친 단위라 역 특정 불가 — 목업 허용).
- 시·군/구 등 기존 리프 → 정확 일치로 기존과 동일.
- `'$s-'`의 `-` 구분자로 `seoul-line2`가 `seoul-line20` 같은 값에 오매칭되지 않음(노선은 line1~9뿐이라 무관하나 규칙상 안전).

모델은 카탈로그에 의존하지 않고 문자열 규칙만 사용 → 순수성 유지.

## 시드 / 모임 생성

- `MeetingRepository._seed`의 모임들은 노선 단위 `locationId`(`seoul-line2` 등) 유지. 재태깅 불필요 — "노선 전체" 선택으로 매칭된다.
- `CreateMeetingScreen`은 깊어진 피커를 그대로 사용한다(단일 선택 모드). 이제 역까지 고르면 `locationId`에 역 id가 저장되고, `nodeById(locationId).label`이 역명이 되어 상세/달력의 장소 표기가 더 정확해진다. 코드 변경 없음(피커 반환 id를 그대로 사용).

## 테스트

- **카탈로그**: 특정 노선의 `childrenOf`가 역 노드를 반환하고 첫 역 등 일부가 기대값과 일치, `nodeById('seoul-line2-강남')`이 역 노드를 반환, 시·군 노드의 `childrenOf`는 빈 목록.
- **필터(접두사 계층 매칭)**:
  - 노선 id 선택 시 그 노선의 역 모임과 노선 단위 모임이 모두 통과
  - 역 id 선택 시 해당 역 모임만 통과, 노선 단위 모임은 탈락
  - 시·군 id 선택은 정확 일치로 기존 동작 유지
- **피커 3단계**:
  - 다중: 서울 → 2호선 → 역 목록에서 역 체크 후 완료 시 역 id 반환, "노선 전체" 체크 시 노선 id 반환
  - 단일(singleSelect): 서울 → 2호선 → 역 탭 시 즉시 역 id pop
  - 뒤로가기: 역 화면에서 back → 노선 목록, 다시 back → 시/도 목록
  - 시·군(경기 → 수원시)은 기존처럼 2단계에서 바로 선택
- **회귀**: 기존 filter_screen / create_meeting / home 흐름 그대로 통과.

## 범위 밖 (YAGNI)

- 도(道)의 시·군 아래 동/읍 단계 추가 (지하철 노선만 대상)
- 역 검색창, 즐겨찾기, 거리순 정렬
- 노선도(그래픽) UI
# 모이자 — 필터 영구 저장 · 장소 뒤로가기 · 요약 필터 개수 설계

작성일: 2026-05-20
대상: 필터 화면/홈 후속 개선 3건
기준일("오늘"): 2026-05-16

## 목표

1. 앱을 완전히 껐다 켜도 마지막 필터가 유지된다.
2. 장소 선택에서 지역 상세(예: 대구1호선 목록)를 보다가 뒤로가기를 누르면 picker가 닫히지 않고 시/도 목록으로 돌아간다.
3. 홈 요약 줄에 필터 개수를 함께 표시한다("필터 N개 · 모임 M개").

## 1. 필터 영구 저장

- `shared_preferences` 의존성 추가(`flutter pub add shared_preferences`).
- `MeetingFilter`에 직렬화 추가:
  - `Map<String, dynamic> toMap()` — categories/timeBands는 enum `name` 리스트, locationIds/customCategories는 문자열 리스트.
  - `factory MeetingFilter.fromMap(Map<String, dynamic>)` — **관대한 파싱**: 알 수 없는 enum name은 건너뛴다(향후 카테고리/시간대 변경 시 깨지지 않도록).
- 신규 `lib/data/filter_storage.dart` — `FilterStorage`:
  - `Future<void> save(MeetingFilter)` → `prefs.setString('meeting_filter', jsonEncode(filter.toMap()))`.
  - `Future<MeetingFilter> load()` → 없으면 `MeetingFilter.empty()`, 있으면 `fromMap(jsonDecode(...))`.
- `HomeScreen`:
  - `FilterStorage` 보유. `initState`에서 `load()` → `mounted`면 `setState(_filter = loaded)`.
  - `_openFilter`에서 결과 수신 시 `setState(_filter = result)` + `await _storage.save(result)`.

## 2. 장소 화면 뒤로가기 (`location_picker_screen.dart`)

- 화면 전체를 `PopScope(canPop: false, onPopInvokedWithResult: ...)`로 감싼다.
  - `didPop`이면 무시.
  - `_region != null` → `setState(() => _region = null)` (지역 상세 → 시/도 목록).
  - `_region == null` → `Navigator.pop(context, _selected)` (선택값 들고 닫기).
- 기존 앱바 leading 뒤로가기 버튼도 동일 로직 유지 → 시스템 back·앱바 back 모두 일관 동작.
- 시스템 back으로 닫을 때도 선택값을 반환하므로 picker 진입 중 누적 선택이 보존된다.

## 3. 요약에 필터 개수 (`selected_day_summary.dart`)

- `SelectedDaySummary({required selectedDay, required meetingCount, required filterCount})`.
- 둘째 줄: **"필터 $filterCount개 · 모임 $meetingCount개"** (항상 표시).
- `HomeScreen`이 `filterCount: _filter.activeCount` 전달.

## 테스트

- `meeting_filter_test`(추가): `toMap`/`fromMap` 라운드트립(카테고리·장소·시간대·커스텀), 알 수 없는 enum name 무시.
- `filter_storage_test`(신규): `SharedPreferences.setMockInitialValues({})` 후 save→load 복원; 빈 상태 load는 empty.
- `location_picker_screen_test`(추가): 지역 상세 진입 후 시스템 back(`tester.binding.handlePopRoute()`) → 시/도 목록 복귀(상세 노드 사라지고 picker 유지).
- `home_screen_test`(갱신): `setUpAll`에 `SharedPreferences.setMockInitialValues({})`; 저장된 필터(prefs 목)가 시작 시 적용되어 비매칭 모임이 숨겨짐; 요약이 "필터 N개 · 모임 M개" 표시.

## 범위 밖 (유지)
- 직접입력 카테고리 매칭 미적용, 전국 전수 장소 데이터, 백엔드.
- 다이얼로그 TextEditingController 정식 해제(별도 위젯 분리 필요 — 후속).

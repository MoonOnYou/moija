# 모이자 — 필터 화면 설계

작성일: 2026-05-20
대상: 홈의 필터 바 → 필터 화면(카테고리·장소·시간대) + 실제 모임 필터링
기준일("오늘"): 2026-05-16

## 목표

홈의 **필터 바**를 누르면 필터 화면으로 이동한다. 카테고리(다중), 장소(시/도 → 호선/구 드릴다운 다중), 시간대(다중)를 고르고, **저장**하면 홈의 달력·리스트 모임이 실제로 걸러진다. **초기화**는 선택을 모두 해제한다.

## 결정 사항

- 장소 데이터는 **대표 서브셋**(하드코딩). 전국 전수 데이터는 범위 밖.
- 저장 시 **실제 모임 필터링** 적용(카테고리·장소·시간대). 단 장소는 목 데이터에 태그된 노드 기준.
- 요일 선택은 없음. 시간대만.
- 카테고리 끝에 **직접 입력하기**(커스텀 문자열) — 저장·표시되나 목 데이터 매칭 대상이 없어 필터링엔 미적용.

## 1. 카테고리 정리 (`meeting_category.dart`)

`MeetingCategory`를 10종으로 교체:
방탈출(escapeRoom), 볼링(bowling), 노래방(karaoke), 술 한잔(drink), 카페(cafe), 등산(hiking),
수영(swimming), 보드게임(boardGame), 롤(lol), 기타(etc).
- 제거: movie, game. 추가: swimming, lol(=기존 game 대체).
- 아이콘/색상: 기존 색 계열 재사용(info/warning/success/중립). 수영=Icons.pool(success), 롤=Icons.sports_esports(info).
- 시드의 movie/ game 사용 모임은 새 카테고리로 재매핑(영화 → 기타, game → 롤).

## 2. 시간대 (`time_band.dart`)

```
enum TimeBand { morning, afternoon, evening, night }
```
- 라벨/범위: 오전 06–12시, 오후 12–18시, 저녁 18–21시, 밤 21–24시.
- `containsHour(int hour)`: `hour >= start && hour < end`. 경계: 12시→오후, 21시→밤.
- 모임 시각의 밴드 = `startTime.hour`로 판정.

## 3. 장소 택소노미 (`location_node.dart`, `location_catalog.dart`)

- `LocationNode { String id; String label; String region; }` — 리프 노드(호선/구/권역).
- `LocationCatalog`: 지역(시/도) 목록과 지역별 리프 노드.
  - 서울: 1~9호선 (id `seoul-line1`..`seoul-line9`)
  - 경기: 수원시·성남시·고양시·용인시
  - 인천: 인천1호선·인천2호선
  - 대전: 대전1호선
  - 대구: 대구1호선·대구2호선
  - 부산: 부산1호선·부산2호선
  - 광주: 광주1호선
  - 전라: 전주권·여수순천권 (지하철 없는 권역 묶음)
- 조회: `regions`(시/도 순서), `nodesIn(region)`.
- "전체 선택"은 해당 지역의 모든 리프를 토글하는 UI 동작(별도 노드 아님).

## 4. 모임 장소 태그 (`meeting.dart`, `meeting_repository.dart`)

- `Meeting`에 `String locationId` 추가.
- 시드(~16개)를 노드에 매핑. 현재 region(신림/강남/홍대/잠실)은 모두 서울 2호선 권역 → 대부분 `seoul-line2`로 태그(현실 반영). (장소 필터 시연: 2호선 선택 시 표시, 다른 선 선택 시 제외)

## 5. 필터 모델 (`meeting_filter.dart`)

```
class MeetingFilter {
  Set<MeetingCategory> categories;
  Set<String> locationIds;     // 선택된 리프 노드 id
  Set<TimeBand> timeBands;
  Set<String> customCategories; // 직접 입력, 매칭 미적용
}
```
- `bool get isEmpty`, `int get activeCount`(= 네 집합 크기 합).
- `bool matches(Meeting m)`:
  - 카테고리 비어있지 않고 `!categories.contains(m.category)` → false
  - 장소 비어있지 않고 `!locationIds.contains(m.locationId)` → false
  - 시간대 비어있지 않고 어떤 밴드도 `containsHour(m.startTime.hour)` 아니면 → false
  - 그 외 true. (빈 섹션 = 제약 없음)
- 순수 로직, 단위 테스트 대상.

## 6. 화면 & 내비게이션

- **FilterBar 변경**(`filter_bar.dart`): 정적 칩 → 탭 가능한 한 줄. 선택 요약(활성 개수 배지) 표시. 탭 → `onTap` 콜백.
- **FilterScreen**(`filter_screen.dart`): 전체화면 라우트. 작업용 선택 상태 보유.
  - 섹션1 카테고리: 칩 다중 토글 + 끝에 "+ 직접 입력하기"(누르면 텍스트 입력 다이얼로그 → customCategories에 추가, 칩으로 표시).
  - 섹션2 장소: "지역 선택" 행 + 선택된 노드 칩들. 탭 → `LocationPickerScreen` push, 반환된 `Set<String>`(노드 id) 반영.
  - 섹션3 시간대: 오전/오후/저녁/밤 칩(범위 표기) 다중 토글.
  - 하단: [초기화](선택 모두 해제) · [저장하기](현재 선택으로 `MeetingFilter` 구성해 `Navigator.pop(filter)`).
- **LocationPickerScreen**(`location_picker_screen.dart`): 시/도 목록 ↔ 지역 상세(리프 다중 체크) 드릴다운. 현재 선택 집합을 받아 누적, 상단에 선택 칩(제거 가능), 완료 시 `Navigator.pop(Set<String>)`.

## 7. 홈 적용 (`home_screen.dart`)

- 홈이 `MeetingFilter _filter`(기본 빈=전체) 보유.
- 필터 바 탭 → `FilterScreen` push → 반환 필터로 `setState`.
- `TwoWeekCalendar`·`DayMeetingsPager`에 `filter` 전달. 두 위젯은 `repository.meetingsOn(date)` 결과를 `filter.matches`로 걸러 사용(달력 칩·요약 개수·리스트 동시 반영).
- 빈 필터면 전체 표시(기존 동작 유지).

## 8. 테스트

- `time_band_test`: 경계 시각(6/12/18/21/23) 밴드 판정.
- `location_catalog_test`: regions 순서, `nodesIn('서울')` 9개 등.
- `meeting_filter_test`: 빈 필터=전체 통과; 카테고리/장소/시간대 단일·복합; 미매칭 제외.
- `filter_screen_test`: 카테고리 칩 토글, 시간대 토글, 초기화로 해제, 저장 시 올바른 `MeetingFilter` pop, 직접입력 추가.
- `location_picker_screen_test`: 시/도 진입 → 리프 다중 선택 → pop 시 노드 집합 반환, 누적 유지.
- `home_screen_test`(갱신): 필터 적용 시 달력/리스트가 걸러짐(예: 특정 카테고리만), 필터 바 탭 → FilterScreen 표시.

## 범위 밖 (유지)
- 검색·알림·FAB·다이아 표시 전용, 채팅/내모임/프로필 플레이스홀더, 백엔드.
- 전국 전수 장소 데이터, 직접입력 카테고리의 실제 매칭, 장소 상위지역 매칭(전체선택은 리프 토글로 대체).

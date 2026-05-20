# 모이자 — 모임 리스트 좌우 스와이프 날짜 이동 설계

작성일: 2026-05-20
대상: 홈 캘린더 화면(2주 뷰)의 모임 리스트 영역
기준일("오늘"): 2026-05-16

## 배경 / 목표

달력 아래 모임 리스트를 좌우로 스와이프하면 이전/다음 **날짜**의 리스트로 이동한다.
왼쪽 스와이프 = 다음 날, 오른쪽 스와이프 = 이전 날. 슬라이드 애니메이션으로 전환한다.
선택일이 현재 보이는 2주 창 밖으로 나가면 달력 창이 따라 이동해 선택일이 항상 보이게 한다.

## 변경 사항

### 1. 새 위젯 `day_meetings_pager.dart`
모임 리스트 영역을 `PageView.builder`로 감싼다.
- **페이지 ↔ 날짜 매핑**: 고정 기준일(epoch=2026-05-16) + 일수 차이 + 큰 base 인덱스로 양방향 무한 스와이프.
- 각 페이지 = 해당 날짜의 모임 리스트(세로 스크롤 `ListView`) 또는 빈 상태("이 날에는 모임이 없어요").
- 스와이프로 페이지가 바뀌면 `onDayChanged(date)` 호출(슬라이드 애니메이션은 PageView 기본).
- `selectedDay`가 외부(달력 탭)에서 바뀌면 `didUpdateWidget`에서 해당 페이지로 `animateToPage`(양방향 동기화). 피드백 루프는 `isSameDay`/현재 페이지 비교로 차단.
- 빈 상태 위젯은 이 파일로 옮긴다(기존 `home_screen.dart`의 `_EmptyState` 제거).

### 2. 창 따라가기 (순수 함수, `calendar_grid.dart`)
```dart
DateTime windowFollowing(DateTime windowStart, DateTime selectedDay)
```
- 선택일이 `[windowStart, windowStart+13]` 밖이면 `windowStart`를 7일 단위로 이동시켜 선택일이 들어오게 한다.
- 항상 일요일(현재 windowStart가 일요일이므로 ±7로 유지)을 유지한다.

### 3. `home_screen.dart`
- 달력 탭과 리스트 스와이프를 하나의 `_goToDay(day)`로 통일:
  `_selectedDay = day; _windowStart = windowFollowing(_windowStart, day);`
- 달력 `onDaySelected` → `_goToDay`.
- 달력의 2주 페이징(`onWindowDelta` ±14, 좌우 스와이프)은 기존대로 유지(선택일은 바꾸지 않음).
- 기존 `Expanded(리스트/빈상태)` → `Expanded(DayMeetingsPager(selectedDay, repository, onDayChanged: _goToDay))`.
- 헤더 월 라벨·`SelectedDaySummary`는 selectedDay에 따라 자동 갱신.

## 테스트
- `calendar_grid_test`: `windowFollowing`
  - 선택일이 창 안 → 그대로.
  - 창 끝 다음 날 → +7 이동, 결과가 일요일이고 선택일 포함.
  - 창 시작 이전 날 → -7 이동.
- `day_meetings_pager_test`(신규): 왼쪽 fling → `onDayChanged`가 다음 날, 오른쪽 fling → 이전 날 호출.
- `home_screen_test`(갱신): 리스트 영역 스와이프 → 요약("5월 17일")과 리스트("주말 관악산 등반")가 다음 날로 갱신. 기존 테스트(라벨/달력 탭/빈 상태/2주 페이징/과거 흐림) 유지.

## 범위 밖 (유지)
- 필터/검색/알림/FAB/다이아 재화 표시 전용.
- 채팅/내모임/프로필 탭 플레이스홀더.
- 백엔드 연결.
- 연도 경계 라벨 등 이전 리뷰의 Minor 항목.

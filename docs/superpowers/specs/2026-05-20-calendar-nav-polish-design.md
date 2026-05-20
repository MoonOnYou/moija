# 모이자 — 달력/리스트 내비게이션 개선 설계

작성일: 2026-05-20
대상: 홈 캘린더 화면(2주 PageView 리스트 + 2주 달력)
기준일("오늘"): 2026-05-16

## 배경

사용자 피드백 3건:
1. (버그) 달력에서 떨어진 날짜를 선택하면 전환이 매끄럽지 않다.
2. 오늘 이전 날짜로는 리스트 스와이프·선택이 안 되게.
3. 달력 좌우 스와이프에도 슬라이드 애니메이션.

## 버그 #1 근본 원인

`DayMeetingsPager.didUpdateWidget`가 외부(달력 탭) 선택 변경 시 `animateToPage`로 이동한다.
떨어진 날짜는 다중 페이지를 휩쓸며 이동하고, 그 과정에서 PageView가 **중간 페이지마다 `onPageChanged`를
발화** → 각 호출이 `onDayChanged(중간날짜)` → `setState` 연쇄를 일으켜 달력 강조·요약이 깜빡이고
애니메이션이 충돌한다(= 매끄럽지 않음). 인접 날짜는 1페이지라 정상.

## 변경 사항

### 1. `DayMeetingsPager` (버그 #1 + #2b)
- **버그 #1**: `didUpdateWidget`의 `animateToPage` → `jumpToPage`(즉시 이동, 중간 페이지 휩쓸기·연쇄 콜백 제거). 사용자 스와이프는 네이티브 슬라이드 유지.
- **#2b**: `today` 파라미터 추가. 페이지 매핑 기준을 today로: `pageOf(d) = d.difference(today).inDays`, page 0 = 오늘. `PageView.builder`는 음수 인덱스가 없어 오늘 이전으로 스와이프 불가. (선택일은 항상 오늘 이후)
- `_dateOf(page) = today + page일`.

### 2. `DayCell` (#2a)
- `onTap` 타입을 `VoidCallback?`로 변경. null이면 탭 무반응.
- 흐림(`isPast` opacity 0.45) 표시는 유지.

### 3. `TwoWeekCalendar` (#3 + 과거 창 차단)
- `StatelessWidget` → `StatefulWidget`(PageController 보유).
- 요일 헤더(일~토)는 정적으로 상단에 두고, **2주 그리드(2행, 높이 208)를 `PageView.builder`로** 페이징.
- 페이지 매핑: `windowOf(i) = weekStartOf(today) + 14*i`, page 0 = 오늘 주 → 음수 인덱스 없음 → **과거 창 차단**.
- 인터페이스 변경: `onWindowDelta(int)` 제거, **`onWindowChanged(DateTime windowStart)`** 추가.
- 스와이프 → `onPageChanged(i)` → `onWindowChanged(windowOf(i))`(네이티브 슬라이드 애니메이션).
- 외부에서 `windowStart`가 바뀌면 `didUpdateWidget`에서 현재 페이지와 다를 때 `jumpToPage`(다중 페이지 jank 방지).
- 각 페이지의 `DayCell`: 과거 날짜는 `onTap: null`.

### 4. `windowFollowing` (`calendar_grid.dart`)
- 이동 단위 7일 → **14일**. 창이 `weekStartOf(today)+14k` 페이지 그리드에 정렬되도록 유지(일요일 유지). 선택일이 창을 벗어나면 14일씩 이동해 포함.

### 5. `home_screen.dart`
- `DayMeetingsPager`에 `today: _today` 전달.
- `TwoWeekCalendar`의 `onWindowDelta: _shiftWindow` → `onWindowChanged: (ws) => setState(() => _windowStart = ws)`. `_shiftWindow` 제거.
- `_goToDay`는 그대로(windowFollowing 호출). 달력 탭은 가시(오늘 이후) 날짜만 들어오므로 selectedDay ≥ today 불변 유지.

## 데이터 흐름 (정리)
- **달력 탭(가시·미래 날짜)** → `_goToDay` → selectedDay 변경 + windowFollowing → 리스트/달력 PageView는 `jumpToPage`로 동기화(즉시), 달력 강조 이동.
- **리스트 스와이프** → 하루 단위 이동(오늘에서 멈춤) → `onDayChanged` → `_goToDay`.
- **달력 스와이프** → 2주 단위 이동(오늘 주에서 멈춤, 슬라이드 애니메이션) → `onWindowChanged`(selectedDay 불변).

## 테스트
- `calendar_grid_test`: `windowFollowing` 14일 단위로 갱신
  - 창 안 → 그대로(`(5/10,5/16)→5/10`, `(5/10,5/23)→5/10`).
  - 끝 다음 날 → +14(`(5/10,5/24)→5/24`, 일요일).
  - 시작 이전 → −14(`(5/24,5/23)→5/10`).
- `day_meetings_pager_test`:
  - 왼쪽 스와이프 → 다음 날(`5/17`).
  - 오른쪽 스와이프(오늘 5/16에서) → 차단(`onDayChanged` 미호출).
  - #1 회귀: 외부에서 `selectedDay`를 5/16→5/20으로 바꾸면 중간 날짜(5/17~5/19)로 `onDayChanged`가 호출되지 않음.
- `home_screen_test`(기존 + 추가):
  - 기존: 초기 라벨, 미래 날짜 탭→리스트 갱신, 빈 날짜, 달력 왼쪽 플링→"2026년 5–6월", 과거 흐림, 리스트 스와이프→다음 날.
  - 추가: 과거 날짜('14') 탭 → 무반응(요약 "5월 16일", "퇴근 후 볼링" 유지).
  - 추가: 달력 오른쪽 플링 → 과거 창 차단(라벨 "2026년 5월" 유지).

## 범위 밖 (유지)
- 필터/검색/알림/FAB/다이아 표시 전용, 탭 플레이스홀더, 백엔드 미연결.
- `_today`(home)와 페이저/달력의 today는 동일 값(2026-05-16)을 공유(목 데이터 단계).

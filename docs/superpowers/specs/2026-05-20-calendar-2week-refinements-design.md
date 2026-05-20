# 모이자 — 홈 캘린더 2주 뷰 개선 설계

작성일: 2026-05-20
대상: 기존 홈 캘린더 화면(`2026-05-20-home-calendar-design.md`)의 후속 개선
기준일("오늘"): 2026-05-16 (토요일)

## 배경

홈 캘린더 1차 구현 이후, 사용자가 6개 변경을 요청했다. 핵심은 "다가오는 모임을 한눈에" 보도록
캘린더를 **2주 뷰**로 압축하고, 각 날짜에 모임 정보를 더 풍부하게 보여주는 것이다.

## 변경 사항

### 1. 필터 바 (`filter_bar.dart`)
- "모두 지우기" 제거, "이번 주" 필터 제거.
- "강남" → "신림" 으로 교체.
- 최종 칩: `[필터 ▾(배지 3)] 방탈출 볼링 신림` (표시 전용 유지).

### 2. 카테고리 확장 (`meeting_category.dart`)
10개로 확장. 각 카테고리는 라벨/아이콘/색상 계열을 갖는다.

| 카테고리 | enum | 아이콘 | 색상 계열 |
|---|---|---|---|
| 방탈출 | escapeRoom | vpn_key | info(파랑) |
| 볼링 | bowling | sports_handball | info |
| 노래방 | karaoke | mic | warning(주황) |
| 술한잔 | drink | local_bar | warning |
| 보드게임 | boardGame | casino | success(초록) |
| 게임 | game | sports_esports | success |
| 등산 | hiking | terrain | success |
| 영화 | movie | movie | info |
| 카페 | cafe | local_cafe | warning |
| 기타 | etc | more_horiz | 중립(bgTertiary/textSecondary) |

### 3. 데이터 모델 (`meeting.dart`)
- `region`(짧은 지역명, 예 `"신림"`) 필드 추가. 달력 칩에 사용.
- 기존 `location`(전체, 예 `"신림 코인노래방"`)은 리스트 카드용으로 유지.

### 4. 그리드 (`calendar_grid.dart`)
- `buildMonthGrid`(6주) 및 그 테스트는 제거.
- 신규 함수:
  - `DateTime weekStartOf(DateTime day)` — 그 날이 속한 주의 일요일.
  - `List<DateTime> twoWeekGridFrom(DateTime weekStart)` — weekStart부터 14일.
  - `List<DateTime> buildTwoWeekGrid(DateTime today)` = `twoWeekGridFrom(weekStartOf(today))`.
- `isSameDay`는 유지.

### 5. 2주 캘린더 위젯 (`month_calendar.dart` → `two_week_calendar.dart`)
- 파일/클래스 이름을 `TwoWeekCalendar`로 변경.
- 요일 헤더 + 2개의 주 행. 각 행은 **고정 높이 104px**, 7개의 `Expanded` 셀.
  (GridView 비율 추정 대신 고정 높이를 써서 셀 높이를 예측 가능하게 — 칩 자동 채우기에 필요.)
- `windowStart`(보이는 2주의 시작 일요일)를 받아 그린다.
- 셀 흐림 기준: 기존 `inFocusedMonth` → **`isPast`(오늘 이전 날짜)**. 오늘 주의 지난 날들이 흐려진다.
- 좌우 스와이프 → `onWindowDelta(±14)` (왼쪽=다음 2주, 오른쪽=이전 2주).

### 6. 날짜 셀 (`day_cell.dart`)
- 파라미터 `inFocusedMonth` → `isPast`.
- 칩 = **한 줄** `카테고리·지역·제목` (말줄임), 카테고리 색상.
- **칩 자동 채우기**: `LayoutBuilder`로 칩 영역 높이를 측정해 들어갈 칩 수(`maxRows`)를 계산.
  - 모임 수 `n ≤ maxRows` → 전부 표시.
  - `n > maxRows` → `maxRows-1`개 칩 + `+N`(나머지) 표시.
  - 칩 높이 18, 간격 2 기준. 셀이 매우 짧으면 최소 1줄은 표시.

### 7. 홈 화면 (`home_screen.dart`)
- 상태: `_selectedDay`(기본 오늘), `_windowStart`(기본 `weekStartOf(today)`).
- `_selectDay(day)` → 선택일만 변경(2주 창 안의 날짜이므로 창 이동 없음).
- `_shiftWindow(days)` → `_windowStart += days`.
- 헤더 월 라벨: 보이는 14일의 첫날~끝날이 같은 달이면 `y년 M월`, 다른 달이면 `y년 M–M월`.
- 모임 리스트는 기존 `Expanded` + `ListView`로 스크롤 유지(2주 뷰로 영역이 커짐).

## 목 데이터 (`meeting_repository.dart`)
- `region` 포함. 오늘(5/16)~다음 주(5/23) 범위를 풍성하게 채운다.
- 과거(흐림) 예: 5/12 카페, 5/14 방탈출.
- **5/18은 비워** 빈 상태 시연.
- **5/19**에 고유 제목 "방탈출 호러 테마 같이!" 포함(탭 테스트용).
- **5/20에 6개** 모임(여러 카테고리) → `+N` 시연.

## 테스트
- `calendar_grid_test`: `twoWeekGridFrom`(14일/연속), `weekStartOf`(일요일 반환), `buildTwoWeekGrid`(첫 줄에 오늘 포함, 일요일 시작), `isSameDay` 유지.
- `day_cell_test`(신규): 모임 많을 때 `+N` 표시, 적을 때 미표시.
- `home_screen_test`(갱신): 초기 라벨 `2026년 5월`, 날짜 탭→리스트 갱신, 빈 날짜(5/18)→빈 상태, 스와이프→`2026년 5–6월`로 페이징, 과거 날짜 흐림(Opacity 0.45 존재).

## 범위 밖 (유지)
- 필터/검색/알림/FAB/다이아 재화는 표시 전용.
- 채팅/내모임/프로필 탭 플레이스홀더.
- 백엔드 연결.

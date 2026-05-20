# 모이자 — 홈 캘린더 화면 설계

작성일: 2026-05-20
대상: 모이자(공개 모임 플랫폼) 앱의 첫 화면 — 홈(월간 캘린더)
참조 목업: `docs/page/01_홈.html`

## 1. 배경 & 목표

모이자는 사용자가 **언제 어떤 모임이 있는지 캘린더로 즉시 파악**하는 공개 모임 플랫폼이다.
플랫폼 전체(인증·검색·참여·알림·채팅 등)는 범위가 크므로, 이번 작업은 첫 번째 하위 프로젝트인
**홈 화면(월간 캘린더)** 만을 다룬다.

### 이번 범위에서 결정된 사항
- **데이터**: 인메모리 목(mock) 데이터로 UI를 먼저 완성한다. 백엔드 연결은 이후 별도 작업.
- **동작 상호작용**: **날짜 선택**과 **월 이동**만 실제 동작한다.
- **표시 전용**: 필터 바, 검색·알림 아이콘, FAB(+), 다이아 재화 표시는 화면만 두고 동작은 다음 단계로 미룬다.
- **하단 탭**: 4탭(홈/채팅/내모임/프로필) 네비게이션 셸을 만들되 홈만 실제 구현하고 나머지는 빈 플레이스홀더.
- **캘린더 구현**: 외부 패키지(`table_calendar`)가 아닌 **직접 구현(custom 위젯)**. 목업의 특정 디자인을 픽셀 단위로 재현하기 위함.

### 성공 기준
- 목업 `01_홈.html`과 시각적으로 일치하는 홈 화면이 렌더링된다.
- 날짜를 탭하면 하단 요약과 모임 리스트가 해당 날짜로 갱신된다.
- 좌우 스와이프 또는 헤더로 월을 이동하면 그리드와 헤더 부제목이 바뀐다.
- 위젯/단위 테스트가 통과한다.

## 2. 폴더 / 파일 구조

기능 단위로 나눠 각 파일이 하나의 책임만 갖게 한다.

```
lib/
├── main.dart                          # 앱 진입점, 테마 주입, intl ko_KR 초기화
├── theme/
│   └── app_colors.dart                # 목업 CSS 변수 → Dart 색상 토큰
├── models/
│   ├── meeting.dart                   # 모임 데이터 모델
│   └── meeting_category.dart          # 카테고리 enum + 라벨/아이콘/색상
├── data/
│   └── meeting_repository.dart        # 인메모리 목 데이터 제공 + 날짜별 매핑
├── features/home/
│   ├── home_screen.dart               # 홈 화면 조립 + 상태(focusedMonth/selectedDay)
│   └── widgets/
│       ├── home_header.dart           # 타이틀·다이아·검색·알림
│       ├── filter_bar.dart            # 필터 칩 (표시 전용)
│       ├── month_calendar.dart        # 월간 캘린더 그리드 (직접 구현)
│       ├── day_cell.dart              # 날짜 셀 1칸 (오늘/선택/칩)
│       ├── selected_day_summary.dart  # "5월 19일 (화) · 모임 N개"
│       └── meeting_card.dart          # 모임 리스트 카드
└── shell/
    └── app_shell.dart                 # 하단 4탭 네비게이션 셸 (홈만 구현)
```

## 3. 데이터 모델

### MeetingCategory (`meeting_category.dart`)

```dart
enum MeetingCategory {
  escapeRoom,  // 방탈출 — Icons.vpn_key, info(파랑)
  bowling,     // 볼링   — Icons.sports_handball(또는 근접 아이콘), info(파랑)
}
```

각 카테고리는 다음 속성을 갖는다(확장 가능):
- `label` — 캘린더 칩/필터에 쓰는 짧은 한글 라벨 ("방탈출", "볼링")
- `icon` — Material 아이콘 (Tabler 웹폰트의 가장 가까운 대체)
- `backgroundColor` / `textColor` — 칩·아이콘 색상 토큰

### Meeting (`meeting.dart`)

```dart
class Meeting {
  final String id;
  final String title;          // "방탈출 호러 테마 같이!"
  final MeetingCategory category;
  final DateTime startTime;    // 날짜 + 시간(예: 2026-05-19 20:00)
  final String location;       // "강남 비밀의방"
  final int currentMembers;    // 2
  final int maxMembers;        // 4
}
```

- 캘린더 칩 라벨은 `category.label`에서 가져온다.
- "두 자리 남음" 같은 문구는 `maxMembers - currentMembers`로 계산하며 모델에 저장하지 않는다.
- 한국어 날짜 포맷("5월 19일 (화)", 요일 헤더)은 `intl` 패키지(`ko_KR` 로케일)로 처리한다.
  `pubspec.yaml`에 `intl` 의존성을 추가하고, `main()`에서 로케일 데이터를 초기화한다.

## 4. 데이터 소스 (`meeting_repository.dart`)

- 인메모리 목 데이터 리스트(`List<Meeting>`)를 보유한다. 목업과 일치하는 샘플 모임을 포함한다
  (예: 5/10 볼링, 5/14 방탈출, 5/16 볼링, 5/19 방탈출, 5/23 볼링, 5/28 방탈출).
- `Map<DateKey, List<Meeting>>` 형태의 **날짜별 매핑**을 한 번 만들어 캘린더 칩과 리스트가 공유한다.
  `DateKey`는 시간을 제외한 연·월·일 기준 키.
- 인터페이스를 단순하게 유지해(`meetingsOn(DateTime day)`, `allMeetings`) 이후 백엔드 구현으로 교체하기 쉽게 한다.

## 5. 상태 관리 & 캘린더 동작

`HomeScreen`을 `StatefulWidget`으로 두고 두 가지 상태만 관리한다. 외부 상태관리 패키지는 도입하지 않는다(YAGNI).

```dart
DateTime _focusedMonth;   // 현재 표시 중인 월 (월 이동 시 변경)
DateTime _selectedDay;    // 선택된 날짜 (날짜 탭 시 변경)
```

### 동작 흐름
- **앱 시작**: 목 데이터 기준 "오늘"을 **2026-05-16**으로 고정(목업과 일치).
  `_focusedMonth = 2026-05`, `_selectedDay = 2026-05-16`.
- **날짜 탭** → `setState`로 `_selectedDay` 변경 → 하단 요약·모임 리스트 갱신.
- **월 이동** → 좌우 스와이프 + 헤더 영역 조작으로 `_focusedMonth`를 ±1개월 → 그리드 재생성.

### 캘린더 그리드 계산 (`month_calendar.dart` 내부 순수 함수)
- 해당 월 1일의 요일을 구해 앞쪽 빈칸(이전 달 날짜)을 채우고 6주 격자(42칸)를 생성한다.
- 각 칸에 날짜 + 그날의 모임 목록을 매핑한다.
- **현재 월이 아닌 날짜**는 `opacity 0.45`로 흐리게 표시(목업과 동일).
- **오늘**: 숫자 둘레에 링(`today-ring`). **선택일**: 채운 원 + 셀 배경 강조(`selected-fill`).
- 일요일 숫자는 danger(빨강), 토요일 숫자는 info(파랑) 색.

## 6. 색상 / 테마 (`app_colors.dart`)

목업의 CSS 변수를 Dart 상수로 옮긴다.

- 배경: primary `#ffffff`, secondary `#f7f6f3`, tertiary `#f1efe8`, info `#e6f1fb`, success `#eaf3de`, warning `#faeeda`
- 텍스트: primary `#2c2c2a`, secondary `#5f5e5a`, tertiary `#888780`, info `#185fa5`, warning `#854f0b`, success `#3b6d11`, danger `#a32d2d`
- 보더: tertiary `rgba(0,0,0,0.15)`, info `#b5d4f4`

**아이콘**: 목업은 Tabler 웹폰트를 쓰지만 Flutter에선 폰트 추가 없이 가장 가까운 **Material Icons**로 매핑한다.
예: ti-key→`Icons.vpn_key`, ti-diamond→`Icons.diamond`, ti-search→`Icons.search`, ti-bell→`Icons.notifications_none`,
하단탭 home/chat/bookmark/person→`Icons.home`, `Icons.chat_bubble_outline`, `Icons.bookmark_border`, `Icons.person_outline`.

## 7. 에러 / 엣지 케이스

- 모임이 없는 날 선택 → 요약 "모임 0개" + 리스트 영역에 빈 상태 안내 텍스트.
- 한 셀에 모임이 여러 개 → 칩 1개만 표시하고 나머지는 "+N"로 축약.
- 월 이동으로 데이터 없는 달 → 빈 그리드를 정상 표시(에러 아님).

## 8. 테스트 (`flutter_test`)

- 그리드 날짜 계산 순수 함수 단위 테스트(특정 달의 시작 요일/칸 수/이전달 채움).
- 날짜 탭 → 하단 리스트가 해당 날짜 모임으로 갱신되는지 위젯 테스트.
- 월 이동 → 헤더 부제목("2026년 N월")과 그리드가 바뀌는지 위젯 테스트.
- 기존 `test/widget_test.dart`(카운터 데모 테스트)는 삭제 후 교체한다.

## 9. 범위 밖 (다음 단계)

- 필터 칩의 실제 필터링 동작
- 검색·알림·다이아 재화 화면 및 기능
- FAB(+) 모임 생성 플로우
- 채팅/내모임/프로필 탭의 실제 구현
- 백엔드(인증·서버 데이터·실시간 동기화) 연결
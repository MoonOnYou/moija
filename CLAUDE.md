# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 서비스 개요

**모이자(Moija)** — 날짜·카테고리·지역 기반 소모임 매칭 Flutter 앱(한국어 전용, `ko_KR` 로케일 고정).

백엔드는 별도 저장소 `/Users/onyoumoon/Documents/workspace/onyou/moija-server`(Django 6 / Python 3.12 / SQLite / `uv`)에 있다. API 연동 작업 시 서버 저장소의 CLAUDE.md를 함께 참고한다.

현재 서버에 구현된 엔드포인트는 `GET/POST /api/meetings/`, `GET /api/meetings/{id}/` 뿐이다. 인증·사용자·채팅·지갑·신고·탈퇴 도메인은 앱 쪽 mock으로 동작한다. **어떤 기능이 서버 연동 완료/미완료인지는 `docs/api-연동-체크리스트.md`에 추적되어 있으니 API 관련 작업 전 반드시 확인하고, 연동을 마치면 체크박스를 갱신한다.**

## 개발 명령어

```bash
flutter run                      # 앱 실행 (API 기본값 http://localhost:8000)
flutter test                     # 전체 테스트
flutter test test/home_screen_test.dart          # 단일 파일
flutter test test/home_screen_test.dart -n '패턴'  # 단일 테스트
flutter analyze                  # 정적 분석 (flutter_lints 기본 룰셋)

./scripts/dev-android.sh         # 안드로이드 기기/에뮬레이터 + Mac 로컬 서버 연동 실행
                                 # (adb reverse tcp:8000 자동 설정 후 flutter run)

# 서버 주소 변경
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# 에셋 재생성 (pubspec.yaml의 해당 설정 변경 시에만)
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## 아키텍처

### 상태 관리 — 라이브러리 없음
외부 상태관리 패키지를 쓰지 않는다. `StatefulWidget` + 전역 `ValueNotifier` 조합이다. `lib/shell/app_navigation.dart`의 세 노티파이어가 화면 간 교차 통신 채널이다:

- `selectedTab` — 셸 위에 push된 화면에서도 특정 탭으로 이동시킬 수 있게 한다.
- `pendingFocusDay` — 모임 생성 직후 홈 캘린더를 해당 날짜로 이동시킨다. `HomeScreen`이 소비 후 `null`로 되돌린다.
- `myMeetingsRevision` — 내모임 데이터 변경 시 bump. `AppShell`이 듣고 탭 배지를 갱신한다.

새 전역 신호가 필요하면 여기에 추가하고, 발신 측은 값만 바꾸고 수신 측이 구독·소비하는 패턴을 유지한다.

### 데이터 흐름 — 저장소 1개를 셸이 소유
`AppShell`이 `MeetingRepository`를 **하나만** 생성해 `HomeScreen`·`ChatScreen`에 주입한다. 탭 전환 시 상태 보존을 위해 `IndexedStack`을 쓰므로 화면들은 계속 살아 있다.

`MeetingRepository`(`lib/data/meeting_repository.dart`)는 두 종류의 데이터를 한 인스턴스에 담는다:

- **브라우즈 모임** — 홈 달력/목록에 노출. 서버 데이터. 날짜 인덱스(`_byDay` → `meetingsOn()`)에 들어간다. `AppShell`은 `browseSeed: false`로 하드코딩 시드를 끄고 API 결과만 `replaceBrowse()`로 채운다.
- **내 모임**(joined/hosted/pending) — 채팅·내모임 탭용. 아직 서버 엔드포인트가 없어 mock 시드가 유지되며, `replaceBrowse()`는 이들을 **보존**한다.

이 분리를 깨면 홈 달력에 하드코딩 모임이 섞여 보인다. 브라우즈 데이터를 건드릴 때 `_myIds` 보존 로직을 확인할 것.

### API 레이어
`lib/data/api/meeting_api.dart`가 유일한 API 파일이다. 최상위 함수(`createMeeting`/`fetchMeetings`/`fetchMeetingDetail`) 형태이며, 테스트 주입을 위해 모든 함수가 `@visibleForTesting http.Client? client`를 받는다.

- base URL은 `String.fromEnvironment('API_BASE_URL')`, 기본값 `http://localhost:8000`.
- 화면은 API 함수를 직접 import하지 않는다. `AppShell`이 `HomeScreen(loadMeetings:, fetchDetail:)`처럼 **함수를 주입**하고, 주입이 없으면(테스트/오프라인) 저장소의 기존 데이터를 쓴다. 새 화면에 API를 붙일 때도 이 콜백 주입 방식을 따른다.
- 서버 필드명은 snake_case, 앱 모델은 camelCase. 변환은 `Meeting.fromJson`과 API 함수의 body 조립부에서만 한다. `fromJson`은 알 수 없는 enum 값을 안전한 기본값(`category→etc`, `joinMethod→approval`, `cost→split`)으로 낮춘다.
- 인증 도입 전까지 `lib/data/current_user.dart`의 `CurrentUser.hostPayload`가 서버 필수 `host` 필드를 채운다. 로그인 연동 시 이 클래스를 실제 사용자로 교체하는 것이 진입점이다.

### 멀티스텝 플로우
가입(`features/signup/`)과 탈퇴(`features/withdrawal/`)는 Navigator push 체인이다.

- 가입: `SignupSession` 인스턴스 하나를 각 화면에 넘기며 채워 나간다. 모든 단계 라우트에 `kSignupRouteName`을 달아 `confirmExitSignup()`이 `popUntil`로 플로우 전체를 한 번에 닫는다. 단계를 추가할 때 `signupRoute()`를 써야 이 종료 처리가 동작한다(서브 피커 등은 일반 라우트로).
- 탈퇴: `WithdrawalFlow`가 4단계를 순차 push.

### 테스트 관례
- 결정적 테스트를 위해 시간·데이터를 주입한다: `HomeScreen(today: DateTime(2026, 5, 16))`, `MeetingRepository.test(meetings:, joined:, hosted:, pending:)`, `MeetingRepository(baseTime:)`.
- 위젯 테스트는 `tester.view.physicalSize = Size(390, 844)` + `devicePixelRatio = 1.0`으로 화면 크기를 고정하고 `addTearDown(tester.view.reset)`한다.
- `initializeDateFormatting('ko_KR')`를 `setUpAll`에서 호출해야 `intl` 포맷이 동작한다. `SharedPreferences.setMockInitialValues({})`로 필터 영속을 초기화한다.
- API 테스트는 `package:http/testing.dart`의 `MockClient`를 `client:` 인자로 주입한다.

## 컬러/테마

`lib/theme/app_colors.dart`의 토큰만 사용한다(브랜드 가이드 `docs/app/브랜드-가이드.html` 기준). 하드코딩 `Color(0x...)`를 새로 만들지 않는다.

- `coral` — CTA·액션·선택 칩 (주 브랜드색)
- `mint` — 출석·진행 상태 / `amber` — 하이라이트(소량)
- `bgPrimary`(흰색, Scaffold 기본) / `bgSecondary`(입력칸·옅은 칩) / `cream`(스플래시 배경)
- `textPrimary/Secondary/Tertiary`, 시맨틱 `textInfo/Warning/Success/Danger` + 대응 `bgInfo/Warning/Success`

## 설계 문서

`docs/superpowers/specs/`(설계) · `docs/superpowers/plans/`(구현 계획)에 기능별 문서가 날짜 프리픽스로 쌓여 있다. 기존 화면을 크게 고칠 때는 해당 기능 문서를 먼저 확인한다. `docs/page/*.html`은 화면별 디자인 목업이다.

커밋 메시지는 한글 + Conventional Commits 프리픽스(`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`)를 쓴다.

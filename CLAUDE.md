# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 서비스 개요

**모이자(Moija)** — 날짜·카테고리·지역 기반 소모임 매칭 Flutter 앱. 백엔드 서버는 `/Users/onyoumoon/Documents/workspace/onyou/moija-server`(Django)에 있으며, API 연동 개발 시 해당 경로를 참고한다.

현재 앱은 인메모리 mock 데이터(`MeetingRepository`)로 동작한다. 백엔드 API를 붙일 때는 `MeetingRepository`를 교체하거나 감싸는 방식으로 연동한다.

## 개발 명령어

```bash
# 앱 실행
flutter run

# 전체 테스트
flutter test

# 단일 테스트 파일
flutter test test/<파일명>_test.dart

# 정적 분석
flutter analyze

# 런처 아이콘 생성 (pubspec.yaml의 flutter_launcher_icons 변경 시)
dart run flutter_launcher_icons

# 네이티브 스플래시 생성 (pubspec.yaml의 flutter_native_splash 변경 시)
dart run flutter_native_splash:create
```

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점, MoijaApp (한국어 로케일, coral 테마)
├── shell/
│   ├── app_shell.dart     # 3탭 바텀 내비 + IndexedStack (홈·내모임·프로필)
│   ├── app_navigation.dart# 전역 ValueNotifier (selectedTab, pendingFocusDay, myMeetingsRevision)
│   └── connectivity_gate.dart # 네트워크 오프라인 감지·오버레이
├── features/
│   ├── home/              # 달력 + 모임 목록 (HomeScreen)
│   ├── meeting/           # 모임 상세·생성·신청자 검토·매너 리뷰·다이아 충전
│   ├── chat/              # 내모임 채팅 목록 + 채팅방
│   ├── profile/           # 프로필·차단 목록·텍스트 편집
│   ├── signup/            # 8단계 가입 플로우 (SignupSession으로 상태 전달)
│   ├── filter/            # 카테고리·장소·시간대 필터
│   ├── withdrawal/        # 4단계 회원 탈퇴 플로우
│   ├── splash/            # 스플래시 → AppShell 전환
│   └── common/            # 공통 위젯 (네트워크 오류·강제 업데이트·신고 등)
├── data/
│   ├── meeting_repository.dart # 인메모리 mock 저장소 (백엔드 연동 시 교체 대상)
│   ├── filter_storage.dart     # SharedPreferences 기반 필터 영속
│   ├── wallet.dart             # 다이아 잔액 (mock 상수)
│   ├── category_catalog.dart   # 카테고리 전체 목록
│   └── location_catalog.dart   # 장소 트리 (지역·지하철역)
├── models/                # Meeting, Member, MeetingFilter, MeetingCategory, MeetingCost, JoinMethod 등
└── theme/
    ├── app_colors.dart    # 브랜드 컬러 토큰 (coral·mint·amber 계열)
    └── moija_logo.dart
```

## 아키텍처 핵심

- **상태 관리**: 외부 라이브러리 없이 `StatefulWidget` + `ValueNotifier` 조합 사용. 전역 탭 이동은 `app_navigation.dart`의 `ValueNotifier`를 직접 수정한다.
- **화면 간 데이터 공유**: `AppShell`이 `MeetingRepository` 인스턴스를 생성해 `HomeScreen`·`ChatScreen`에 주입한다. 탭 전환 시 상태 유지를 위해 `IndexedStack` 사용.
- **가입 플로우**: `SignupSession` 객체를 Navigator push 체인으로 전달하며 각 단계가 채운다.
- **탈퇴 플로우**: `WithdrawalFlow` 가 4단계 화면을 순차 push한다.
- **테스트 주입**: `HomeScreen(today:, repository:)`, `MeetingRepository.test(...)` 생성자로 날짜·데이터를 고정해 결정적 테스트를 작성한다.

## 컬러/테마 규칙

`AppColors`의 토큰만 사용한다. 주요 토큰:
- `coral` — CTA·액션 (주 브랜드색)
- `mint` — 출석·진행 상태
- `amber` — 강조·하이라이트
- `bgPrimary`(흰색) / `bgSecondary`(크림) — 배경 계층
- `textPrimary/Secondary/Tertiary` — 텍스트 계층

## 백엔드 서버 (moija-server)

경로: `/Users/onyoumoon/Documents/workspace/onyou/moija-server`  
스택: Django 6+ / Python 3.12 / SQLite / 패키지 관리는 `uv`

API 연동 개발 시 서버 CLAUDE.md를 함께 참고한다. 서버의 도메인 모델(Meeting·Member·MeetingFilter·Wallet)은 Flutter 클라이언트 모델 구조와 맞춰 설계한다.

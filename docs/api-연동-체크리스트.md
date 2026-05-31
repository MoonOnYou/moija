# API 연동 체크리스트

> 작성: 2026-05-31 · 앱 mock → 백엔드(`moija-server`, Django) 연동 추적용
>
> 범례:
> - 🟢 **서버 준비됨** — 엔드포인트 존재, 앱만 연결하면 됨
> - 🟠 **서버 일부** — 엔드포인트는 있으나 필드/기능 보강 필요
> - 🔴 **서버 미구현** — 서버 + 앱 양쪽 모두 작업 필요
>
> 현재 서버 구현: `GET/POST /api/meetings/`, `GET /api/meetings/{id}/` 만 존재. 인증·사용자·채팅·지갑·신고·탈퇴 도메인은 미구현.

---

## Phase 1 — 기본 기능 (앱 핵심 동작)

### 모임 조회
- [ ] 🟢 모임 목록 조회 — `GET /api/meetings/?date=YYYY-MM-DD` (또는 `date_from`/`date_to`, `categories`, `location_ids`, `time_bands`)
  - 앱: `lib/data/meeting_repository.dart`의 `allMeetings`/`meetingsOn()` mock 교체
  - 서버 필터링 로직 이미 구현됨 (날짜·카테고리·지역·시간대)
- [ ] 🟢 모임 상세 조회 — `GET /api/meetings/{id}/`
  - 앱: `lib/features/meeting/meeting_detail_screen.dart`
- [x] 🟢 모임 생성 — `POST /api/meetings/` *(완료: `lib/data/api/meeting_api.dart`)*

### 인증 (서버 전체 미구현)
- [ ] 🔴 OTP 발송 — `POST /api/auth/send-otp/`
  - 앱: `lib/features/signup/signup_phone_screen.dart`
- [ ] 🔴 OTP 검증 — `POST /api/auth/verify-otp/`
  - 앱: `lib/features/signup/signup_otp_screen.dart` (현재 아무 6자리나 통과)
- [ ] 🔴 회원가입 완료 — `POST /api/auth/register/`
  - 앱: `lib/features/signup/signup_complete_screen.dart` + `SignupSession` 전체 페이로드
- [ ] 🔴 로그인 — `POST /api/auth/login/`
- [ ] 🔴 로그아웃 — `POST /api/auth/logout/`
  - 앱: `lib/features/profile/profile_screen.dart` (현재 stub)
- [ ] 🔴 토큰 인증 체계 (JWT 등) — 이후 모든 `/api/me/*` 호출에 필요

### 내 모임 / 참가
- [ ] 🔴 내 모임 목록 — `GET /api/me/meetings/?status=joined|hosted|pending`
  - 앱: `meeting_repository.dart`의 `myJoinedIds`/`myHostedIds`/`myPendingIds`
- [ ] 🔴 참가 신청(선착순) — `POST /api/me/meetings/{id}/join/`
- [ ] 🔴 참가 신청(승인제) — `POST /api/me/meetings/{id}/apply/`
- [ ] 🔴 신청 취소 — `DELETE /api/me/meetings/{id}/pending/`
- [ ] 🔴 모임 탈퇴 — `DELETE /api/me/meetings/{id}/`
  - 앱: `meeting_detail_screen.dart`의 `_onApply`, `cancelPending()`, `leave()`

---

## Phase 2 — 핵심 상호작용

### 모임 멤버 (서버에 멤버 모델 없음)
- [ ] 🔴 모임 멤버 목록 — `GET /api/meetings/{id}/members/`
  - 앱: `participantsOf()` (현재 id 해시 기반 mock)
  - 서버: `Meeting` 모델에 멤버/호스트/현재인원 관계 추가 필요

### 신청자 검토 (방장용)
- [ ] 🔴 신청자 목록 — `GET /api/me/meetings/{id}/applicants/`
- [ ] 🔴 신청 수락 — `POST /api/me/meetings/{id}/applicants/{userId}/accept/`
- [ ] 🔴 신청 거절 — `POST /api/me/meetings/{id}/applicants/{userId}/reject/`
  - 앱: `lib/features/meeting/applicant_review_screen.dart` (`_seedApplicants` mock)

### 채팅
- [ ] 🔴 채팅 히스토리 — `GET /api/meetings/{id}/messages/`
- [ ] 🔴 메시지 전송 — `POST /api/meetings/{id}/messages/`
- [ ] 🔴 채팅 미리보기 목록 — `GET /api/me/messages/preview/` (미읽음 배지 포함)
- [ ] 🔴 읽음 표시 — `PATCH /api/meetings/{id}/messages/{messageId}/read/`
  - 앱: `lib/features/chat/` (`mockMessagesFor`, `ChatPreview.forMeeting`)
  - 참고: 실시간 필요 시 WebSocket(Django Channels) 검토

### 프로필
- [ ] 🔴 내 프로필 조회 — `GET /api/me/`
- [ ] 🔴 닉네임 수정 — `PATCH /api/me/profile/nickname/`
- [ ] 🔴 자기소개 수정 — `PATCH /api/me/profile/intro/`
  - 앱: `lib/features/profile/profile_screen.dart` (mock 프로필 상수)

---

## Phase 3 — 부가 기능

### 매너 평가
- [ ] 🔴 매너 평가 제출 — `POST /api/me/meetings/{id}/reviews/`
  - 앱: `lib/features/meeting/manner_review_screen.dart`

### 지갑 / 다이아
- [ ] 🔴 잔액 조회 — `GET /api/me/wallet/`
  - 앱: `lib/data/wallet.dart` (현재 `myDiamonds = 500` 상수)
- [ ] 🔴 충전 패키지 목록 — `GET /api/diamond-packages/`
- [ ] 🔴 다이아 충전 — `POST /api/me/wallet/charge/` (결제 연동 별도)
- [ ] 🔴 다이아 차감 — 모임 신청 시 (서버 트랜잭션으로 처리 권장)
  - 앱: `lib/features/meeting/diamond_recharge_screen.dart` (결제 버튼 stub)

### 신고 / 차단
- [ ] 🔴 사용자 신고 — `POST /api/reports/`
  - 앱: `lib/features/common/report_screen.dart`
- [ ] 🔴 차단 목록 조회 — `GET /api/me/blocked-users/`
- [ ] 🔴 차단 추가 — `POST /api/me/blocked-users/`
- [ ] 🔴 차단 해제 — `DELETE /api/me/blocked-users/{userId}/`
  - 앱: `lib/features/profile/block_list_screen.dart`, `lib/features/common/block_screen.dart`

### 회원 탈퇴
- [ ] 🔴 탈퇴 OTP 검증 — `POST /api/auth/verify-otp/` (재사용)
- [ ] 🔴 탈퇴 실행 — `POST /api/me/withdraw/`
  - 앱: `lib/features/withdrawal/` (현재 최종 탈퇴 호출 없음)

---

## API 불필요 (로컬/정적 데이터 유지)

- [x] 필터 프리셋 — `lib/data/filter_storage.dart` (SharedPreferences, 개인 디바이스 저장)
- [x] 카테고리 카탈로그 — `lib/data/category_catalog.dart` (정적, 변경 잦으면 API화 검토)
- [x] 장소/지하철 트리 — `lib/data/location_catalog.dart` (정적)
- [x] 약관 동의 화면 — `lib/features/common/notice_screen.dart` (동의 기록은 register에 포함)

---

## 선행 작업 (모든 `/api/me/*`의 전제)

- [ ] 🔴 서버: 사용자(User) 모델 + 인증 앱(`apps/accounts`) 신설
- [ ] 🔴 서버: `Meeting`에 host/members 관계 추가 (멤버·신청자·채팅의 기반)
- [ ] 앱: 공통 API 클라이언트 정리 — base URL 환경 분기(현재 `meeting_api.dart`에 `localhost:8000` 하드코딩), 인증 헤더 주입, 에러 처리 통일

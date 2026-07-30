# API 연동 체크리스트

> 작성: 2026-05-31 · 앱 mock → 백엔드(`moija-server`, Django) 연동 추적용
>
> 범례:
> - 🟢 **서버 준비됨** — 엔드포인트 존재, 앱만 연결하면 됨
> - 🟠 **서버 일부** — 엔드포인트는 있으나 필드/기능 보강 필요
> - 🔴 **서버 미구현** — 서버 + 앱 양쪽 모두 작업 필요
>
> 현재 서버 구현: 모임(`GET/POST /api/meetings/`, `GET /api/meetings/{id}/`) + 채팅(히스토리·전송·읽음·실시간 WebSocket·기기등록) + 인증(`apps.accounts`: OTP·회원가입·로그인·JWT·프로필·탈퇴). 지갑·신고·모임멤버/참가 REST는 미구현.

---

## Phase 1 — 기본 기능 (앱 핵심 동작)

### 모임 조회
- [x] 🟢 모임 목록 조회 — `GET /api/meetings/?date=YYYY-MM-DD` (또는 `date_from`/`date_to`, `categories`, `location_ids`, `time_bands`) *(완료: `app_shell.dart` loadMeetings → `home_screen.dart`)*
  - 서버 필터링 로직 이미 구현됨 (날짜·카테고리·지역·시간대)
- [x] 🟢 모임 상세 조회 — `GET /api/meetings/{id}/` *(완료: `app_shell.dart` fetchDetail)*
- [x] 🟢 모임 생성 — `POST /api/meetings/` *(완료: `lib/data/api/meeting_api.dart`)*

### 인증 *(서버 `apps.accounts` 구현 완료 — 앱 연동 남음)*
- [ ] 🟢 OTP 발송 — `POST /api/auth/send-otp/` `{phone}` → `{detail, dev_code(DEBUG)}`
  - 앱: `lib/features/signup/signup_phone_screen.dart`. 개발 중엔 응답 `dev_code`로 자동입력 가능.
- [ ] 🟢 OTP 검증 — `POST /api/auth/verify-otp/` `{phone, code, purpose}` → `{verification_token}`
  - 앱: `lib/features/signup/signup_otp_screen.dart` (현재 아무 6자리나 통과 → 실제 검증으로 교체)
- [ ] 🟢 회원가입 — `POST /api/auth/register/` (SignupSession 전체 + `verification_token`) → `{access, refresh, user}`
  - 앱: `signup_complete_screen.dart` 또는 `signup_intro_screen.dart._next`가 연동 지점. 필드: phone, password, nickname, gender(male/female), birth_year, intro, interest_categories[], interest_locations[], agreed_* 5개
- [ ] 🟢 로그인 — `POST /api/auth/login/` `{phone, password}` → `{access, refresh, user}`
  - 앱: 전용 로그인 화면 신규 필요(현재 없음). `signup_start_screen`의 "이미 계정이 있어요" 자리.
- [ ] 🟢 로그아웃 — `POST /api/auth/logout/` `{refresh}` (블랙리스트)
  - 앱: `lib/features/profile/profile_screen.dart` (현재 stub)
- [ ] 🟢 JWT 토큰 체계 — `Authorization: Bearer <access>`. 앱: access/refresh를 SharedPreferences 저장 + API 헤더 주입 계층 신설 (현재 chat의 `X-Participant-Id`를 대체)

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

### 채팅 *(서버 `apps.chat` 구현 완료 · 앱 라이브 모드 배선 완료 — 인증 전까지 개발용 브리지)*
- [x] 🟢 채팅 히스토리 — `GET /api/meetings/{id}/messages/` *(앱: `lib/data/api/chat_api.dart` `fetchMessages`)*
- [x] 🟢 메시지 전송 — `POST /api/meetings/{id}/messages/` *(REST `sendMessage` + WebSocket `send`)*
- [x] 🟢 읽음 표시 — `PATCH /api/meetings/{id}/read/` body `{last_read_message_id}` *(REST `markRead` + WebSocket `read`)*
- [x] 🟢 실시간 — WebSocket `ws://<host>/ws/meetings/{id}/?participant_id=<id>` *(앱: `lib/data/chat/chat_socket.dart`, `message.new`/`read.update` 구독)*
- [ ] 🟠 채팅 미리보기 목록 — `GET /api/me/messages/preview/` (미읽음 배지 포함)
  - 서버는 구현됨. 앱 채팅 리스트(`ChatScreen`)는 아직 `ChatPreview.forMeeting` mock 사용 → 라이브 배선 미완.
- **참고(중요):** 앱에 아직 로그인·"내 모임" API가 없어 현재 사용자의 `participant_id`를 알 수 없다. 개발용 브리지 `lib/data/chat/chat_dev_config.dart`가 `--dart-define`(`CHAT_LIVE_MEETING_ID`/`CHAT_LIVE_PARTICIPANT_ID`/`CHAT_LIVE_NICKNAME`)으로 특정 서버 모임에 붙는다. 세 값이 없으면 기존 mock 채팅으로 동작(회귀 0). 인증·내모임 연동 시 이 브리지를 제거하고 각 방의 실제 서버 모임 id로 배선한다.

### 프로필 *(서버 완료 — 앱 연동 남음)*
- [ ] 🟢 내 프로필 조회 — `GET /api/me/` (인증 필요) → nickname, birth_year, gender, manner_score, total_activities, intro, interest_*
- [ ] 🟢 프로필 수정(닉네임·자기소개) — `PATCH /api/me/` `{nickname?, intro?}`
  - 앱: `lib/features/profile/profile_screen.dart` (mock 프로필 상수 교체)
  - 참고: 서버는 닉네임/자기소개 통합 PATCH. 매너점수·활동수는 read-only.

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

### 회원 탈퇴 *(서버 완료 — 앱 연동 남음)*
- [ ] 🟢 탈퇴 OTP 검증 — `POST /api/auth/verify-otp/` `purpose=withdraw` (재사용)
- [ ] 🟢 탈퇴 실행 — `POST /api/me/withdraw/` `{reasons[], detail}` (인증 필요, soft delete + 30일 재가입 제한)
  - 앱: `lib/features/withdrawal/` (현재 최종 탈퇴 호출 없음)
- [ ] 🔴 방장 위임 — `POST /api/me/meetings/{id}/transfer-host/` `{new_host_id}`
  - 앱: `lib/features/withdrawal/host_delegation_screen.dart` → `MeetingRepository.delegateHost()` (현재 로컬 mock)
  - 서버: 멤버 모델 + 호스트 관계가 먼저 필요(위 "모임 멤버" 항목)
  - 방장이 모임을 닫는 동작은 제공하지 않는다. 멤버가 방장뿐인 모임은 탈퇴 시 서버가 함께 정리한다.

---

## API 불필요 (로컬/정적 데이터 유지)

- [x] 필터 프리셋 — `lib/data/filter_storage.dart` (SharedPreferences, 개인 디바이스 저장)
- [x] 카테고리 카탈로그 — `lib/data/category_catalog.dart` (정적, 변경 잦으면 API화 검토)
- [x] 장소/지하철 트리 — `lib/data/location_catalog.dart` (정적)
- [x] 약관 동의 화면 — `lib/features/common/notice_screen.dart` (동의 기록은 register에 포함)

---

## 선행 작업 (모든 `/api/me/*`의 전제)

- [x] 🟢 서버: 사용자(User) 모델 + 인증 앱(`apps/accounts`) 신설 *(완료: 전화번호 커스텀 User + JWT)*
- [ ] 🟠 서버: `Meeting`에 host/members 관계 추가 (멤버·신청자·채팅의 기반)
  - `MeetingParticipant` 모델은 존재하나 아직 User FK 없음(값 스냅샷). 인증 연동 시 User 연결 + 멤버/참가 REST 노출 필요.
- [ ] 앱: 공통 API 클라이언트 정리 — base URL 환경 분기(현재 `meeting_api.dart`/`chat_api.dart`에 `localhost:8000`), **JWT 토큰 저장(SharedPreferences) + `Authorization: Bearer` 헤더 주입 계층 신설**, 에러 처리 통일. chat의 `X-Participant-Id`도 이때 토큰 기반으로 대체.

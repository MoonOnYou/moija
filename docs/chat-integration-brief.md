# Flutter 채팅 연결 지시문 (moija 앱 → moija-server)

## 목표
현재 인메모리 mock으로 동작하는 채팅을 **실제 백엔드 API + WebSocket**에 연결한다.
채팅방은 모임(Meeting)별로 하나씩이며, "메시지별 안읽음 수"는 **서버가 권위 있게 계산**하므로 클라이언트가 직접 세지 말고 서버 값을 그대로 표시한다.

먼저 앱의 채팅 관련 화면·모델·mock repository를 분석한 뒤, 아래 계약에 맞춰 연결하라. **계약에 없는 필드/동작을 추측하지 말 것.**

---

## 서버 접속 정보 (로컬 개발)
서버는 ASGI(daphne)로 띄워야 WebSocket이 동작한다. 서버 쪽에서:
```bash
uv run python manage.py runserver        # daphne가 ASGI로 서빙(WS 지원), 기본 8000 포트
# 또는: uv run daphne config.asgi:application
```

Flutter 앱이 도는 환경에 따라 **호스트 주소가 다르다**(로컬 서버는 `localhost:8000`):

| 실행 환경 | REST Base URL | WebSocket Base URL |
|-----------|---------------|--------------------|
| iOS 시뮬레이터 | `http://127.0.0.1:8000` | `ws://127.0.0.1:8000` |
| Android 에뮬레이터 | `http://10.0.2.2:8000` | `ws://10.0.2.2:8000` |
| 실기기(같은 Wi-Fi) | `http://<맥의 LAN IP>:8000` | `ws://<맥의 LAN IP>:8000` |

→ base URL은 **빌드 환경변수/설정 파일 한 곳**에 두고 위 값 중 하나를 주입하도록 만들어라(하드코딩 산재 금지).

- ⚠️ **인증 미구현(임시)**: 로그인 대신 아래 임시 식별자를 사용한다. 코드에 `TODO(auth)` 주석을 남겨라.
  - REST: HTTP 헤더 `X-Participant-Id: <participant_id>`
  - WebSocket: 쿼리스트링 `?participant_id=<participant_id>`
- 실제 `meeting_id` / `participant_id`는 아직 로그인이 없으니, 서버 admin 또는 시드로 만든 모임·참가자 값을 개발 중 수동 주입한다.

## 식별자 타입 (엄수)
- `meeting_id` — **UUID 문자열** (예: `"dda7e767-..."`)
- `participant_id` — **정수** (모임 참가자 PK)
- 메시지 `id` — **정수**
- `sent_at` — ISO8601 문자열, KST 오프셋 포함 (예: `"2026-06-22T10:00:00+09:00"`)

---

## REST API 계약

### 1) 채팅 히스토리 조회
`GET /api/meetings/{meeting_id}/messages/`  — 헤더 `X-Participant-Id` 필수
- 200: 메시지 배열 (created_at 오름차순 = 오래된→최신)
```json
[{ "id": 12, "type": "user", "text": "안녕", "sent_at": "2026-06-22T10:00:00+09:00", "sender": "온유", "unread_count": 3 }]
```
- `type`: `"user"` | `"system"` (시스템 메시지는 `sender: null`)
- `sender`: 보낸 사람 **닉네임 문자열** (id 아님), 시스템 메시지면 `null`
- `unread_count`: 이 메시지를 아직 안 읽은 인원 수(보낸 사람 제외)

### 2) 메시지 전송
`POST /api/meetings/{meeting_id}/messages/`  — 헤더 `X-Participant-Id` 필수
- Body: `{ "text": "..." }`
- 201: 생성된 메시지 1건(위 히스토리와 동일 구조)
- 400: `{ "detail": "text는 비어 있을 수 없습니다." }` (빈 text)
- ⚠️ WS를 연결한 상태라면 이 메시지는 WebSocket `message.new` 로도 되돌아온다(중복 주의, 아래 참고).

### 3) 읽음 위치 갱신
`PATCH /api/meetings/{meeting_id}/read/`  — 헤더 `X-Participant-Id` 필수
- Body: `{ "last_read_message_id": <정수> }` (이 메시지까지 읽음 처리)
- 200: `{ "unread": { "<message_id>": 0, ... } }`  ← **영향받은 메시지만** 부분 갱신 맵
- 400: `last_read_message_id` 누락/타입 오류

### 4) 채팅 목록(미리보기)
`GET /api/me/messages/preview/?participant_ids=1,2,3`  (내 여러 방을 한 번에)
- 200:
```json
[{ "meeting_id": "uuid", "title": "모임제목", "last_sender": "온유", "last_message": "마지막", "last_time": "2026-06-22T10:00:00+09:00", "unread_count": 2 }]
```
- 메시지 없는 방이면 `last_*`는 `null`, `unread_count: 0`

### 5) FCM 기기 등록
`POST /api/me/devices/`  — 헤더 `X-Participant-Id` (있으면 참가자에 연결)
- Body: `{ "token": "<fcm_token>", "platform": "ios" | "android" }`
- 201(신규) 또는 200(갱신): `{ "token": "...", "platform": "..." }`

### 공통 에러
- 헤더 `X-Participant-Id` 누락 → 400 `{ "detail": "X-Participant-Id 헤더가 필요합니다." }`
- 잘못된 participant id → 400
- 다른 모임 소속 participant → 403 `{ "detail": "해당 모임의 멤버가 아닙니다." }`

---

## WebSocket 계약

접속: `ws(s)://<HOST>/ws/meetings/{meeting_id}/?participant_id=<id>`
- 방 멤버가 아니거나 잘못된 id면 서버가 **즉시 연결을 close** → 재시도/에러 처리.

### 클라이언트 → 서버 (JSON)
- 전송: `{ "type": "send", "text": "..." }`
- 읽음: `{ "type": "read", "last_read_message_id": <정수> }`

### 서버 → 클라이언트 (JSON)
- 새 메시지: `{ "type": "message.new", "message": { ...히스토리와 동일 구조... } }`
- 읽음 갱신: `{ "type": "read.update", "unread": { "<message_id>": 1, ... } }`

---

## 구현 지시 (중요 함정 포함)

1. **mock repository를 실제 API로 교체.** 기존 화면/모델 구조는 유지하고 데이터 소스만 교체한다. 서버 필드명(`sender`, `sent_at`, `unread_count`)을 앱 모델에 매핑하라.

2. **하이브리드 로딩:** 방 진입 시 REST(1)로 히스토리를 먼저 로드 → 이후 실시간은 WebSocket으로 수신. 전송/읽음도 가능하면 WebSocket으로(오프라인/미연결 시 REST로 폴백).

3. **자기 메시지 에코 중복 방지:** WS로 `send` 하면 자신도 `message.new`를 받는다. 낙관적으로 먼저 그린 뒤 서버 메시지 `id` 기준으로 dedup/치환하라. (REST POST로 보낸 뒤 WS로도 같은 게 오는 경우도 동일하게 id로 dedup.)

4. **unread_count는 서버가 진실:** 직접 계산 금지. `message.new`의 값으로 초기화하고, `read.update`가 오면 **맵에 담긴 message_id들만 부분 갱신**(전체 목록 교체 아님). PATCH(3) 응답의 `unread` 맵도 동일하게 부분 병합.

5. **읽음 트리거:** 사용자가 방을 보고 있을 때(화면 포커스/스크롤 최하단) 마지막 수신 메시지 id로 `read`(WS) 또는 PATCH(3)를 보내라.

6. **재연결:** WS 끊기면 지수 백오프로 재접속하고, 재접속 후 REST(1)로 히스토리를 재동기화(놓친 메시지 보정).

7. **FCM(선택):** 푸시 토큰 확보 시 (5)로 등록. 앱이 포그라운드/해당 방을 보고 있으면 로컬 알림은 억제.

8. `X-Participant-Id` / `?participant_id=`는 임시 인증 우회다. 한 곳(예: ApiClient/환경설정)에 모아두고 전부 `TODO(auth)`로 표기해 나중에 로그인 토큰으로 교체하기 쉽게 하라.

## 검증
- 두 기기(또는 두 participant_id)로 같은 방 접속 → 한쪽에서 보낸 메시지가 다른 쪽에 실시간 표시.
- 상대가 읽으면 내 메시지의 안읽음 수가 실시간으로 줄어든다.
- 방 나갔다 재진입 시 히스토리가 REST로 복원된다.

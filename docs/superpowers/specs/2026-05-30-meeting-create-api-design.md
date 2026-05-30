# 모임 생성 API 연동 설계

**날짜:** 2026-05-30  
**범위:** 모임 생성(`POST /api/meetings/`) 연동. 목록 조회는 이 스펙 밖.

---

## 배경

Flutter 앱은 현재 `MeetingRepository`(인메모리 mock)로 모임 생성을 처리한다. Django 서버에 `POST /api/meetings/` 엔드포인트가 완성됐고, 생성 흐름을 이 API로 교체한다. 생성 후 달력에 즉시 반영하는 기능은 목록 API가 없으므로 이번 범위에서 제외한다.

---

## 아키텍처

### 새 파일: `lib/data/api/meeting_api.dart`

단일 함수 `createMeeting(Meeting m) → Future<void>` 를 노출한다.

- 기본 URL: `http://localhost:8000`
- 엔드포인트: `POST /api/meetings/`
- HTTP 패키지: `http` (pubspec.yaml에 추가)
- 2xx 외 응답 → `Exception` throw
- 네트워크 오류 → 그대로 throw (SocketException 등)

### 수정 파일: `lib/features/meeting/create_meeting_screen.dart`

`_submit()` 내부만 변경한다.

- `_loading` bool 상태 추가
- `widget.repository.add(meeting)` 제거 → `await createMeeting(meeting)` 으로 교체
- 성공: 기존 탭 이동(채팅) + "모임이 생성됐어요" 스낵바
- 실패: "모임 생성에 실패했어요" 스낵바, 화면 유지
- 로딩 중: 제출 버튼 비활성화 + `CircularProgressIndicator`

---

## 필드 매핑 (Flutter → 서버 JSON)

| Flutter 필드 | JSON 키 | 변환 방식 |
|---|---|---|
| `m.title` | `title` | 그대로 |
| `m.category.name` | `category` | enum `.name` (예: `"cafe"`) |
| `m.customCategory` | `custom_category` | 그대로 |
| `m.startTime.toIso8601String()` | `start_time` | ISO 8601 |
| `m.location` | `location` | 그대로 |
| `m.region` | `region` | 그대로 |
| `m.locationId` | `location_id` | 그대로 |
| `m.maxMembers` | `max_members` | 그대로 |
| `m.description` | `description` | 그대로 |
| `m.nearestStation` | `nearest_station` | 그대로 |
| `m.joinMethod.name` | `join_method` | enum `.name` (예: `"approval"`) |
| `m.cost.type.name` | `cost_type` | enum `.name` (예: `"split"`) |
| `m.cost.amountWon` | `cost_amount_won` | paid일 때만 포함, 나머지 null |
| `m.cost.customText` | `cost_custom_text` | custom일 때만 포함, 나머지 `""` |

**서버에서 자동 생성:** `id`(UUID), `created_at` → 클라이언트에서 보내지 않음.  
**클라이언트 전용 필드:** `currentMembers`, `customIcon` → 서버 모델 없음, 전송 제외.

---

## 의존성

- `pubspec.yaml`: `http: ^1.2.0` 추가
- `MeetingRepository`: 변경 없음 (테스트 격리용 생성자 유지)

---

## 에러 처리

| 상황 | 처리 |
|---|---|
| 네트워크 단절 | "모임 생성에 실패했어요" 스낵바, 화면 유지 |
| 서버 4xx/5xx | "모임 생성에 실패했어요" 스낵바, 화면 유지 |
| 성공 | 채팅 탭 이동 + "모임이 생성됐어요" 스낵바 |

---

## 범위 밖 (이번 스펙에서 제외)

- 목록 조회 API 연동 (생성된 모임이 달력에 즉시 노출되지 않음)
- 인증/토큰 처리 (서버에 인증 미들웨어 없음)
- `MeetingRepository` 전체 교체

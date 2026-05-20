# 모이자 — 모임 상세 화면 설계

작성일: 2026-05-21
대상: 모임 카드 탭 → 모임 상세 화면(정보 + 참가자 프로필)

## 목표

모임 리스트에서 카드를 누르면 상세 화면으로 이동한다. 모임 정보(제목·카테고리·설명·가격·장소·일시·인원·모집상태)와
참가자 프로필 목록(이니셜 아바타·닉네임·년생·성별·매너 별점·활동 횟수·나와 만난 횟수·자기소개)을 보여주고,
하단에 "참가 신청하기" CTA와 "수락 시 50 다이아 사용" 캡션을 둔다.

## 1. 가격 모델 (`lib/models/meeting_cost.dart`)

- `enum CostType { split('엔빵'), hostPays('호스트가 쏨'), free('무료'), paid('유료') }` (각 label 보유).
- `class MeetingCost { final CostType type; final int? amountWon; }`
  - `String get display`: paid → "10,000원"(천단위 콤마), 그 외 → `type.label`.

## 2. 모임 모델 확장 (`lib/models/meeting.dart`)

- 선택 필드 + 기본값 추가(기존 생성자 호환 → 직접 생성하는 테스트 안 깨짐):
  - `String description` (기본 '')
  - `String nearestStation` (기본 '')
  - `MeetingCost cost` (기본 `MeetingCost(CostType.split)`)
- `bool get isFull => spotsLeft <= 0;`

## 3. 저장소: 상세 필드 생성 + 참가자 (`lib/data/meeting_repository.dart`)

- `_m` 헬퍼가 description/nearestStation/cost를 **중앙에서 생성**:
  - `description`: 템플릿, 예 "{region}에서 즐기는 {category.label} 모임이에요. 편하게 신청하세요!"
  - `nearestStation`: "{region} 인근".
  - `cost`: 카테고리 규칙 — 등산·수영 → 무료, 카페·노래방 → 엔빵, 술 한잔·보드게임·롤·방탈출·볼링 → 엔빵, 기타 → 호스트가 쏨. (단순 규칙; 1~2개는 유료 예시로 금액 부여)
- 멤버 풀(8명 고정) + `List<Member> participantsOf(Meeting m)`:
  - `n = min(m.currentMembers, pool.length)`. id 해시 기반 오프셋에서 순환으로 `n`명 반환. **첫 번째 = 호스트**.
  - 결정적(같은 모임이면 같은 결과).

## 4. 참가자 모델 (`lib/models/member.dart`)

- `enum Gender { male('남'), female('여') }`.
- `class Member { String nickname; int birthYear; Gender gender; double mannerScore; int totalActivities; int timesMetWithMe; String intro; }`
- 표시 규칙: 아바타 = 닉네임 첫 글자(색 원), "{birthYear}년생 · {gender.label}", 매너 "★{mannerScore}", "활동 {totalActivities}회 · 나와 {timesMetWithMe}번 만남", 자기소개.

## 5. 화면 (`lib/features/meeting/meeting_detail_screen.dart`, `widgets/participant_card.dart`)

- 앱바: 뒤로 + 우측 공유·신고 아이콘(표시용, no-op).
- 본문 스크롤:
  - 카테고리 칩 + 모집 상태 배지(모집중 / 마감=`isFull`).
  - 제목(큰 글씨).
  - 정보 행(아이콘+텍스트): 일시(`y년 M월 d일 (E) HH:mm`), 장소(가까운 역 + location), 가격(`cost.display`), 인원("{cur}/{max}명 · {spotsLeft>0?'N자리 남음':'마감'}").
  - 설명 문단.
  - 구분선 → "참가자 {n}명" 헤더.
  - `ParticipantCard` 목록(첫 번째 HOST 배지).
- 하단 고정(SafeArea): `[참가 신청하기]`(꽉 찬 버튼) + 그 아래/옆 작게 "수락 시 50 다이아 사용"(다이아 아이콘). 신청 로직은 no-op.

## 6. 내비게이션

- `MeetingCard`에 `VoidCallback? onTap` 추가.
- `DayMeetingsPager`가 카드에 `onTap: () => Navigator.push(MeetingDetailScreen(meeting: m, repository: widget.repository))` 연결.

## 테스트

- `meeting_cost_test`: display(유료 금액 콤마·엔빵·무료·호스트).
- `meeting_repository_test`(추가): `participantsOf` 길이=currentMembers(풀 한도), 결정적, 첫 번째 호스트 취급(반환 리스트 0번).
- `meeting_detail_screen_test`: 제목·가격·인원·참가자(닉네임/매너/만남) 렌더, "참가 신청하기"·"수락 시 50 다이아 사용" 표시; 마감 모임 "마감" 배지.
- `day_meetings_pager_test`(추가): 카드 탭 → `MeetingDetailScreen` 표시.

## 범위 밖 (유지)
- 실제 참여/수락·다이아 차감, 채팅, 공유/신고 동작, 호스트가 아닌 "나"의 프로필, 백엔드.

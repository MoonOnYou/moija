# 모임 만들기 화면 설계

작성일: 2026-05-21

## 목표

홈 화면 우하단 FAB로 진입하는 "모임 만들기" 화면을 구현한다. 사용자가 카테고리·제목·일시·장소·인원·비용·설명·참가방식을 입력해 새 모임을 생성하면, 인메모리 저장소에 추가되어 홈 달력/목록에 즉시 반영된다. 생성 시 다이아 300개가 차감되며, 잔액이 부족하면 충전 화면으로 유도한다.

참고 이미지: `docs/page/03_참가방식.png` (참가 방식 카드 디자인)

## 데이터 모델

### 새 모델: `JoinMethod` — `lib/models/join_method.dart`

참가 방식 enum. 라벨·요약·불릿 설명을 함께 보유한다.

```dart
enum JoinMethod {
  approval('승인제', '신청을 받고 멤버를 골라 수락해요',
      ['누가 오는지 보고 결정', '신청자는 수락될 때만 다이아 차감']),
  firstCome('선착순', '자리가 있으면 바로 확정돼요',
      ['빠르게 모으고 싶을 때', '신청 즉시 확정 + 다이아 차감']);

  const JoinMethod(this.label, this.summary, this.bullets);
  final String label;
  final String summary;
  final List<String> bullets;
}
```

`approval`이 기본/추천. UI에서 `approval`에 "추천" 뱃지를 단다.

### `Meeting` 모델 변경 — `lib/models/meeting.dart`

`joinMethod` 필드 추가. 기본값 `JoinMethod.approval`로 두어 기존 시드/테스트는 영향받지 않는다.

```dart
final JoinMethod joinMethod;
// 생성자: this.joinMethod = JoinMethod.approval,
```

### 온라인 모임 표현

온라인 토글이 켜진 모임은 다음 값으로 저장한다:

- `region = '온라인'`
- `locationId = 'online'`
- `nearestStation = '온라인'`
- `location` = 입력한 구체 장소 텍스트, 비어 있으면 `'온라인'`

위치 필터(`MeetingFilter`)에는 `online`이라는 노드가 없으므로 매칭되지 않는다. 목업 단계에서 허용한다.

## 저장소 가변화 — `lib/data/meeting_repository.dart`

현재 `allMeetings`는 정적 `_seed`를 그대로 반환한다. 생성된 모임을 추가할 수 있도록 인스턴스 가변 구조로 리팩터링한다:

- 생성자에서 인스턴스 리스트 `_all = [..._seed]`을 만들고, `_byDay`를 `_all` 기준으로 구성
- `allMeetings`는 `_all`을 unmodifiable로 반환
- 새 메서드 `void add(Meeting m)`: `_all`에 추가하고 `_byDay[_key(m.startTime)]`에도 반영
- 기존 `_seed`(static)는 초기 데이터로 유지, 변경하지 않음

생성 id는 화면 측에서 `'u${DateTime.now().millisecondsSinceEpoch}'` 형태로 만든다.

## 화면 구성 — `CreateMeetingScreen` (StatefulWidget)

`lib/features/meeting/create_meeting_screen.dart`

`Scaffold` + `AppBar(title: '모임 만들기')` + `ListView` 본문 + `bottomNavigationBar`(안내문 + 버튼). 기존 화면들의 `AppColors`·버튼 스타일을 따른다.

### 생성자

```dart
CreateMeetingScreen({
  required MeetingRepository repository,
  int currentDiamonds = Wallet.myDiamonds,
});
```

### 상태 필드

| 상태 | 타입 | 기본값 |
|------|------|--------|
| 카테고리 | `MeetingCategory?` | null (미선택) |
| 제목 | `TextEditingController` | 빈 값 |
| 날짜 | `DateTime?` | null |
| 시간 | `TimeOfDay?` | null |
| 온라인 | `bool` | false |
| 지역 노드 id | `String?` | null |
| 구체 장소 | `TextEditingController` | 빈 값 (선택) |
| 인원(방장 포함) | `int` | 4 (최소 2) |
| 비용 유형 | `CostType?` | null (미선택) |
| 유료 금액 | `TextEditingController` | 빈 값 |
| 설명 | `TextEditingController` | 빈 값 (선택) |
| 참가 방식 | `JoinMethod` | `JoinMethod.approval` |

### 섹션 (ListView 순서)

| # | 섹션 | UI |
|---|------|-----|
| 1 | 카테고리 | 칩 그리드 (`filter_screen` 스타일, 단일 선택). `MeetingCategory.values` |
| 2 | 제목 | 단일행 TextField |
| 3 | 일시 | 날짜 선택(`showDatePicker`) + 시간 선택(`showTimePicker`), `ko_KR` 포맷으로 표시 |
| 4 | 장소 | 온라인 토글 + 지역 선택(단일 선택 picker, 선택 라벨 표시) + 구체 장소 텍스트. 온라인 ON 시 지역/장소 입력 비활성화 |
| 5 | 인원 | 스테퍼(− / 숫자 / +), 방장 포함 최소 2명 |
| 6 | 비용 | 더치페이 / 방장이 쏨 / 무료 / 유료(1인당) 단일 선택. 유료 선택 시 금액 입력 필드 노출 |
| 7 | 설명 | 멀티라인 TextField (선택) |
| 8 | 참가방식 | `03_참가방식.png` 형태의 선택 카드 2개 (승인제 `추천` / 선착순, 불릿 설명 포함). 선택된 카드는 테두리 강조 + 라디오 채움 |

### 지역 단일 선택

기존 `LocationPickerScreen`에 `singleSelect` 옵션(기본 false)을 추가한다:

- `singleSelect == true`이면 리프 노드 탭 시 즉시 `Navigator.pop(context, {id})` (체크박스 대신 일반 ListTile, 상단 선택 칩·하단 "완료" 버튼 숨김)
- 호출 측은 반환된 Set의 first를 사용
- 드릴다운(시/도 → 노드)과 `LocationCatalog` API를 그대로 재사용

기존 다중 선택(필터) 동작은 변경 없음.

## 하단 영역 & 동작

- 안내문: **"방이 생성되면 다이아 300개가 차감돼요"** (작은 보조 텍스트)
- 버튼 **모임 만들기**:
  - 필수 항목(카테고리·제목·일시(날짜+시간)·장소(지역 선택 또는 온라인)·인원·비용·참가방식)이 모두 채워질 때까지 **비활성화**(회색)
  - 비용이 유료일 경우 금액도 입력돼야 활성화
  - 설명·구체 장소는 선택이므로 비어도 활성화 가능
- 탭 시:
  - `currentDiamonds < 300` → '다이아가 부족해요' 스낵바 + `DiamondRechargeScreen(currentDiamonds: ...)`로 push (참가 흐름과 동일 패턴)
  - 충분 → `Meeting` 생성(`currentMembers = 1`(방장), `maxMembers =` 입력 인원) → `repository.add(meeting)` → '모임이 생성됐어요' 스낵바 → `Navigator.pop(context, meeting)`

### 홈 화면 연결 — `lib/features/home/home_screen.dart`

FAB의 `onPressed: () {}`를 다음으로 교체:

```dart
onPressed: () async {
  final created = await Navigator.push<Meeting>(
    context,
    MaterialPageRoute(
      builder: (_) => CreateMeetingScreen(repository: _repository),
    ),
  );
  if (created != null && mounted) {
    _goToDay(created.startTime); // 생성된 모임 날짜로 이동
    setState(() {});
  }
}
```

## 테스트 (TDD)

- `JoinMethod`: 라벨·요약·불릿 값 검증
- `Meeting`: `joinMethod` 기본값 = `JoinMethod.approval`
- `MeetingRepository.add`: 추가 후 `meetingsOn(해당일)`와 `allMeetings`에 반영되는지
- `CreateMeetingScreen` 위젯 테스트:
  - 초기 상태에서 '모임 만들기' 버튼 비활성
  - 필수 항목을 모두 채우면 버튼 활성
  - 잔액 충분 시 탭하면 저장소에 추가되고 pop
  - 잔액 부족 시 탭하면 충전 화면으로 이동
  - 온라인 토글 ON 시 지역 선택이 비활성/숨김

## 범위 밖 (YAGNI)

- 실제 다이아 차감 로직(Wallet는 const 목, 차감 시뮬레이션은 안내·게이트로 충분)
- 이미지 업로드, 임시저장(draft), 모임 수정/삭제
- 온라인 모임의 위치 필터 매칭
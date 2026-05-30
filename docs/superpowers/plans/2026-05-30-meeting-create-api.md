# 모임 생성 API 연동 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `POST /api/meetings/` 를 호출하도록 모임 생성 플로우를 교체하고, 인메모리 `repository.add()` 호출을 제거한다.

**Architecture:** 새 파일 `lib/data/api/meeting_api.dart` 에 `createMeeting(Meeting, {http.Client?})` 함수를 두고 `CreateMeetingScreen._submit()` 에서 호출한다. `repository` 파라미터는 더 이상 필요 없으므로 화면 생성자에서 제거한다. 테스트 격리는 `@visibleForTesting onCreateMeeting` 콜백으로 처리한다.

**Tech Stack:** Flutter, `http: ^1.2.0`, `package:http/testing.dart` (MockClient)

---

## 파일 맵

| 작업 | 파일 |
|---|---|
| 생성 | `lib/data/api/meeting_api.dart` |
| 생성 | `test/meeting_api_test.dart` |
| 수정 | `pubspec.yaml` |
| 수정 | `lib/features/meeting/create_meeting_screen.dart` |
| 수정 | `lib/features/home/home_screen.dart` |
| 수정 | `test/create_meeting_screen_test.dart` |

---

## Task 1: http 패키지 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml에 http 추가**

`dependencies:` 블록에 아래 줄을 추가한다 (기존 `connectivity_plus` 아래):

```yaml
  http: ^1.2.0
```

- [ ] **Step 2: 패키지 설치**

```bash
flutter pub get
```

Expected: `Downloading http 1.x.x...` 포함 출력, 오류 없음

- [ ] **Step 3: 커밋**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: http 패키지 추가"
```

---

## Task 2: meeting_api.dart 작성 (TDD)

**Files:**
- Create: `lib/data/api/meeting_api.dart`
- Create: `test/meeting_api_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/meeting_api_test.dart` 를 아래 내용으로 생성한다:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moija/data/api/meeting_api.dart';
import 'package:moija/models/join_method.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_cost.dart';

Meeting _m() => Meeting(
      id: 'local-id',
      title: '카페 모임',
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 6, 1, 14, 0),
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
      description: '테스트 모임',
      nearestStation: '강남역',
      cost: const MeetingCost(CostType.split),
      joinMethod: JoinMethod.approval,
    );

void main() {
  test('2xx 응답: 예외 없이 반환', () async {
    final client = MockClient((_) async => http.Response('{}', 201));
    await expectLater(createMeeting(_m(), client: client), completes);
  });

  test('올바른 JSON 페이로드 전송', () async {
    late Map<String, dynamic> body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    });
    await createMeeting(_m(), client: client);

    expect(body['title'], '카페 모임');
    expect(body['category'], 'cafe');
    expect(body['custom_category'], '');
    expect(body['max_members'], 4);
    expect(body['cost_type'], 'split');
    expect(body['join_method'], 'approval');
    expect(body['location_id'], 'seoul-line2');
    expect(body['nearest_station'], '강남역');
    expect(body.containsKey('cost_amount_won'), isFalse);
  });

  test('paid 비용이면 cost_amount_won 포함', () async {
    late Map<String, dynamic> body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    });
    final m = Meeting(
      id: 'x',
      title: '유료',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 6, 1, 20, 0),
      location: '강남',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
      cost: const MeetingCost(CostType.paid, amountWon: 22000),
      joinMethod: JoinMethod.approval,
    );
    await createMeeting(m, client: client);
    expect(body['cost_amount_won'], 22000);
  });

  test('4xx 응답: Exception throw', () {
    final client = MockClient((_) async => http.Response('{"error":"bad"}', 400));
    expect(createMeeting(_m(), client: client), throwsException);
  });

  test('5xx 응답: Exception throw', () {
    final client = MockClient((_) async => http.Response('error', 500));
    expect(createMeeting(_m(), client: client), throwsException);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/meeting_api_test.dart
```

Expected: `Error: Could not find package 'moija/data/api/meeting_api.dart'` 또는 import 오류

- [ ] **Step 3: meeting_api.dart 구현**

`lib/data/api/meeting_api.dart` 를 아래 내용으로 생성한다:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meeting.dart';

const _baseUrl = 'http://localhost:8000';

Future<void> createMeeting(Meeting m, {@visibleForTesting http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final body = <String, dynamic>{
      'title': m.title,
      'category': m.category.name,
      'custom_category': m.customCategory,
      'start_time': m.startTime.toIso8601String(),
      'location': m.location,
      'region': m.region,
      'location_id': m.locationId,
      'max_members': m.maxMembers,
      'description': m.description,
      'nearest_station': m.nearestStation,
      'join_method': m.joinMethod.name,
      'cost_type': m.cost.type.name,
      if (m.cost.amountWon != null) 'cost_amount_won': m.cost.amountWon,
      'cost_custom_text': m.cost.customText ?? '',
    };
    final response = await c.post(
      Uri.parse('$_baseUrl/api/meetings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  } finally {
    if (client == null) c.close();
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/meeting_api_test.dart
```

Expected: `All tests passed!` (5개 통과)

- [ ] **Step 5: 커밋**

```bash
git add lib/data/api/meeting_api.dart test/meeting_api_test.dart
git commit -m "feat: 모임 생성 API 함수 추가 (meeting_api.dart)"
```

---

## Task 3: CreateMeetingScreen 수정

**Files:**
- Modify: `lib/features/meeting/create_meeting_screen.dart`

- [ ] **Step 1: import 교체 및 생성자 변경**

파일 상단 `import '../../data/meeting_repository.dart';` 줄을 삭제하고,
`import '../../data/wallet.dart';` 바로 위에 아래 줄을 추가한다:

```dart
import '../../data/api/meeting_api.dart';
```

생성자를 아래로 교체한다 (`required this.repository` 제거, `onCreateMeeting` 추가):

```dart
class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({
    super.key,
    this.currentDiamonds = Wallet.myDiamonds,
    @visibleForTesting this.onCreateMeeting,
  });

  final int currentDiamonds;
  @visibleForTesting
  final Future<void> Function(Meeting)? onCreateMeeting;

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}
```

- [ ] **Step 2: _loading 상태 추가**

`_CreateMeetingScreenState` 에 `_joinMethod` 선언 바로 아래에 추가한다:

```dart
  bool _loading = false;
```

- [ ] **Step 3: _submit() 교체**

기존 `_submit()` 메서드 전체를 아래로 교체한다:

```dart
  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (widget.currentDiamonds < _createCost) {
      messenger.showSnackBar(const SnackBar(content: Text('다이아가 부족해요')));
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              DiamondRechargeScreen(currentDiamonds: widget.currentDiamonds),
        ),
      );
      return;
    }
    final agreed = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => Notices.createMeeting()),
    );
    if (agreed != true || !mounted) return;
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final placeText = _place.text.trim();
    final locLabel =
        _online ? '' : LocationCatalog.displayLabel(_locationId!);
    final regionName =
        _online ? '온라인' : LocationCatalog.regionOf(_locationId!);
    final meeting = Meeting(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category!,
      customCategory: _customCategory ?? '',
      customIcon: (_customCategory != null && _customCategory!.isNotEmpty)
          ? CategoryCatalog.iconForLabel(_customCategory!)
          : null,
      startTime: start,
      location: _online
          ? (placeText.isEmpty ? '온라인' : placeText)
          : (placeText.isEmpty ? locLabel : placeText),
      region: _online
          ? '온라인'
          : (placeText.isNotEmpty ? placeText : regionName),
      locationId: _online ? 'online' : _locationId!,
      currentMembers: 1,
      maxMembers: _members,
      description: _description.text.trim(),
      nearestStation: _online ? '온라인' : locLabel,
      cost: _buildCost(),
      joinMethod: _joinMethod,
    );
    setState(() => _loading = true);
    try {
      await (widget.onCreateMeeting ?? createMeeting)(meeting);
      if (!mounted) return;
      pendingFocusDay.value = start;
      selectedTab.value = 1;
      navigator.popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(content: Text('모임이 생성됐어요')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(const SnackBar(content: Text('모임 생성에 실패했어요')));
    }
  }
```

- [ ] **Step 4: 버튼 UI 수정**

`bottomNavigationBar` 안의 `ElevatedButton` 을 아래로 교체한다:

```dart
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.bgPrimary,
                    disabledBackgroundColor: AppColors.bgTertiary,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (_valid && !_loading) ? _submit : null,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bgPrimary,
                          ),
                        )
                      : const Text('모임 만들기',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
```

- [ ] **Step 5: 정적 분석 확인**

```bash
flutter analyze lib/features/meeting/create_meeting_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 6: 커밋**

```bash
git add lib/features/meeting/create_meeting_screen.dart
git commit -m "feat: CreateMeetingScreen을 API 연동으로 교체"
```

---

## Task 4: home_screen.dart 호출부 정리

**Files:**
- Modify: `lib/features/home/home_screen.dart`

- [ ] **Step 1: FAB onPressed 단순화**

`floatingActionButton` 의 `onPressed` 콜백을 아래로 교체한다 (await·created 관련 코드 제거):

```dart
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.bgPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateMeetingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
```

- [ ] **Step 2: 정적 분석 확인**

```bash
flutter analyze lib/features/home/home_screen.dart
```

Expected: `No issues found!` (unused `_repository` 경고가 있다면 해당 변수도 정리한다)

- [ ] **Step 3: 커밋**

```bash
git add lib/features/home/home_screen.dart
git commit -m "refactor: CreateMeetingScreen 호출부 단순화"
```

---

## Task 5: 기존 테스트 수정

**Files:**
- Modify: `test/create_meeting_screen_test.dart`

- [ ] **Step 1: import에서 meeting_repository 제거**

파일 상단에서 아래 줄을 삭제한다:

```dart
import 'package:moija/data/meeting_repository.dart';
```

- [ ] **Step 2: 생성자에서 repository 제거**

파일 전체에서 `repository: repo` 인수를 모두 제거한다. `MeetingRepository()` 인스턴스 생성도 모두 삭제한다.

> 검색: `final repo = MeetingRepository();` → 삭제  
> 검색: `repository: repo,` → 삭제

- [ ] **Step 3: "잔액 충분" 테스트 수정**

기존 `'잔액 충분: 저장소에 추가되고 pop'` 테스트를 아래로 교체한다:

```dart
  testWidgets('잔액 충분: API 호출 후 화면 닫히고 채팅 탭 이동', (tester) async {
    Meeting? captured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateMeetingScreen(
                    currentDiamonds: 1000,
                    onCreateMeeting: (m) async => captured = m,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateMeetingScreen), findsNothing);
    expect(captured, isNotNull);
    expect(captured!.title, '주말 카페 모임');
    expect(selectedTab.value, 1);
  });
```

- [ ] **Step 4: customCategory 테스트 수정**

`'전체보기에서 enum에 없는 라벨 선택 → customCategory로 저장된다'` 테스트에서:

1. `final repo = MeetingRepository();` 삭제
2. `Meeting? captured;` 추가
3. `CreateMeetingScreen(repository: repo, currentDiamonds: 1000)` →  
   `CreateMeetingScreen(currentDiamonds: 1000, onCreateMeeting: (m) async => captured = m)`
4. 어설션 교체:
   - `expect(repo.allMeetings.last.customCategory, '배드민턴');` →  
     `expect(captured!.customCategory, '배드민턴');`
   - `expect(repo.allMeetings.last.categoryLabel, '배드민턴');` →  
     `expect(captured!.categoryLabel, '배드민턴');`

- [ ] **Step 5: 인원 테스트 수정**

`'인원: 직접 입력 가능하고 99 초과는 99로 잘린다'` 테스트에서:

1. `final repo = MeetingRepository();` 삭제
2. `Meeting? captured;` 추가
3. `CreateMeetingScreen(repository: repo, currentDiamonds: 1000)` →  
   `CreateMeetingScreen(currentDiamonds: 1000, onCreateMeeting: (m) async => captured = m)`
4. `expect(repo.allMeetings.last.maxMembers, 8);` →  
   `expect(captured!.maxMembers, 8);`

- [ ] **Step 6: 비용 테스트 수정**

`'비용: 기타 선택 후 직접 입력값이 저장된다'` 테스트에서:

1. `final repo = MeetingRepository();` 삭제
2. `Meeting? captured;` 추가
3. `CreateMeetingScreen(repository: repo, currentDiamonds: 1000)` →  
   `CreateMeetingScreen(currentDiamonds: 1000, onCreateMeeting: (m) async => captured = m)`
4. `expect(repo.allMeetings.last.cost.display, '연구실에서 갹출');` →  
   `expect(captured!.cost.display, '연구실에서 갹출');`

- [ ] **Step 7: API 실패 경로 테스트 추가**

`'잔액 부족: 충전 화면으로 이동'` 테스트 **아래에** 아래 테스트를 추가한다:

```dart
  testWidgets('API 실패: 오류 스낵바, 화면 유지', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateMeetingScreen(
                    currentDiamonds: 1000,
                    onCreateMeeting: (_) async => throw Exception('network error'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateMeetingScreen), findsOneWidget);
    expect(find.text('모임 생성에 실패했어요'), findsOneWidget);
  });
```

- [ ] **Step 8: 전체 테스트 실행**

```bash
flutter test test/create_meeting_screen_test.dart test/meeting_api_test.dart
```

Expected: 모든 테스트 통과

- [ ] **Step 9: 전체 테스트 suite 확인**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 10: 커밋**

```bash
git add test/create_meeting_screen_test.dart
git commit -m "test: 모임 생성 테스트를 API 연동 방식으로 업데이트"
```

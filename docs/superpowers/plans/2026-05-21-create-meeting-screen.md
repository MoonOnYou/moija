# 모임 만들기 화면 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 FAB로 진입하는 "모임 만들기" 화면을 구현해, 입력한 모임을 인메모리 저장소에 추가하고(300다이아 차감 게이트 포함) 홈 달력에 반영한다.

**Architecture:** 새 `JoinMethod` enum을 추가하고 `Meeting`에 `joinMethod` 필드(기본값)를 단다. `MeetingRepository`를 가변 구조로 바꿔 `add()`를 제공한다. 기존 `LocationPickerScreen`에 단일 선택 모드를 추가해 재사용한다. `CreateMeetingScreen`(StatefulWidget)이 모든 입력·검증·제출을 담당하고, 잔액 부족 시 기존 `DiamondRechargeScreen`으로 보낸다.

**Tech Stack:** Flutter (Material 3), Dart, intl(DateFormat ko_KR), flutter_test 위젯 테스트.

---

## File Structure

- Create: `lib/models/join_method.dart` — 참가 방식 enum (라벨/요약/불릿)
- Modify: `lib/models/meeting.dart` — `joinMethod` 필드 추가
- Modify: `lib/data/meeting_repository.dart` — 가변화 + `add()`
- Modify: `lib/features/filter/location_picker_screen.dart` — `singleSelect` 모드
- Create: `lib/features/meeting/create_meeting_screen.dart` — 모임 만들기 화면
- Modify: `lib/features/home/home_screen.dart` — FAB → 화면 연결
- Create/Modify tests: `test/join_method_test.dart`, `test/meeting_test.dart`, `test/meeting_repository_test.dart`, `test/location_picker_screen_test.dart`, `test/create_meeting_screen_test.dart`, `test/home_screen_test.dart`

---

## Task 1: JoinMethod 모델

**Files:**
- Create: `lib/models/join_method.dart`
- Test: `test/join_method_test.dart`

- [ ] **Step 1: Write the failing test**

`test/join_method_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/join_method.dart';

void main() {
  test('승인제/선착순 라벨·요약·불릿', () {
    expect(JoinMethod.approval.label, '승인제');
    expect(JoinMethod.approval.summary, '신청을 받고 멤버를 골라 수락해요');
    expect(JoinMethod.approval.bullets, [
      '누가 오는지 보고 결정',
      '신청자는 수락될 때만 다이아 차감',
    ]);
    expect(JoinMethod.firstCome.label, '선착순');
    expect(JoinMethod.firstCome.summary, '자리가 있으면 바로 확정돼요');
    expect(JoinMethod.firstCome.bullets, [
      '빠르게 모으고 싶을 때',
      '신청 즉시 확정 + 다이아 차감',
    ]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/join_method_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moija/models/join_method.dart'`

- [ ] **Step 3: Write minimal implementation**

`lib/models/join_method.dart`:
```dart
/// 모임 참가 방식. (docs/page/03_참가방식.png)
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

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/join_method_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/models/join_method.dart test/join_method_test.dart
git commit -m "feat: JoinMethod 모델 (승인제/선착순)"
```

---

## Task 2: Meeting에 joinMethod 필드 추가

**Files:**
- Modify: `lib/models/meeting.dart`
- Test: `test/meeting_test.dart`

- [ ] **Step 1: Write the failing test**

`test/meeting_test.dart`의 `import` 블록에 다음 줄을 추가:
```dart
import 'package:moija/models/join_method.dart';
```

그리고 `void main() {` 안의 기존 test 아래에 새 test를 추가:
```dart
  test('joinMethod 기본값은 승인제', () {
    final m = Meeting(
      id: '1',
      title: 't',
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: 'x',
      region: 'x',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    );
    expect(m.joinMethod, JoinMethod.approval);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/meeting_test.dart`
Expected: FAIL — `The getter 'joinMethod' isn't defined for the type 'Meeting'`

- [ ] **Step 3: Write minimal implementation**

`lib/models/meeting.dart` 상단 import에 추가:
```dart
import 'join_method.dart';
```

생성자에서 `this.cost = const MeetingCost(CostType.split),` 바로 아래에 추가:
```dart
    this.joinMethod = JoinMethod.approval,
```

필드 선언부에서 `final MeetingCost cost;` 아래에 추가:
```dart
  final JoinMethod joinMethod;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/meeting_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/models/meeting.dart test/meeting_test.dart
git commit -m "feat: Meeting.joinMethod 필드 (기본 승인제)"
```

---

## Task 3: MeetingRepository.add (가변화)

**Files:**
- Modify: `lib/data/meeting_repository.dart`
- Test: `test/meeting_repository_test.dart`

- [ ] **Step 1: Write the failing test**

`test/meeting_repository_test.dart`의 `void main() {` 안, 마지막 test 아래에 추가:
```dart
  test('add 한 모임이 meetingsOn / allMeetings 에 반영된다', () {
    final r = MeetingRepository();
    final before = r.meetingsOn(DateTime(2026, 7, 1)).length;
    r.add(Meeting(
      id: 'new-1',
      title: '새 모임',
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 7, 1, 18, 0),
      location: '강남역',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    ));
    expect(r.meetingsOn(DateTime(2026, 7, 1)).length, before + 1);
    expect(r.allMeetings.any((m) => m.id == 'new-1'), isTrue);
  });
```

파일 상단 import에 다음 두 줄이 없으면 추가:
```dart
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/meeting_repository_test.dart`
Expected: FAIL — `The method 'add' isn't defined for the type 'MeetingRepository'`

- [ ] **Step 3: Write minimal implementation**

`lib/data/meeting_repository.dart`의 생성자와 필드를 다음으로 교체.

기존:
```dart
  MeetingRepository() {
    _byDay = {};
    for (final m in _seed) {
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
  }

  late final Map<DateTime, List<Meeting>> _byDay;

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Meeting> get allMeetings => List.unmodifiable(_seed);
```

교체 후:
```dart
  MeetingRepository() {
    _all = [..._seed];
    _byDay = {};
    for (final m in _all) {
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
  }

  late final List<Meeting> _all;
  late final Map<DateTime, List<Meeting>> _byDay;

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Meeting> get allMeetings => List.unmodifiable(_all);

  /// 새 모임을 추가하고 날짜 인덱스에 반영한다.
  void add(Meeting m) {
    _all.add(m);
    _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/meeting_repository_test.dart`
Expected: PASS (기존 테스트 포함 전부 통과)

- [ ] **Step 5: Commit**

```bash
git add lib/data/meeting_repository.dart test/meeting_repository_test.dart
git commit -m "feat: MeetingRepository.add 가변 저장소"
```

---

## Task 4: LocationPickerScreen 단일 선택 모드

**Files:**
- Modify: `lib/features/filter/location_picker_screen.dart`
- Test: `test/location_picker_screen_test.dart`

- [ ] **Step 1: Write the failing test**

`test/location_picker_screen_test.dart`의 `void main() {` 안 마지막에 추가:
```dart
  testWidgets('singleSelect: 리프 탭 시 즉시 단일 id로 pop', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(
                        initial: {}, singleSelect: true),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    expect(find.text('완료'), findsNothing); // 단일 모드엔 완료 버튼 없음
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();

    expect(result, {'seoul-line2'});
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: FAIL — `No named parameter with the name 'singleSelect'`

- [ ] **Step 3: Write minimal implementation**

`lib/features/filter/location_picker_screen.dart` 수정.

생성자/필드:
```dart
  const LocationPickerScreen({
    super.key,
    required this.initial,
    this.singleSelect = false,
  });

  final Set<String> initial;
  final bool singleSelect;
```

`body`의 선택 칩 라인을 다음으로 교체 (기존: `if (_selected.isNotEmpty) _selectedChips(),`):
```dart
            if (!widget.singleSelect && _selected.isNotEmpty) _selectedChips(),
```

`bottomNavigationBar:` 전체를 다음으로 교체 (단일 모드에선 완료 버튼 숨김):
```dart
        bottomNavigationBar: widget.singleSelect
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.bgPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('완료'),
                    ),
                  ),
                ),
              ),
```

`_nodeList` 메서드를 다음으로 교체:
```dart
  Widget _nodeList(String region) {
    final nodes = LocationCatalog.nodesIn(region);
    return ListView(
      children: [
        for (final node in nodes)
          if (widget.singleSelect)
            ListTile(
              title: Text(node.label),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
              onTap: () => Navigator.pop(context, {node.id}),
            )
          else
            CheckboxListTile(
              value: _selected.contains(node.id),
              title: Text(node.label),
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => _toggle(node.id),
            ),
      ],
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/location_picker_screen_test.dart`
Expected: PASS (기존 다중 선택 테스트 4개 포함 전부 통과)

- [ ] **Step 5: Commit**

```bash
git add lib/features/filter/location_picker_screen.dart test/location_picker_screen_test.dart
git commit -m "feat: LocationPickerScreen 단일 선택 모드"
```

---

## Task 5: CreateMeetingScreen 화면 + 검증

**Files:**
- Create: `lib/features/meeting/create_meeting_screen.dart`
- Test: `test/create_meeting_screen_test.dart`

- [ ] **Step 1: Write the screen**

`lib/features/meeting/create_meeting_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/location_catalog.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import '../../models/meeting_category.dart';
import '../../models/meeting_cost.dart';
import '../../theme/app_colors.dart';
import '../filter/location_picker_screen.dart';
import 'diamond_recharge_screen.dart';

const int _createCost = 300;
final DateTime _today = DateTime(2026, 5, 16);

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({
    super.key,
    required this.repository,
    this.currentDiamonds = Wallet.myDiamonds,
  });

  final MeetingRepository repository;
  final int currentDiamonds;

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  MeetingCategory? _category;
  final _title = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _online = false;
  String? _locationId;
  final _place = TextEditingController();
  int _members = 4;
  CostType? _costType;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  JoinMethod _joinMethod = JoinMethod.approval;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    _amount.addListener(_refresh);
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _valid {
    if (_category == null) return false;
    if (_title.text.trim().isEmpty) return false;
    if (_date == null || _time == null) return false;
    if (!_online && _locationId == null) return false;
    if (_members < 2) return false;
    if (_costType == null) return false;
    if (_costType == CostType.paid &&
        (int.tryParse(_amount.text.trim()) ?? 0) <= 0) return false;
    return true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? _today,
      firstDate: _today,
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _locationId == null ? <String>{} : {_locationId!},
          singleSelect: true,
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _locationId = result.first);
    }
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.currentDiamonds < _createCost) {
      messenger.showSnackBar(const SnackBar(content: Text('다이아가 부족해요')));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DiamondRechargeScreen(currentDiamonds: widget.currentDiamonds),
        ),
      );
      return;
    }
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final node = _online ? null : LocationCatalog.nodeById(_locationId!);
    final placeText = _place.text.trim();
    final region = _online
        ? '온라인'
        : (placeText.isNotEmpty ? placeText : (node?.label ?? ''));
    final meeting = Meeting(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category!,
      startTime: start,
      location: _online
          ? (placeText.isEmpty ? '온라인' : placeText)
          : (placeText.isEmpty ? (node?.label ?? '') : placeText),
      region: region,
      locationId: _online ? 'online' : _locationId!,
      currentMembers: 1,
      maxMembers: _members,
      description: _description.text.trim(),
      nearestStation: _online ? '온라인' : (node?.label ?? ''),
      cost: _costType == CostType.paid
          ? MeetingCost(CostType.paid,
              amountWon: int.tryParse(_amount.text.trim()))
          : MeetingCost(_costType!),
      joinMethod: _joinMethod,
    );
    widget.repository.add(meeting);
    messenger.showSnackBar(const SnackBar(content: Text('모임이 생성됐어요')));
    Navigator.pop(context, meeting);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? '날짜 선택'
        : DateFormat('y년 M월 d일 (E)', 'ko_KR').format(_date!);
    final timeLabel = _time == null ? '시간 선택' : _time!.format(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('모임 만들기'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('카테고리'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in MeetingCategory.values)
                _chip(c.label, _category == c,
                    () => setState(() => _category = c)),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('제목'),
          TextField(
            key: const Key('title'),
            controller: _title,
            decoration: _inputDeco('어떤 모임인가요?'),
          ),
          const SizedBox(height: 20),
          _sectionTitle('일시'),
          Row(
            children: [
              Expanded(
                child: _pickerField(const Key('date'), Icons.calendar_today,
                    dateLabel, _date != null, _pickDate),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerField(const Key('time'), Icons.schedule,
                    timeLabel, _time != null, _pickTime),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('장소'),
          SwitchListTile(
            key: const Key('online'),
            contentPadding: EdgeInsets.zero,
            title: const Text('온라인 모임', style: TextStyle(fontSize: 14)),
            value: _online,
            activeColor: AppColors.textInfo,
            onChanged: (v) => setState(() => _online = v),
          ),
          if (!_online) ...[
            const SizedBox(height: 4),
            _pickerField(
              const Key('location'),
              Icons.location_on_outlined,
              _locationId == null
                  ? '지역 선택'
                  : (LocationCatalog.nodeById(_locationId!)?.label ??
                      '지역 선택'),
              _locationId != null,
              _pickLocation,
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('place'),
              controller: _place,
              decoration: _inputDeco('구체적인 장소 (선택)'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('인원 (방장 포함)'),
          Row(
            children: [
              _stepBtn(const Key('members-minus'), Icons.remove,
                  _members > 2 ? () => setState(() => _members--) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_members명',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _stepBtn(const Key('members-plus'), Icons.add,
                  () => setState(() => _members++)),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('비용'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in CostType.values)
                _chip(t.label, _costType == t,
                    () => setState(() => _costType = t)),
            ],
          ),
          if (_costType == CostType.paid) ...[
            const SizedBox(height: 10),
            TextField(
              key: const Key('amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('1인당 금액 (원)'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('설명 (선택)'),
          TextField(
            key: const Key('description'),
            controller: _description,
            maxLines: 4,
            decoration: _inputDeco('모임을 소개해 주세요'),
          ),
          const SizedBox(height: 20),
          _sectionTitle('참가 방식'),
          for (final m in JoinMethod.values) ...[
            _joinCard(m),
            const SizedBox(height: 10),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('방이 생성되면 다이아 300개가 차감돼요',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bgPrimary,
                    disabledBackgroundColor: AppColors.bgTertiary,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _valid ? _submit : null,
                  child: const Text('모임 만들기',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderTertiary),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.textInfo : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          selected ? '$label ✓' : label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _pickerField(
      Key key, IconData icon, String label, bool filled, VoidCallback onTap) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderTertiary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: filled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(Key key, IconData icon, VoidCallback? onTap) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderTertiary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color:
                onTap == null ? AppColors.textTertiary : AppColors.textPrimary),
      ),
    );
  }

  Widget _joinCard(JoinMethod m) {
    final selected = _joinMethod == m;
    return GestureDetector(
      onTap: () => setState(() => _joinMethod = m),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border.all(
            color: selected ? AppColors.textInfo : AppColors.borderTertiary,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.textInfo : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      if (m == JoinMethod.approval) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgInfo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('추천',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textInfo)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(m.summary,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  for (final b in m.bullets)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('· $b',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write the validation test**

`test/create_meeting_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/create_meeting_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // 필수 항목을 모두 채운다(설명·구체장소 제외).
  Future<void> fillRequired(WidgetTester tester) async {
    await tester.tap(find.text('카페')); // 카테고리
    await tester.pump();
    await tester.enterText(find.byKey(const Key('title')), '주말 카페 모임');
    await tester.pump();

    await tester.tap(find.byKey(const Key('date'))); // 날짜 → OK
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('time'))); // 시간 → OK
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('location'))); // 지역(단일선택)
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('더치페이')); // 비용
    await tester.pump();
  }

  testWidgets('필수 미완성이면 버튼 비활성, 채우면 활성', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();

    ElevatedButton button() => tester.widget<ElevatedButton>(
        find.byKey(const Key('submit')));
    expect(button().onPressed, isNull); // 초기 비활성

    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    expect(button().onPressed, isNotNull); // 활성
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/create_meeting_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Run the analyzer**

Run: `flutter analyze lib/features/meeting/create_meeting_screen.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/features/meeting/create_meeting_screen.dart test/create_meeting_screen_test.dart
git commit -m "feat: 모임 만들기 화면 + 입력 검증"
```

---

## Task 6: 제출 동작 + 온라인 토글 테스트

**Files:**
- Test: `test/create_meeting_screen_test.dart` (Task 5에서 만든 파일에 추가)

> 제출/온라인 동작 구현은 Task 5의 화면 코드에 이미 포함되어 있다. 이 태스크는 그 동작을 검증하는 위젯 테스트를 추가한다.

- [ ] **Step 1: Add the behavior tests**

`test/create_meeting_screen_test.dart`의 `void main() {` 안, 검증 테스트 아래에 추가:
```dart
  testWidgets('잔액 충분: 저장소에 추가되고 pop', (tester) async {
    final repo = MeetingRepository();
    final before = repo.allMeetings.length;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateMeetingScreen(
                      repository: repo, currentDiamonds: 1000),
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

    expect(find.byType(CreateMeetingScreen), findsNothing); // pop됨
    expect(repo.allMeetings.length, before + 1);
    expect(repo.allMeetings.last.title, '주말 카페 모임');
  });

  testWidgets('잔액 부족: 충전 화면으로 이동', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 30),
    ));
    await tester.pumpAndSettle();
    await fillRequired(tester);
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('다이아가 부족해요'), findsOneWidget);
    expect(find.text('충전하기'), findsWidgets); // 충전 화면 진입
  });

  testWidgets('온라인 토글 ON 시 지역 선택이 사라진다', (tester) async {
    final repo = MeetingRepository();
    await tester.pumpWidget(MaterialApp(
      home: CreateMeetingScreen(repository: repo, currentDiamonds: 1000),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('location')), findsOneWidget);
    await tester.tap(find.byKey(const Key('online')));
    await tester.pump();
    expect(find.byKey(const Key('location')), findsNothing);
  });
```

> 참고: `fillRequired`는 Task 5에서 `main()` 안 최상단에 정의했으므로 그대로 재사용한다. `'충전하기'` 텍스트는 `DiamondRechargeScreen`의 결제 버튼 라벨이다 — Step 2에서 실제 라벨을 확인해 맞춘다.

- [ ] **Step 2: 충전 화면 버튼 라벨 확인**

Run: `grep -n "child: const Text" lib/features/meeting/diamond_recharge_screen.dart`
충전 CTA 버튼의 실제 텍스트를 확인하고, 위 `'충전하기'` 기대값을 그 라벨로 맞춘다. (라벨이 다르면 해당 문자열로 교체)

- [ ] **Step 3: Run tests to verify they pass**

Run: `flutter test test/create_meeting_screen_test.dart`
Expected: PASS (4개 테스트 전부)

- [ ] **Step 4: Commit**

```bash
git add test/create_meeting_screen_test.dart
git commit -m "test: 모임 만들기 제출/온라인 동작"
```

---

## Task 7: 홈 FAB 연결

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Test: `test/home_screen_test.dart`

- [ ] **Step 1: Write the failing test**

`test/home_screen_test.dart`의 `void main() {` 안 마지막에 추가:
```dart
  testWidgets('FAB 탭하면 모임 만들기 화면으로 이동', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('모임 만들기'), findsWidgets);
  });
```

> `home_screen_test.dart`에 `HomeScreen` import가 이미 있다고 가정한다. 없으면 `import 'package:moija/features/home/home_screen.dart';`를 추가한다.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — '모임 만들기' 텍스트를 찾지 못함 (FAB onPressed가 no-op)

- [ ] **Step 3: Wire the FAB**

`lib/features/home/home_screen.dart` 상단 import 블록에 추가:
```dart
import '../../models/meeting.dart';
import '../meeting/create_meeting_screen.dart';
```

FAB의 `onPressed: () {},`를 다음으로 교체:
```dart
        onPressed: () async {
          final created = await Navigator.push<Meeting>(
            context,
            MaterialPageRoute(
              builder: (_) => CreateMeetingScreen(repository: _repository),
            ),
          );
          if (created != null && mounted) {
            _goToDay(created.startTime);
            setState(() {});
          }
        },
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/home_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/home_screen.dart test/home_screen_test.dart
git commit -m "feat: 홈 FAB → 모임 만들기 화면 연결"
```

---

## Task 8: 전체 검증

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests passed!

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Fix any issues**

문제가 있으면 해당 태스크로 돌아가 수정하고 다시 `flutter test` / `flutter analyze`를 실행한다.

---

## Notes

- `_today`(2026-5-16)는 홈 화면의 기준일과 동일하게 두어, 생성된 모임 날짜가 항상 오늘 이후가 되도록 한다.
- 온라인 모임은 `locationId='online'`이라 위치 필터에 매칭되지 않는다(설계 범위 밖).
- 실제 다이아 차감은 시뮬레이션하지 않는다(`Wallet`은 const 목). 300다이아 게이트는 안내 + 충전 화면 유도로만 구현.
- 날짜/시간 피커 다이얼로그는 앱에 `flutter_localizations`가 없어 영어(`OK`/`CANCEL`)로 표시된다. 위젯 테스트는 `OK` 버튼을 탭한다.
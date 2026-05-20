# 다이아 충전 화면(목업) + 헤더 진입 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 충전 화면을 목업(08_다이아충전.html)대로 재구성하고, 홈 헤더 다이아 칩 탭으로 진입하게 한다.

**Architecture:** 충전 화면을 패키지 선택 상태를 가진 StatefulWidget으로 재작성. 헤더 다이아 칩에 onTap 콜백 추가, 홈이 push.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `intl`, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-21-recharge-screen-design.md`

---

## Task 1: 충전 화면 재구성 (`diamond_recharge_screen.dart`)

**Files:**
- Modify: `lib/features/meeting/diamond_recharge_screen.dart` (전체 교체)
- Test: `test/diamond_recharge_screen_test.dart` (신규)

- [ ] **Step 1: 실패 테스트 작성**

`test/diamond_recharge_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/meeting/diamond_recharge_screen.dart';

void main() {
  testWidgets('shows balance, packages, and default payment amount',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DiamondRechargeScreen(currentDiamonds: 30),
    ));

    expect(find.text('현재 보유'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('1,000 다이아'), findsOneWidget);
    expect(find.text('3,300 다이아'), findsOneWidget);
    expect(find.text('12,000 다이아'), findsOneWidget);
    expect(find.text('광고 보고 무료 충전'), findsOneWidget);
    expect(find.text('₩3,000 결제하기'), findsOneWidget); // 기본 인기 패키지
  });

  testWidgets('selecting another package updates the payment amount',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DiamondRechargeScreen(currentDiamonds: 30),
    ));

    await tester.tap(find.text('12,000 다이아'));
    await tester.pump();

    expect(find.text('₩10,000 결제하기'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/diamond_recharge_screen_test.dart`
Expected: FAIL — 기존 플레이스홀더와 불일치(패키지/결제 버튼 없음).

- [ ] **Step 3: 화면 전체 교체**

`lib/features/meeting/diamond_recharge_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class _Package {
  const _Package(this.diamonds, this.bonus, this.won, this.popular);
  final int diamonds;
  final String? bonus;
  final int won;
  final bool popular;
}

const _packages = <_Package>[
  _Package(1000, null, 1000, false),
  _Package(3300, '보너스 +300 (10%)', 3000, true),
  _Package(5750, '보너스 +750 (15%)', 5000, false),
  _Package(12000, '보너스 +2,000 (20%)', 10000, false),
];

/// 다이아 충전 화면. 실제 결제·광고는 범위 밖(no-op).
class DiamondRechargeScreen extends StatefulWidget {
  const DiamondRechargeScreen({super.key, required this.currentDiamonds});

  final int currentDiamonds;

  @override
  State<DiamondRechargeScreen> createState() => _DiamondRechargeScreenState();
}

class _DiamondRechargeScreenState extends State<DiamondRechargeScreen> {
  final NumberFormat _fmt = NumberFormat('#,###');
  late int _selected = _packages.indexWhere((p) => p.popular);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('다이아 충전'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _balanceCard(),
          const SizedBox(height: 24),
          const Text('충전 패키지',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          for (var i = 0; i < _packages.length; i++) _packageTile(i),
          const SizedBox(height: 24),
          _adCard(),
          const SizedBox(height: 24),
          _usageCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {},
              child: Text('₩${_fmt.format(_packages[_selected].won)} 결제하기',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgInfo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('현재 보유',
                style: TextStyle(fontSize: 12, color: AppColors.textInfo)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond, size: 28, color: AppColors.textInfo),
                const SizedBox(width: 8),
                Text(_fmt.format(widget.currentDiamonds),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textInfo)),
              ],
            ),
          ],
        ),
      );

  Widget _packageTile(int i) {
    final p = _packages[i];
    final selected = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.borderInfo : AppColors.borderTertiary,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                const Icon(Icons.diamond, size: 24, color: AppColors.textInfo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_fmt.format(p.diamonds)} 다이아',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      if (p.bonus != null) ...[
                        const SizedBox(height: 2),
                        Text(p.bonus!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSuccess)),
                      ],
                    ],
                  ),
                ),
                Text('₩${_fmt.format(p.won)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            if (p.popular)
              Positioned(
                top: -19,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgInfo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('인기',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textInfo)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _adCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgWarning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline,
                size: 22, color: AppColors.textWarning),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('광고 보고 무료 충전',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWarning)),
                  SizedBox(height: 2),
                  Text('15초 광고 시청 시 50 다이아',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textWarning, width: 0.5),
              ),
              child: const Text('받기',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textWarning)),
            ),
          ],
        ),
      );

  Widget _usageCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다이아는 어디에 쓰나요?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            _usageRow(Icons.add, '모임 만들기', '300 다이아'),
            const SizedBox(height: 8),
            _usageRow(Icons.chat_bubble_outline, '채팅방 참가', '50 다이아'),
          ],
        ),
      );

  Widget _usageRow(IconData icon, String label, String cost) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          Text(cost,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      );
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/diamond_recharge_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/features/meeting/diamond_recharge_screen.dart test/diamond_recharge_screen_test.dart && git commit -m "feat: rebuild DiamondRechargeScreen from mockup"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## Task 2: 헤더 다이아 칩 → 충전 화면 진입

**Files:**
- Modify: `lib/features/home/widgets/home_header.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `test/home_screen_test.dart` (테스트 추가)

- [ ] **Step 1: 홈 테스트 추가(실패 유도)**

`test/home_screen_test.dart` 상단 import에 추가:
```dart
import 'package:moija/features/meeting/diamond_recharge_screen.dart';
```
그리고 `void main(){` 안 마지막 `});` 다음(닫는 `}` 직전)에 추가:

```dart
  testWidgets('tapping the diamond chip opens the recharge screen',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('header-diamond')));
    await tester.pumpAndSettle();
    expect(find.byType(DiamondRechargeScreen), findsOneWidget);
  });
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/home_screen_test.dart`
Expected: FAIL — 칩 키/탭 없음.

- [ ] **Step 3: `home_header.dart` 수정**

(a) 생성자/필드에 `onDiamondTap` 추가:
```dart
  const HomeHeader({
    super.key,
    required this.monthLabel,
    required this.diamonds,
    required this.onDiamondTap,
  });

  final String monthLabel;
  final int diamonds;
  final VoidCallback onDiamondTap;
```
(b) 다이아 `Container(...)`(칩)를 `GestureDetector`로 감싼다:
```dart
          GestureDetector(
            key: const Key('header-diamond'),
            onTap: onDiamondTap,
            child: Container(
              // ... 기존 다이아 칩 Container 그대로 ...
            ),
          ),
```
(기존 `Container(padding: ... 다이아 칩 ...)`를 위 GestureDetector의 child로 이동)

- [ ] **Step 4: `home_screen.dart` 수정**

(a) import 추가: `import '../meeting/diamond_recharge_screen.dart';`
(b) `HomeHeader(monthLabel: _monthLabel(), diamonds: Wallet.myDiamonds)`를 다음으로:
```dart
            HomeHeader(
              monthLabel: _monthLabel(),
              diamonds: Wallet.myDiamonds,
              onDiamondTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DiamondRechargeScreen(
                      currentDiamonds: Wallet.myDiamonds),
                ),
              ),
            ),
```

- [ ] **Step 5: 통과 + 전체**

Run: `flutter test test/home_screen_test.dart && flutter analyze && flutter test`
Expected: 전부 PASS, No issues.

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "feat: open recharge screen from home diamond chip"
```
(커밋 본문 끝에 Co-Authored-By 줄 추가)

---

## 최종 검증
- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS
- [ ] `flutter run`: 홈 헤더 다이아(30) 탭 → 충전 화면(현재 보유 30, 패키지 선택, 결제 버튼 금액 변화).

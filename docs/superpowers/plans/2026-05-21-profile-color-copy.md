# 프로필 성별 색상 · 비용/다이아 문구 변경 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 참가자 아바타를 성별 색(남=파랑/여=분홍)으로, 비용 '엔빵'→'1/N', 다이아 캡션 문구를 변경한다.

**Architecture:** 색상 토큰 추가 + 위젯/모델/문구 소규모 수정. 로직 구조 불변.

**Tech Stack:** Flutter 3.38 / Dart 3.10, `flutter_test`.

**참조 스펙:** `docs/superpowers/specs/2026-05-21-profile-color-copy-design.md`

---

## Task 1: 색상 토큰 + 비용 단어 + 캡션 + 성별 아바타

**Files:**
- Modify: `lib/theme/app_colors.dart`
- Modify: `lib/models/meeting_cost.dart`
- Modify: `test/meeting_cost_test.dart`
- Modify: `lib/features/meeting/widgets/participant_card.dart`
- Modify: `lib/features/meeting/meeting_detail_screen.dart`
- Modify: `test/meeting_detail_screen_test.dart`

- [ ] **Step 1: 비용/문구 테스트 갱신(실패 유도)**

`test/meeting_cost_test.dart`에서 `expect(const MeetingCost(CostType.split).display, '엔빵');`를
`expect(const MeetingCost(CostType.split).display, '1/N');`로 변경.

`test/meeting_detail_screen_test.dart`에서
`expect(find.text('수락 시 50 다이아 사용'), findsOneWidget);`를
`expect(find.text('방장이 수락할 경우 다이아 50개 차감'), findsOneWidget);`로 변경.

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/meeting_cost_test.dart test/meeting_detail_screen_test.dart`
Expected: FAIL (라벨/문구 불일치).

- [ ] **Step 3: 색상 토큰 추가**

`lib/theme/app_colors.dart`의 보더 섹션 앞(텍스트 섹션 끝, `textDanger` 다음 줄)에 분홍 추가:
```dart
  static const bgPink = Color(0xFFFDE7EF);
  static const textPink = Color(0xFFC2185B);
```

- [ ] **Step 4: 비용 단어 변경**

`lib/models/meeting_cost.dart`에서 `split('엔빵'),` → `split('1/N'),`.

- [ ] **Step 5: 캡션 변경**

`lib/features/meeting/meeting_detail_screen.dart`의 하단 캡션 Text를
`'방장이 수락할 경우 다이아 50개 차감'`으로 변경.

- [ ] **Step 6: 성별 아바타 색**

`lib/features/meeting/widgets/participant_card.dart`의 `build`에서 `initial` 계산 다음에 색을 정한다:
```dart
    final isMale = member.gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;
```
그리고 아바타 `Container`의 `decoration: const BoxDecoration(color: AppColors.bgInfo, shape: BoxShape.circle)`를
`decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle)`로,
이니셜 `Text`의 `color: AppColors.textInfo`를 `color: avatarFg`로 변경한다. (해당 줄들의 `const`는 색이 변수가 되므로 제거)

- [ ] **Step 7: 통과 + 전체**

Run: `flutter test && flutter analyze`
Expected: 전부 PASS, No issues.

- [ ] **Step 8: 커밋**

```bash
git add -A && git commit -m "feat: gender-colored avatars, 1/N cost label, updated diamond copy"
```
(커밋 본문 끝에: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`)

---

## 최종 검증
- [ ] `flutter analyze` → No issues
- [ ] `flutter test` → 전부 PASS

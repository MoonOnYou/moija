# 모이자 — 더치페이 + 참가 신청 흐름(다이아 분기) 설계

작성일: 2026-05-21

## 변경

1. **비용 단어**: `CostType.split` `'1/N'` → `'더치페이'`.
2. **지갑 단일 소스**: `lib/data/wallet.dart` `class Wallet { static const int myDiamonds = 30; }`. 홈 헤더 다이아 표시를 이 값으로 통일(`HomeHeader`에 `diamonds` 파라미터).
3. **참가 신청 버튼(`MeetingDetailScreen`)**:
   - 하단 별도 캡션 제거 → 버튼 안 2줄: "참가 신청하기" + 작게 "방장 수락 시 다이아 50개 차감".
   - `int diamonds` 파라미터(기본 `Wallet.myDiamonds`).
   - 탭:
     - 잔액 ≤ 50 → SnackBar "다이아 50개 이상일 때 참가 신청을 할 수 있어요" + `DiamondRechargeScreen` push.
     - 잔액 > 50 → SnackBar "참가 신청이 완료됐어요" + `Navigator.pop`(홈 복귀).
4. **충전 화면(`lib/features/meeting/diamond_recharge_screen.dart`)**: 플레이스홀더(앱바 "다이아 충전" + 현재 잔액 + 충전 옵션 타일 3개, 동작 없음).
5. 토스트 = `ScaffoldMessenger` SnackBar(앱 레벨이라 pop 후 홈에서도 보임).

## 파일
- 신규: `lib/data/wallet.dart`, `lib/features/meeting/diamond_recharge_screen.dart`.
- 수정: `lib/models/meeting_cost.dart`(더치페이), `lib/features/home/widgets/home_header.dart`(diamonds), `lib/features/home/home_screen.dart`(전달), `lib/features/meeting/meeting_detail_screen.dart`(버튼·분기).
- 테스트: `meeting_cost_test`(더치페이), `meeting_detail_screen_test`(버튼 문구 + 차단/성공 분기).

## 테스트 상세
- split.display == '더치페이'.
- 상세: 버튼 "참가 신청하기" & "방장 수락 시 다이아 50개 차감" 표시.
- 잔액 30 탭 → `DiamondRechargeScreen` 표시 + "다이아 50개 이상일 때 참가 신청을 할 수 있어요" SnackBar.
- 잔액 1000(상세를 push한 호스트 위에서) 탭 → 상세 pop(`findsNothing`) + "참가 신청이 완료됐어요" SnackBar.

## 범위 밖
- 실제 결제·잔액 차감/증가, 충전 동작, 백엔드.

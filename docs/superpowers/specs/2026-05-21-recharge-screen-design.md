# 모이자 — 다이아 충전 화면(목업 반영) + 헤더 진입 설계

작성일: 2026-05-21
참조 목업: `docs/page/08_다이아충전.html`

## 변경

1. **`DiamondRechargeScreen` 재구성** (StatelessWidget → StatefulWidget, 패키지 선택 상태):
   - 앱바: 뒤로 + "다이아 충전".
   - 현재 보유 카드(bgInfo): "현재 보유" + 다이아 아이콘 + `currentDiamonds`.
   - "충전 패키지" 4종(탭 선택, 기본=인기):
     - 1,000 다이아 / ₩1,000
     - 3,300 다이아 (보너스 +300 (10%)) / ₩3,000 — [인기] 배지 + 선택 테두리
     - 5,750 다이아 (보너스 +750 (15%)) / ₩5,000
     - 12,000 다이아 (보너스 +2,000 (20%)) / ₩10,000
   - 선택 시 파란 테두리(`borderInfo` 2px); 하단 결제 버튼 금액이 선택 패키지로 갱신.
   - 광고 카드(bgWarning): "광고 보고 무료 충전" / "15초 광고 시청 시 50 다이아" / [받기](no-op).
   - 사용처 카드(bgSecondary): "다이아는 어디에 쓰나요?" — 모임 만들기 300 / 채팅방 참가 50.
   - 하단 고정 버튼: "₩{선택 금액} 결제하기"(no-op).
   - 아이콘 Material 매핑(diamond/play_arrow/add/chat_bubble_outline), 천단위 콤마 `intl` `NumberFormat('#,###')`.

2. **홈 헤더 진입**: `HomeHeader` 다이아 칩을 탭 가능하게 `onDiamondTap` 콜백 추가(`Key('header-diamond')`). 홈이 `DiamondRechargeScreen(currentDiamonds: Wallet.myDiamonds)` push.

## 파일
- 수정(전체 교체): `lib/features/meeting/diamond_recharge_screen.dart`.
- 수정: `lib/features/home/widgets/home_header.dart`(onDiamondTap), `lib/features/home/home_screen.dart`(push).
- 테스트: `diamond_recharge_screen_test`(신규), `home_screen_test`(헤더 칩 탭).

## 테스트
- 충전 화면: "현재 보유"·`currentDiamonds` 표시, 4개 패키지 라벨 표시, 기본 버튼 "₩3,000 결제하기", "12,000 다이아" 탭 → "₩10,000 결제하기", "광고 보고 무료 충전" 표시.
- 홈: `Key('header-diamond')` 탭 → `DiamondRechargeScreen` 표시.

## 범위 밖
- 실제 결제·광고 시청·잔액 증가, 백엔드. (모두 no-op)
- `MeetingDetailScreen`의 기존 충전 진입은 그대로 동작(같은 화면 재사용).

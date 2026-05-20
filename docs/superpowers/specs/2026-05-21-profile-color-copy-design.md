# 모이자 — 프로필 성별 색상 · 비용/다이아 문구 변경 설계

작성일: 2026-05-21

## 변경 3건

1. **성별 색상**: 참가자 아바타(원 배경 + 이니셜)를 성별로 — 남 = 파랑(`bgInfo`/`textInfo`), 여 = 분홍(`bgPink`/`textPink`). `AppColors`에 분홍 토큰 추가.
2. **비용 단어**: `CostType.split` 라벨 `'엔빵'` → `'1/N'`. `meeting_cost_test` 기대값 갱신.
3. **다이아 문구**: `MeetingDetailScreen` 하단 캡션 `'수락 시 50 다이아 사용'` → `'방장이 수락할 경우 다이아 50개 차감'`.

## 파일
- `lib/theme/app_colors.dart`: `bgPink`(연분홍), `textPink`(진분홍) 추가.
- `lib/models/meeting_cost.dart`: split 라벨 `'1/N'`.
- `test/meeting_cost_test.dart`: split.display 기대값 `'1/N'`.
- `lib/features/meeting/widgets/participant_card.dart`: 성별별 아바타 색.
- `lib/features/meeting/meeting_detail_screen.dart`: 캡션 문구.

## 테스트
- `meeting_cost_test`: split → `'1/N'`(나머지 그대로).
- `meeting_detail_screen_test`: 캡션 단언을 `'방장이 수락할 경우 다이아 50개 차감'`으로 갱신.
- (선택) `participant_card`는 색상 변경이라 단언이 까다로워 시각 확인으로 갈음; analyze 통과로 검증.

## 범위 밖
- 다른 색 테마, 비용 모델 구조 변경.

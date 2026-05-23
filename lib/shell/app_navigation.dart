import 'package:flutter/foundation.dart';

/// 하단 탭 인덱스(홈 0 · 채팅 1 · 내모임 2 · 프로필 3).
///
/// 모임 만들기/참가처럼 셸 위에 push된 화면에서도 동의 후 특정 탭으로
/// 이동시킬 수 있도록 전역 ValueNotifier로 둔다. AppShell이 이를 구독한다.
final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

/// 새 모임이 생성된 직후, 홈 캘린더가 이 날짜로 이동하도록 요청한다.
/// HomeScreen이 구독하여 _goToDay 후 다시 null로 비운다.
final ValueNotifier<DateTime?> pendingFocusDay = ValueNotifier<DateTime?>(null);

import 'package:flutter/foundation.dart';

/// 하단 탭 인덱스(홈 0 · 내모임 1 · 프로필 2).
///
/// 모임 만들기/참가처럼 셸 위에 push된 화면에서도 동의 후 특정 탭으로
/// 이동시킬 수 있도록 전역 ValueNotifier로 둔다. AppShell이 이를 구독한다.
final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

/// 새 모임이 생성된 직후, 홈 캘린더가 이 날짜로 이동하도록 요청한다.
/// HomeScreen이 구독하여 _goToDay 후 다시 null로 비운다.
final ValueNotifier<DateTime?> pendingFocusDay = ValueNotifier<DateTime?>(null);

/// 내모임 데이터(신청 취소 등)가 바뀌면 bump 한다. AppShell이 듣고 탭 배지를 갱신한다.
final ValueNotifier<int> myMeetingsRevision = ValueNotifier<int>(0);

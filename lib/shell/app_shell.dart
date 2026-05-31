import 'package:flutter/material.dart';
import '../data/api/meeting_api.dart';
import '../data/meeting_repository.dart';
import '../features/chat/chat_preview.dart';
import '../features/chat/chat_screen.dart';
import '../features/common/force_update_dialog.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../theme/app_colors.dart';
import 'app_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.showForceUpdate = true});

  /// 앱 진입 시 강제 업데이트 다이얼로그를 띄울지 여부. 테스트에서는 false로 끈다.
  final bool showForceUpdate;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  // 홈과 내모임이 같은 모임 데이터를 공유하도록 한 인스턴스를 셸에서 보유한다.
  final MeetingRepository _repository = MeetingRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showForceUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ForceUpdateDialog.show(context);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 백그라운드에서 자정을 넘어 돌아오면 시간 의존 화면(내모임 D-N, 진행중 라벨 등)을
    // 다시 그려야 한다. setState로 IndexedStack 자식들의 build를 한 번 강제.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([selectedTab, myMeetingsRevision]),
      builder: (context, _) {
        final index = selectedTab.value;
        final unread = myMeetingsBadgeTotal(_repository, DateTime.now());

        // 모든 탭 위젯을 IndexedStack에 살려둬, 탭 전환 후 돌아와도
        // HomeScreen의 저장소·선택 날짜 같은 상태가 보존되도록 한다.
        return PopScope(
          // 첫 탭이 아니면 뒤로가기로 앱을 끄지 않고 첫 탭(홈)으로 돌아간다.
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (index != 0) selectedTab.value = 0;
          },
          child: Scaffold(
            body: IndexedStack(
              index: index,
              children: [
                HomeScreen(
                  repository: _repository,
                  loadMeetings: (from, to) =>
                      fetchMeetings(dateFrom: from, dateTo: to),
                  fetchDetail: fetchMeetingDetail,
                ),
                ChatScreen(repository: _repository),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.borderTertiary, width: 0.5),
                ),
              ),
              child: NavigationBarTheme(
                data: const NavigationBarThemeData(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  // 눌림 효과 제거 — 아이콘 outlined↔rounded 전환만 보이도록.
                  indicatorColor: Colors.transparent,
                  overlayColor: WidgetStatePropertyAll(Colors.transparent),
                  elevation: 0,
                  labelTextStyle: WidgetStatePropertyAll(
                    TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                child: NavigationBar(
                  height: 64,
                  selectedIndex: index,
                  onDestinationSelected: (i) => selectedTab.value = i,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: '홈',
                    ),
                    NavigationDestination(
                      icon: _BadgedIcon(
                        icon: Icons.groups_outlined,
                        count: unread,
                      ),
                      selectedIcon: _BadgedIcon(
                        icon: Icons.groups_rounded,
                        count: unread,
                      ),
                      label: '내모임',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: '프로필',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.textDanger,
      textColor: Colors.white,
      child: Icon(icon),
    );
  }
}

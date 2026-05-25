import 'package:flutter/material.dart';
import '../data/meeting_repository.dart';
import '../features/chat/chat_preview.dart';
import '../features/chat/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../theme/app_colors.dart';
import 'app_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 홈과 내모임이 같은 모임 데이터를 공유하도록 한 인스턴스를 셸에서 보유한다.
  final MeetingRepository _repository = MeetingRepository();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([selectedTab, myMeetingsRevision]),
      builder: (context, _) {
        final index = selectedTab.value;
        final unread =
            myMeetingsBadgeTotal(_repository, DateTime.now());

        // 모든 탭 위젯을 IndexedStack에 살려둬, 탭 전환 후 돌아와도
        // HomeScreen의 저장소·선택 날짜 같은 상태가 보존되도록 한다.
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              HomeScreen(repository: _repository),
              ChatScreen(repository: _repository),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBarTheme(
            data: const NavigationBarThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.bgSecondary,
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


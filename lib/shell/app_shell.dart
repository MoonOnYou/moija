import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../theme/app_colors.dart';
import 'app_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _placeholders = ['채팅', '내모임', '프로필'];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedTab,
      builder: (context, index, _) {
        final Widget body = index == 0
            ? const HomeScreen()
            : _Placeholder(label: _placeholders[index - 1]);

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => selectedTab.value = i,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
              NavigationDestination(icon: Icon(Icons.bookmark_border), label: '내모임'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
            ],
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Text('$label (준비 중)',
            style: const TextStyle(
                fontSize: 15, color: AppColors.textTertiary)),
      ),
    );
  }
}

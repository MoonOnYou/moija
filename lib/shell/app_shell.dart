import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _placeholders = ['채팅', '내모임', '프로필'];

  @override
  Widget build(BuildContext context) {
    final Widget body = _index == 0
        ? const HomeScreen()
        : _Placeholder(label: _placeholders[_index - 1]);

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: '내모임'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
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

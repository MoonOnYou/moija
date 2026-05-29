import 'dart:async';

import 'package:flutter/material.dart';
import '../../shell/app_shell.dart';
import '../../theme/app_colors.dart';

/// 앱 진입 스플래시. 앱 아이콘 + 따뜻한 한 줄 소개를 잠깐 보여준 뒤 홈으로 전환.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2000), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const AppShell(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SplashDots(),
                const SizedBox(height: 22),
                const Text(
                  '모이자',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '혼자보다 함께라서 더 즐거운 하루',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 회원가입 시작 화면의 점 인디케이터와 같은 색·배열(스플래시용으로 살짝 크게).
class _SplashDots extends StatelessWidget {
  const _SplashDots();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, double s) => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(AppColors.coral, 14),
        const SizedBox(width: 8),
        dot(AppColors.mint, 11),
        const SizedBox(width: 8),
        dot(AppColors.amber, 10),
      ],
    );
  }
}

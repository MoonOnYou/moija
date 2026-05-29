import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/moija_logo.dart';
import 'signup_session.dart';

/// 가입 완료 — 환영 메시지를 1초 보여 주고 홈(루트)으로 돌려보낸다.
/// `Navigator.popUntil(root)`로 가입 플로우의 모든 페이지를 한 번에 닫는다.
class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _timer = Timer(const Duration(milliseconds: 2000), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nickname =
        widget.session.nickname.isEmpty ? '모이자' : widget.session.nickname;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _ctrl,
                    curve: Curves.easeOutBack,
                  ),
                  child: const MoijaLogo(size: 88),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _ctrl,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                  child: Column(
                    children: [
                      Text('$nickname 님, 반가워요',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 8),
                      const Text(
                        '오늘, 같이 놀 사람을 찾아 볼까요?',
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgCoral,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('가입 완료',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.coral,
                            )),
                      ),
                    ],
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

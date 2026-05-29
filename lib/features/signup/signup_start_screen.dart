import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/moija_logo.dart';
import 'signup_flow.dart';
import 'signup_session.dart';
import 'signup_terms_screen.dart';

/// 가입 플로우 진입 화면. 큰 로고 + 슬로건 + 시작하기 CTA.
class SignupStartScreen extends StatelessWidget {
  const SignupStartScreen({super.key});

  static Future<void> start(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const SignupStartScreen(),
    ));
  }

  void _begin(BuildContext context) {
    final session = SignupSession();
    Navigator.of(context).pushReplacement(signupRoute(
      (_) => SignupTermsScreen(session: session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          splashRadius: 22,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const MoijaLogo(size: 84),
              const SizedBox(height: 24),
              const Text('오늘, 같이 놀 사람',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 10),
              const Text(
                '가벼운 마음으로 시작해요.\n잠깐이면 돼요 — 약 1분.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _MiniDots(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _begin(context),
                  child: const Text('시작하기'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('이미 계정이 있어요'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, double s) =>
        Container(width: s, height: s, decoration: BoxDecoration(
              color: c, shape: BoxShape.circle));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(AppColors.coral, 10),
        const SizedBox(width: 6),
        dot(AppColors.mint, 8),
        const SizedBox(width: 6),
        dot(AppColors.amber, 7),
      ],
    );
  }
}

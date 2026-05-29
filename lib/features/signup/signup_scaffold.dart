import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';

/// 가입 플로우 공통 레이아웃.
/// 진행률 막대 → 화면 안내(제목+부제) → 본문 → 하단 Coral CTA 의 일관 구조.
class SignupScaffold extends StatelessWidget {
  const SignupScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    required this.child,
    this.primaryLabel,
    this.onPrimary,
    this.primaryLoading = false,
    this.bottomHint,
    this.showBack = true,
    this.scrollable = true,
  });

  final int step; // 1-indexed
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget child;

  /// 하단 코랄 CTA. null이면 CTA 영역을 그리지 않는다.
  final String? primaryLabel;

  /// null이면 비활성(회색). 활성/비활성은 호출자가 판단해 넘긴다.
  final VoidCallback? onPrimary;
  final bool primaryLoading;

  /// CTA 위 작은 안내 문구(약관 안내 등).
  final Widget? bottomHint;

  final bool showBack;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );

    return PopScope(
      // 가입 도중 뒤로가기는 단계 이동이 아니라 "종료 확인"으로 처리한다.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        confirmExitSignup(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: PreferredSize(
          // 상태바(노치 포함) 높이만큼 더 확보해 뒤로가기와 겹치지 않게 한다.
          preferredSize: Size.fromHeight(
            56 + MediaQuery.of(context).padding.top,
          ),
          child: _SignupAppBar(
            step: step,
            totalSteps: totalSteps,
            showBack: showBack,
            onBack: () => confirmExitSignup(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: scrollable
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: body,
                )
              : body,
        ),
        bottomNavigationBar: primaryLabel == null
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bottomHint != null) ...[
                      DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        child: bottomHint!,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _CoralButton(
                      label: primaryLabel!,
                      onPressed: primaryLoading ? null : onPrimary,
                      loading: primaryLoading,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SignupAppBar extends StatelessWidget {
  const _SignupAppBar({
    required this.step,
    required this.totalSteps,
    required this.showBack,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (step / totalSteps).clamp(0.0, 1.0);
    return Container(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(showBack ? 4 : 22, 0, 22, 6),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: onBack,
                        splashRadius: 22,
                      )
                    else
                      const SizedBox(width: 4),
                    const Spacer(),
                    Text(
                      '$step / $totalSteps',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.bgSecondary,
                  valueColor: const AlwaysStoppedAnimation(AppColors.coral),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoralButton extends StatelessWidget {
  const _CoralButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: enabled ? onPressed : null,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'withdrawal_reason_screen.dart';

/// 회원 탈퇴 플로우에 속한 라우트에 붙이는 이름.
/// "안 할게요"를 누르면 이 이름을 가진 라우트를 한 번에 닫아 프로필로 되돌린다.
const String kWithdrawalRouteName = 'withdrawal_flow';

/// 탈퇴 단계 화면을 push할 때 쓰는 라우트 빌더.
Route<T> withdrawalRoute<T>(WidgetBuilder builder) => MaterialPageRoute<T>(
      builder: builder,
      settings: const RouteSettings(name: kWithdrawalRouteName),
    );

/// 탈퇴 플로우 전체를 닫고 진입 직전(프로필)으로 되돌린다.
void cancelWithdrawal(BuildContext context) {
  Navigator.of(context)
      .popUntil((route) => route.settings.name != kWithdrawalRouteName);
}

/// 탈퇴 플로우 전 단계에서 공유되는 계정 정보 + 사용자 입력 묶음.
/// 각 화면이 같은 인스턴스를 전달받아 사유를 채워 나간다. (현재는 모킹)
class WithdrawalSession {
  WithdrawalSession({
    required this.phone,
    required this.diamonds,
    required this.mannerScore,
    required this.activities,
    required this.blockCount,
    required this.joinedCount,
    this.hostsMeeting = true,
  });

  /// 등록된 휴대폰 번호(숫자만, 예: 01012345678).
  final String phone;

  /// 탈퇴 시 사라지는 항목들(요약 카드에 노출).
  final int diamonds;
  final double mannerScore;
  final int activities;
  final int blockCount;
  final int joinedCount;

  /// 방장으로 운영 중인 모임이 있는지 — 있으면 위임 안내를 띄운다.
  final bool hostsMeeting;

  /// 떠나는 이유(선택, 복수 선택 가능). 화면 1에서 채워진다.
  final List<String> reasons = [];
  String detail = '';

  String get formattedPhone {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
  }
}

/// 회원 탈퇴 플로우 진입점. 프로필에서 호출한다.
class WithdrawalFlow {
  const WithdrawalFlow._();

  static Future<void> start(
    BuildContext context, {
    required WithdrawalSession session,
  }) {
    return Navigator.of(context).push(
      withdrawalRoute((_) => WithdrawalReasonScreen(session: session)),
    );
  }
}

/// 탈퇴 단계 공통 레이아웃 — "회원 탈퇴" 앱바 + 제목/부제 + 본문 + 하단 CTA.
class WithdrawalScaffold extends StatelessWidget {
  const WithdrawalScaffold({
    super.key,
    required this.appBarTitle,
    required this.heading,
    this.subtitle,
    required this.child,
    required this.actions,
  });

  final String appBarTitle;
  final String heading;
  final Widget? subtitle;
  final Widget child;

  /// 하단 CTA 버튼들. 가로로 균등 분할된다(1~2개).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: Text(appBarTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                  child: subtitle!,
                ),
              ],
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: actions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary, danger }

/// 탈퇴 플로우 하단 CTA 버튼. primary(코랄)·secondary(옅은 회색)·danger(빨강).
class WithdrawalButton extends StatelessWidget {
  const WithdrawalButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _variant = _ButtonVariant.primary;

  const WithdrawalButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
  })  : _variant = _ButtonVariant.secondary,
        icon = null;

  const WithdrawalButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
  })  : _variant = _ButtonVariant.danger,
        icon = null;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color bg;
    final Color fg;
    switch (_variant) {
      case _ButtonVariant.primary:
        bg = enabled ? AppColors.coral : AppColors.coral.withValues(alpha: 0.35);
        fg = Colors.white;
      case _ButtonVariant.secondary:
        bg = AppColors.bgSecondary;
        fg = AppColors.textSecondary;
      case _ButtonVariant.danger:
        bg = enabled ? AppColors.textDanger : const Color(0xFFE1DED4);
        fg = Colors.white;
    }
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg,
          disabledForegroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

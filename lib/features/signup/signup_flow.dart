import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'signup_start_screen.dart';

/// 가입 플로우에 속한 모든 라우트에 붙이는 이름.
/// 종료 시 이 이름을 가진 라우트를 한 번에 닫아 시작 화면으로 되돌린다.
const String kSignupRouteName = 'signup_flow';

/// 가입 단계 화면을 push할 때 쓰는 라우트 빌더. [kSignupRouteName]을 달아
/// "가입 플로우 소속"임을 표시한다(서브 피커 등은 일반 라우트로 띄운다).
Route<T> signupRoute<T>(WidgetBuilder builder) => MaterialPageRoute<T>(
      builder: builder,
      settings: const RouteSettings(name: kSignupRouteName),
    );

/// 가입 도중 뒤로가기 시 호출. 종료 확인 팝업을 띄우고, 사용자가 종료를 택하면
/// 가입 플로우의 모든 라우트를 닫은 뒤 시작 화면("오늘, 같이 놀 사람")으로 되돌린다.
Future<void> confirmExitSignup(BuildContext context) async {
  final navigator = Navigator.of(context);
  final leave = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => const _SignupExitDialog(),
  );
  if (leave != true) return;

  // 가입 소속 라우트를 모두 닫고(진입 직전 화면까지), 시작 화면을 다시 띄운다.
  navigator.popUntil((route) => route.settings.name != kSignupRouteName);
  navigator.push(
    MaterialPageRoute(builder: (_) => const SignupStartScreen()),
  );
}

class _SignupExitDialog extends StatelessWidget {
  const _SignupExitDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.bgCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.coral, size: 26),
            ),
            const SizedBox(height: 18),
            const Text(
              '회원가입을 종료할까요?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '지금까지 입력한 내용이 모두 사라져요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('계속 입력하기'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('종료하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

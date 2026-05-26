import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/moija_logo.dart';

/// 강제 업데이트 안내 다이얼로그.
/// 닫기·뒤로가기로 빠져나갈 수 없고, "지금 업데이트" 버튼이 유일한 액션이다.
class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.onUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final VoidCallback onUpdate;

  /// 강제 업데이트 다이얼로그를 띄운다. barrier·뒤로가기 모두 차단된다.
  static Future<void> show(
    BuildContext context, {
    String currentVersion = '1.0.0',
    String latestVersion = '1.2.0',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: ForceUpdateDialog(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          // 출시 전 mock: 누르면 그냥 다이얼로그를 닫는다.
          // 출시 시점에는 url_launcher로 스토어로 보내도록 교체.
          onUpdate: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MoijaLogo(size: 72),
            const SizedBox(height: 18),
            const Text(
              '새 버전이 출시되었어요',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              '더 안정적인 이용을 위해\n최신 버전으로 업데이트가 필요해요',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('현재 $currentVersion',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Text('최신 $latestVersion',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textInfo)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('force-update-button'),
                onPressed: onUpdate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('지금 업데이트'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

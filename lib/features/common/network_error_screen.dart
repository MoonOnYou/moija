import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 네트워크 오류·비행기모드·서버 오류에 공통으로 쓰는 전체 화면.
/// [onRetry]가 있으면 "다시 시도" 버튼을 보여준다.
class NetworkErrorScreen extends StatelessWidget {
  const NetworkErrorScreen({
    super.key,
    this.icon = Icons.wifi_off_rounded,
    this.title = '인터넷에 연결할 수 없어요',
    this.message = '네트워크 연결 상태를 확인해 주세요.\n비행기 모드가 켜져 있진 않나요?',
    this.onRetry,
    this.retrying = false,
  });

  /// 서버 오류용 프리셋.
  const NetworkErrorScreen.server({
    super.key,
    this.onRetry,
    this.retrying = false,
  })  : icon = Icons.cloud_off_rounded,
        title = '일시적인 오류가 발생했어요',
        message = '잠시 후 다시 시도해 주세요.\n문제가 계속되면 고객센터로 알려 주세요.';

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgPrimary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: 180,
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
                    onPressed: retrying ? null : onRetry,
                    child: retrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('다시 시도'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

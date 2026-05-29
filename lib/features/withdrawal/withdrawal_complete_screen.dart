import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'withdrawal_flow.dart';

/// 4단계 — 탈퇴 완료. 인사 + 30일 후 재가입 안내 + 앱 종료.
class WithdrawalCompleteScreen extends StatefulWidget {
  const WithdrawalCompleteScreen({super.key, required this.session});
  final WithdrawalSession session;

  @override
  State<WithdrawalCompleteScreen> createState() =>
      _WithdrawalCompleteScreenState();
}

class _WithdrawalCompleteScreenState extends State<WithdrawalCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 탈퇴일 + 30일 = 같은 번호로 재가입 가능한 날.
  String get _rejoinDate {
    final d = DateTime.now().add(const Duration(days: 30));
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 완료 화면에서 시스템 뒤로가기로 플로우 중간으로 돌아가지 못하게 막는다.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: CurvedAnimation(
                            parent: _ctrl, curve: Curves.easeOutBack),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.borderTertiary, width: 0.5),
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded,
                              size: 42, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('탈퇴가 완료됐어요',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      const Text(
                        '그동안 함께해주셔서 고마워요.\n언제든 마음 바뀌면 다시 와주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                        decoration: BoxDecoration(
                          color: AppColors.bgPrimary,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: AppColors.borderTertiary, width: 0.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.event_available_rounded,
                                size: 18, color: AppColors.textWarning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('30일 후 다시 가입할 수 있어요',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text('$_rejoinDate부터 같은 번호로 가능해요.',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.5,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: WithdrawalButton.primary(
                    label: '앱 종료',
                    onPressed: () => SystemNavigator.pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'host_delegation_screen.dart';
import 'withdrawal_flow.dart';
import 'withdrawal_otp_screen.dart';

/// 2단계 — 탈퇴 전 최종 확인. 사라지는 것 + 방장 위임 안내 + 30일 정책 + 본인 확인 시작.
class WithdrawalConfirmScreen extends StatefulWidget {
  const WithdrawalConfirmScreen({super.key, required this.session});
  final WithdrawalSession session;

  @override
  State<WithdrawalConfirmScreen> createState() =>
      _WithdrawalConfirmScreenState();
}

class _WithdrawalConfirmScreenState extends State<WithdrawalConfirmScreen> {
  WithdrawalSession get session => widget.session;

  void _sendCode(BuildContext context) {
    // 방장으로 운영 중인 모임이 있으면 위임 전까지 탈퇴를 진행할 수 없다.
    if (session.hostsMeeting) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
        content: Text('운영 중인 모임의 방장을 먼저 위임해주세요'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
      content: Text('인증번호를 보냈어요'),
      duration: Duration(seconds: 2),
    ));
    Navigator.of(context).push(withdrawalRoute(
      (_) => WithdrawalOtpScreen(session: session),
    ));
  }

  /// 방장 정리 화면으로. 돌아오면 세션의 위임 결과를 반영해 다시 그린다.
  Future<void> _delegateHost(BuildContext context) async {
    await Navigator.of(context).push(withdrawalRoute(
      (_) => HostDelegationScreen(session: session),
    ));
    if (mounted) setState(() {});
  }

  String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return WithdrawalScaffold(
      appBarTitle: '회원 탈퇴',
      heading: '탈퇴 전 꼭 확인해주세요',
      subtitle: const Text('한 번 탈퇴하면 되돌릴 수 없어요.'),
      actions: [
        WithdrawalButton.secondary(
          label: '안 할게요',
          onPressed: () => cancelWithdrawal(context),
        ),
        WithdrawalButton.primary(
          label: '인증번호 받기',
          icon: Icons.sms_outlined,
          onPressed: () => _sendCode(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 탈퇴하면 사라지는 것
          Container(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.borderTertiary, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('탈퇴하면 사라져요',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
                _LoseRow(
                  icon: Icons.diamond_rounded,
                  iconColor: AppColors.textInfo,
                  iconBg: AppColors.bgInfo,
                  label: '남은 다이아 (소멸)',
                  value: '${_comma(session.diamonds)}개',
                ),
                _LoseRow(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.textSuccess,
                  iconBg: AppColors.bgSuccess,
                  label: '매너점수 · 활동 이력',
                  value:
                      '★ ${session.mannerScore.toStringAsFixed(1)} · ${session.activities}회',
                ),
                _LoseRow(
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.textDanger,
                  iconBg: AppColors.bgPink,
                  label: '차단·신고 목록',
                  value: '${session.blockCount}건',
                ),
                _LoseRow(
                  icon: Icons.event_rounded,
                  iconColor: AppColors.textWarning,
                  iconBg: AppColors.bgWarning,
                  label: '참가 중 모임',
                  value: '${session.joinedCount}개',
                  last: true,
                ),
              ],
            ),
          ),

          // 방장으로 운영 중인 모임 — 위임 안내(남은 게 있을 때)
          if (session.hostsMeeting) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFF0C5C5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 20, color: AppColors.textDanger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '방장으로 운영 중인 모임 '
                            '${session.unresolvedHostedMeetings.length}개가 있어요',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDanger)),
                        const SizedBox(height: 4),
                        const Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '탈퇴 전 다른 멤버에게 '),
                            TextSpan(
                                text: '방장을 위임',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                            TextSpan(text: '해야 해요.'),
                          ]),
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.5,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 7),
                        for (final m in session.unresolvedHostedMeetings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('· ${m.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    color: AppColors.textPrimary)),
                          ),
                        const SizedBox(height: 9),
                        GestureDetector(
                          key: const Key('go-delegate'),
                          onTap: () => _delegateHost(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.textDanger,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Text('방장 위임 진행 ›',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
          // 방장 정리 완료 — 무엇을 어떻게 넘겼는지 요약
          else if (session.handovers.isNotEmpty) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSuccess,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.mint),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 20, color: AppColors.textSuccess),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('방장을 모두 위임했어요',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSuccess)),
                        const SizedBox(height: 5),
                        for (final m in session.hostedMeetings)
                          if (session.handovers[m.id] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                  '· ${m.title} → ${session.handovers[m.id]!.nickname}님',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.45,
                                      color: AppColors.textSecondary)),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 30일 재가입 제한 안내
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgWarning,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFECD9B0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.gpp_maybe_outlined,
                        size: 16, color: AppColors.textWarning),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text('탈퇴 후 30일 동안 같은 전화번호로 다시 가입할 수 없어요',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: AppColors.textWarning)),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text:
                            '차단된 사용자가 새 계정으로 우회하는 것을 막기 위한 정책이에요. 또한 매너점수·차단·신고 이력은 30일 후 재가입하더라도 '),
                    TextSpan(
                        text: '같은 번호 계정에 그대로 따라와요',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: '.'),
                  ]),
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // 본인 확인 안내
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('본인 확인이 필요해요',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '등록된 휴대폰 번호 '),
                    TextSpan(
                        text: session.formattedPhone,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: '로 인증번호를 보내드릴게요.'),
                  ]),
                  style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 사라지는 항목 한 줄(아이콘 + 이름 + 값).
class _LoseRow extends StatelessWidget {
  const _LoseRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom:
                    BorderSide(color: AppColors.borderTertiary, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textPrimary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

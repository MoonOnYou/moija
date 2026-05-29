import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'withdrawal_complete_screen.dart';
import 'withdrawal_flow.dart';

/// 3단계 — 본인 확인(OTP). 6자리 입력 + 카운트다운 + 다시받기.
/// 모킹이라 아무 6자리나 통과한다. "탈퇴하기"는 6자리 입력 전까지 비활성.
class WithdrawalOtpScreen extends StatefulWidget {
  const WithdrawalOtpScreen({super.key, required this.session});
  final WithdrawalSession session;

  @override
  State<WithdrawalOtpScreen> createState() => _WithdrawalOtpScreenState();
}

class _WithdrawalOtpScreenState extends State<WithdrawalOtpScreen> {
  static const int _initialSeconds = 5 * 60;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _remaining = _initialSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _resend() {
    _controller.clear();
    _startTimer();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
      content: Text('인증번호를 다시 보냈어요'),
      duration: Duration(seconds: 2),
    ));
  }

  bool get _valid => _controller.text.length == 6 && _remaining > 0;

  void _withdraw() {
    Navigator.of(context).pushReplacement(withdrawalRoute(
      (_) => WithdrawalCompleteScreen(session: widget.session),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString();
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final timeout = _remaining <= 0;
    return WithdrawalScaffold(
      appBarTitle: '본인 확인',
      heading: '인증번호를 입력해주세요',
      subtitle: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: widget.session.formattedPhone,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(text: '로 인증번호 6자리를 보냈어요.\n안 왔으면 스팸함도 한번 확인해주세요.'),
        ]),
      ),
      actions: [
        WithdrawalButton.secondary(
          label: '안 할게요',
          onPressed: () => cancelWithdrawal(context),
        ),
        WithdrawalButton.danger(
          label: '탈퇴하기',
          onPressed: _valid ? _withdraw : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('인증번호 6자리',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _OtpBoxes(
            controller: _controller,
            focusNode: _focus,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                timeout ? '시간이 만료됐어요' : '남은 ${_formatTime(_remaining)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: timeout ? AppColors.textDanger : AppColors.coral,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resend,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  minimumSize: const Size(40, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('다시 받기'),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.textWarning),
                    SizedBox(width: 6),
                    Text('마지막 확인',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWarning)),
                  ],
                ),
                const SizedBox(height: 7),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '인증을 완료하고 '),
                    TextSpan(
                        text: '탈퇴하기',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDanger)),
                    TextSpan(text: '를 누르면 즉시 탈퇴되고 '),
                    TextSpan(
                        text: '30일간 같은 번호로 재가입',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: '할 수 없어요. 다이아와 매너점수·이력도 함께 사라져요.'),
                  ]),
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 6칸 시각화 + 보이지 않는 [TextField] 하나가 실제 입력을 처리한다.
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 56,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (focusNode.hasFocus) {
              SystemChannels.textInput.invokeMethod<void>('TextInput.show');
            } else {
              focusNode.requestFocus();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, _) {
              final text = controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final filled = i < text.length;
                  final active = i == text.length && focusNode.hasFocus;
                  return Container(
                    width: 44,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: filled ? const Color(0xFFFFF5EE) : AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: active || filled
                            ? AppColors.coral
                            : AppColors.borderTertiary,
                        width: active ? 1.6 : 1,
                      ),
                    ),
                    child: Text(filled ? text[i] : '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

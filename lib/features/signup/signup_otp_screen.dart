import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/api/auth_api.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_password_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 6자리 인증번호 입력. 서버 verify-otp로 실제 검증한다.
/// 3분 카운트다운 + 재전송 버튼. [devCode]가 있으면(개발 서버) 자동입력한다.
class SignupOtpScreen extends StatefulWidget {
  const SignupOtpScreen({super.key, required this.session, this.devCode});
  final SignupSession session;
  final String? devCode;

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  static const int _initialSeconds = 3 * 60;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _remaining = _initialSeconds;

  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // 개발 서버가 내려준 인증번호를 자동입력한다(실서버에선 null).
    if (widget.devCode != null && widget.devCode!.isNotEmpty) {
      _controller.text = widget.devCode!;
    }
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
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(const SnackBar(
      content: Text('인증번호를 다시 보냈어요'),
      duration: Duration(seconds: 2),
    ));
  }

  bool get _valid => _controller.text.length == 6;

  Future<void> _next() async {
    setState(() => _verifying = true);
    try {
      final token = await verifyOtp(widget.session.phone, _controller.text);
      widget.session.verificationToken = token;
      if (!mounted) return;
      Navigator.of(context).push(signupRoute(
        (_) => SignupPasswordScreen(session: widget.session),
      ));
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('네트워크 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _formatPhone(String d) {
    if (d.length != 11) return d;
    return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final timeout = _remaining <= 0;
    return SignupScaffold(
      step: 3,
      totalSteps: 9,
      title: '인증번호 6자리를 입력해 주세요',
      subtitle: '${_formatPhone(widget.session.phone)} 으로 보냈어요.',
      primaryLabel: '인증 완료',
      onPrimary: _valid && !timeout && !_verifying ? _next : null,
      primaryLoading: _verifying,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OtpBoxes(
            controller: _controller,
            focusNode: _focus,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 14,
                  color: timeout
                      ? AppColors.textDanger
                      : AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                timeout ? '시간이 만료됐어요' : '남은 시간 ${_formatTime(_remaining)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: timeout
                      ? AppColors.textDanger
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resend,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textInfo,
                  minimumSize: const Size(40, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('인증번호 다시 받기'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.help_outline_rounded,
                    size: 16, color: AppColors.textTertiary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '문자가 오지 않나요?\n스팸함을 확인하거나 1분 뒤 다시 받아 보세요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 6칸짜리 시각화 + 실제 텍스트는 보이지 않는 하나의 [TextField]가 처리한다.
/// 박스 위를 탭하면 키보드가 다시 올라온다.
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
            height: 64,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: onChanged,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
        GestureDetector(
          // 키보드가 시스템에 의해 내려가도 FocusNode는 포커스를 유지하므로
          // requestFocus만으론 키보드가 다시 안 뜬다. 이미 포커스가 있으면
          // 플랫폼에 직접 키보드 표시를 요청한다.
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
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.coral
                            : (filled
                                ? AppColors.textPrimary
                                : AppColors.borderTertiary),
                        width: active ? 1.6 : 0.8,
                      ),
                    ),
                    child: Text(filled ? text[i] : '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
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

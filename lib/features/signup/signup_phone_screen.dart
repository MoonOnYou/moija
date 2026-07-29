import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/api/auth_api.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_otp_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 전화번호 입력. 010 / 011 등 한국식 11자리. 다른 기기에서도 다시 받을 수 있게
/// SMS 인증을 사용한다는 안내를 함께 보여준다.
class SignupPhoneScreen extends StatefulWidget {
  const SignupPhoneScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupPhoneScreen> createState() => _SignupPhoneScreenState();
}

class _SignupPhoneScreenState extends State<SignupPhoneScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.session.phone);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid =>
      _digits.length == 11 &&
      (_digits.startsWith('010') ||
          _digits.startsWith('011') ||
          _digits.startsWith('016') ||
          _digits.startsWith('017') ||
          _digits.startsWith('018') ||
          _digits.startsWith('019'));

  bool _sending = false;

  Future<void> _next() async {
    widget.session.phone = _digits;
    setState(() => _sending = true);
    try {
      final res = await sendOtp(_digits);
      if (!mounted) return;
      // DEBUG 서버는 dev_code를 내려주며, OTP 화면에서 자동입력에 쓴다.
      final devCode = res['dev_code'] as String?;
      Navigator.of(context).push(signupRoute(
        (_) => SignupOtpScreen(session: widget.session, devCode: devCode),
      ));
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('네트워크 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      step: 2,
      totalSteps: 9,
      title: '전화번호를 알려 주세요',
      subtitle: '문자로 인증번호를 보내드려요.\n번호는 본인 확인과 알림 외에는 쓰이지 않아요.',
      primaryLabel: '인증번호 받기',
      onPrimary: _valid && !_sending ? _next : null,
      primaryLoading: _sending,
      bottomHint: const Text(
          'SKT · KT · LGU+ 알뜰폰 모두 가능해요.\n해외 번호는 아직 지원하지 않아요.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: '휴대폰 번호',
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _PhoneFormatter(),
              ],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.4,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '010-0000-0000',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.shield_rounded,
            text:
                '입력한 번호는 암호화되어 저장되며, 다른 사용자에게 공개되지 않아요.',
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.borderTertiary, width: 0.6),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bgInfo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textInfo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.textInfo,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }
}

/// 010-1234-5678 형태로 자동 하이픈을 끼워 넣는 포매터.
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 7) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

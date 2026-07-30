import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/api/auth_api.dart';
import '../auth/login_screen.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_otp_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 전화번호 입력. 010 / 011 등 한국식 11자리. 다른 기기에서도 다시 받을 수 있게
/// SMS 인증을 사용한다는 안내를 함께 보여준다.
///
/// 번호를 다 입력하면 곧바로 서버에 가입 가능 여부를 물어(`check-phone`) 중복 가입을
/// 이 화면에서 알린다. 예전에는 마지막 단계(자기소개)의 register 응답으로만 알 수 있었다.
class SignupPhoneScreen extends StatefulWidget {
  const SignupPhoneScreen({
    super.key,
    required this.session,
    this.checkAvailability,
  });
  final SignupSession session;

  /// 번호 중복 확인 함수. 미주입 시 실제 API(`checkPhone`)를 쓴다(테스트 주입용).
  final Future<PhoneAvailability> Function(String phone)? checkAvailability;

  @override
  State<SignupPhoneScreen> createState() => _SignupPhoneScreenState();
}

class _SignupPhoneScreenState extends State<SignupPhoneScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.session.phone);
  final FocusNode _focus = FocusNode();

  /// 입력 중 매 글자마다 서버를 찌르지 않도록 잠깐 기다린다.
  static const _debounceDelay = Duration(milliseconds: 400);
  Timer? _debounce;

  /// 확인이 끝난 번호와 그 결과(번호가 바뀌면 함께 버린다).
  String? _checkedPhone;
  PhoneAvailability? _availability;
  bool _checking = false;

  /// 마지막으로 시작한 확인 요청 번호. 늦게 도착한 응답을 무시하는 데 쓴다.
  int _checkSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    // 뒤로 왔을 때 이미 채워져 있으면 바로 확인한다.
    if (_valid) _scheduleCheck();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

  /// 확인 결과가 "가입 불가"인 번호. 이 경우 진행을 막는다.
  PhoneAvailability? get _blocked {
    final a = _availability;
    if (a == null || a.available || _checkedPhone != _digits) return null;
    return a;
  }

  /// 확인이 끝나 "가입 가능"으로 나온 번호인지.
  bool get _confirmedFree {
    final a = _availability;
    return a != null && a.available && _checkedPhone == _digits;
  }

  bool get _canSubmit =>
      _valid && !_sending && !_checking && _blocked == null;

  void _onChanged() {
    _debounce?.cancel();
    if (_checkedPhone != _digits) {
      // 번호가 바뀌면 이전 결과는 무효.
      _availability = null;
      _checkedPhone = null;
    }
    setState(() {});
    if (_valid) _scheduleCheck();
  }

  void _scheduleCheck() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _check);
  }

  Future<void> _check() async {
    final phone = _digits;
    if (!_valid) return;
    final seq = ++_checkSeq;
    setState(() => _checking = true);
    try {
      final check = widget.checkAvailability ?? checkPhone;
      final result = await check(phone);
      if (!mounted || seq != _checkSeq) return; // 그새 번호가 바뀌었으면 버린다
      setState(() {
        _availability = result;
        _checkedPhone = phone;
      });
    } catch (_) {
      // 확인 실패(네트워크 등)는 조용히 넘긴다 — 인증번호 발송 단계에서 서버가 다시 막는다.
    } finally {
      if (mounted && seq == _checkSeq) setState(() => _checking = false);
    }
  }

  /// 이미 가입된 번호일 때: 가입 플로우를 닫고 로그인 화면으로 보낸다.
  void _goLogin() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.settings.name != kSignupRouteName);
    navigator.push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _next() async {
    if (_blocked != null) return;
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
      onPrimary: _canSubmit ? _next : null,
      primaryLoading: _sending,
      bottomHint: const Text(
          'SKT · KT · LGU+ 알뜰폰 모두 가능해요.\n해외 번호는 아직 지원하지 않아요.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: '휴대폰 번호',
            hasError: _blocked != null,
            child: TextField(
              key: const Key('signup-phone-field'),
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _PhoneFormatter(),
              ],
              onChanged: (_) => _onChanged(),
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
          const SizedBox(height: 12),
          // 번호 확인 결과 → 없을 때만 안내 카드를 보여 준다(둘이 겹치지 않게).
          _status() ??
              const _InfoCard(
                icon: Icons.shield_rounded,
                text:
                    '입력한 번호는 암호화되어 저장되며, 다른 사용자에게 공개되지 않아요.',
              ),
        ],
      ),
    );
  }

  /// 번호 확인 진행/결과 표시. 보여줄 게 없으면 null.
  Widget? _status() {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textTertiary),
              ),
            ),
            SizedBox(width: 8),
            Text('번호를 확인하는 중이에요',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                )),
          ],
        ),
      );
    }

    final blocked = _blocked;
    if (blocked != null) {
      return Container(
        key: const Key('signup-phone-blocked'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.bgWarning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: AppColors.textWarning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    blocked.isRegistered
                        ? '${blocked.detail}\n로그인하거나 다른 번호로 가입해 주세요.'
                        : blocked.detail,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.textWarning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (blocked.isRegistered)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('signup-phone-go-login'),
                  onPressed: _goLogin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.coral,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('이 번호로 로그인하기'),
                ),
              ),
          ],
        ),
      );
    }

    if (_confirmedFree) {
      return const Padding(
        key: Key('signup-phone-available'),
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.textSuccess),
            SizedBox(width: 8),
            Text('가입할 수 있는 번호예요',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSuccess,
                )),
          ],
        ),
      );
    }
    return null;
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.hasError = false,
  });
  final String label;
  final Widget child;
  final bool hasError;

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
              color: hasError
                  ? AppColors.textWarning
                  : AppColors.borderTertiary,
              width: hasError ? 1.0 : 0.6,
            ),
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

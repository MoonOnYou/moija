import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_nickname_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 로그인 비밀번호 설정. 영문+숫자 포함 8자 이상, 확인 입력 일치.
class SignupPasswordScreen extends StatefulWidget {
  const SignupPasswordScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupPasswordScreen> createState() => _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends State<SignupPasswordScreen> {
  late final TextEditingController _pw =
      TextEditingController(text: widget.session.password);
  final TextEditingController _confirm = TextEditingController();
  final FocusNode _pwFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscurePw = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pwFocus.requestFocus());
  }

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    _pwFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String get _pwText => _pw.text;
  bool get _lengthOk => _pwText.length >= 8;
  bool get _comboOk =>
      RegExp(r'[A-Za-z]').hasMatch(_pwText) &&
      RegExp(r'[0-9]').hasMatch(_pwText);
  bool get _pwValid => _lengthOk && _comboOk;
  bool get _confirmMatch =>
      _confirm.text.isNotEmpty && _confirm.text == _pwText;
  bool get _valid => _pwValid && _confirmMatch;

  void _next() {
    widget.session.password = _pwText;
    Navigator.of(context).push(signupRoute(
      (_) => SignupNicknameScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final confirmError = _confirm.text.isNotEmpty && !_confirmMatch;
    return SignupScaffold(
      step: 4,
      totalSteps: 9,
      title: '비밀번호를 설정해 주세요',
      subtitle: '다음에 로그인할 때 사용할 비밀번호예요.',
      primaryLabel: '다음',
      onPrimary: _valid ? _next : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PasswordField(
            controller: _pw,
            focusNode: _pwFocus,
            hint: '비밀번호 입력',
            obscure: _obscurePw,
            onToggle: () => setState(() => _obscurePw = !_obscurePw),
            onChanged: () => setState(() {}),
            onSubmitted: () => _confirmFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RuleChip(label: '8자 이상', ok: _lengthOk),
              const SizedBox(width: 8),
              _RuleChip(label: '영문·숫자 포함', ok: _comboOk),
            ],
          ),
          const SizedBox(height: 22),
          const Text('비밀번호 확인',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _PasswordField(
            controller: _confirm,
            focusNode: _confirmFocus,
            hint: '비밀번호 다시 입력',
            obscure: _obscureConfirm,
            error: confirmError,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onChanged: () => setState(() {}),
            onSubmitted: _valid ? _next : null,
          ),
          const SizedBox(height: 10),
          if (confirmError)
            Row(children: const [
              Icon(Icons.error_outline_rounded,
                  size: 14, color: AppColors.textDanger),
              SizedBox(width: 4),
              Text('비밀번호가 일치하지 않아요',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDanger)),
            ])
          else if (_confirmMatch)
            Row(children: const [
              Icon(Icons.check_circle_rounded,
                  size: 14, color: AppColors.textSuccess),
              SizedBox(width: 4),
              Text('비밀번호가 일치해요',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSuccess)),
            ]),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.onSubmitted,
    this.error = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final VoidCallback? onSubmitted;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error
              ? AppColors.textDanger
              : (focusNode.hasFocus
                  ? AppColors.coral
                  : AppColors.borderTertiary),
          width: error ? 1.0 : 0.6,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmitted?.call(),
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary),
              ),
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 15,
          color: ok ? AppColors.textSuccess : AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.textSuccess : AppColors.textTertiary,
            )),
      ],
    );
  }
}

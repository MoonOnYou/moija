import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_profile_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 닉네임 입력. 2~12자, 한글/영문/숫자/일부 기호 허용.
class SignupNicknameScreen extends StatefulWidget {
  const SignupNicknameScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupNicknameScreen> createState() => _SignupNicknameScreenState();
}

class _SignupNicknameScreenState extends State<SignupNicknameScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.session.nickname);
  final FocusNode _focus = FocusNode();

  static const _min = 2;
  static const _max = 12;
  static final _allowed = RegExp(r'^[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9._\- ]+$');

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

  String get _value => _controller.text.trim();

  String? get _error {
    if (_value.isEmpty) return null;
    if (_value.length < _min) return '$_min자 이상 입력해 주세요';
    if (_value.length > _max) return '$_max자 이내로 입력해 주세요';
    if (!_allowed.hasMatch(_value)) {
      return '한글·영문·숫자와 . _ - 만 사용할 수 있어요';
    }
    return null;
  }

  bool get _valid =>
      _value.length >= _min && _value.length <= _max && _allowed.hasMatch(_value);

  void _next() {
    widget.session.nickname = _value;
    Navigator.of(context).push(signupRoute(
      (_) => SignupProfileScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final err = _error;
    return SignupScaffold(
      step: 5,
      totalSteps: 8,
      title: '닉네임을 정해 주세요',
      subtitle: '모임에서 다른 사람들에게 보일 이름이에요.\n나중에 프로필에서 바꿀 수 있어요.',
      primaryLabel: '다음',
      onPrimary: _valid ? _next : null,
      bottomHint: const Text('실명이나 연락처는 닉네임에 쓰지 말아 주세요.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: err != null
                    ? AppColors.textDanger
                    : (_focus.hasFocus
                        ? AppColors.coral
                        : AppColors.borderTertiary),
                width: err != null ? 1.0 : 0.6,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    maxLength: _max,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_max),
                    ],
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      counterText: '',
                      border: InputBorder.none,
                      hintText: '예) 모이자',
                      hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary),
                    ),
                  ),
                ),
                Text('${_value.length}/$_max',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (err != null)
            Row(children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: AppColors.textDanger),
              const SizedBox(width: 4),
              Text(err,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDanger)),
            ])
          else
            const Text(
              '한글·영문·숫자 2~12자, 기호는 . _ - 만 사용할 수 있어요.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textTertiary, height: 1.5),
            ),
          const SizedBox(height: 26),
          const _PreviewLabel('미리보기'),
          const SizedBox(height: 8),
          _NicknamePreview(nickname: _value.isEmpty ? '모이자' : _value),
        ],
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ));
  }
}

class _NicknamePreview extends StatelessWidget {
  const _NicknamePreview({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.bgCoral,
            child: Text(
              nickname.isEmpty ? '?' : nickname.characters.first,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coral),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text(
                  '"오늘 같이 놀 사람!" 한 마디로 모임을 시작해요',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

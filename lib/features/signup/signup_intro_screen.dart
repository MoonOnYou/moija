import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'signup_complete_screen.dart';
import 'signup_flow.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 자기소개 입력(선택). 가입의 마지막 데이터 단계로, 비워두고 건너뛸 수 있다.
/// 입력값은 모임에서 다른 사람에게 보이는 한 줄 소개로 쓰인다.
class SignupIntroScreen extends StatefulWidget {
  const SignupIntroScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupIntroScreen> createState() => _SignupIntroScreenState();
}

class _SignupIntroScreenState extends State<SignupIntroScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.session.intro);
  final FocusNode _focus = FocusNode();

  static const _max = 150;

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
  bool get _hasText => _value.isNotEmpty;

  void _next() {
    widget.session.intro = _value;
    Navigator.of(context).pushReplacement(signupRoute(
      (_) => SignupCompleteScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      step: 9,
      totalSteps: 9,
      title: '마지막으로, 나를 소개해 주세요',
      subtitle: '모임에서 다른 사람에게 보여요. 비워둬도 괜찮아요.',
      // 선택 단계라 항상 진행 가능. 비어 있으면 "건너뛰기"로 안내한다.
      primaryLabel: _hasText ? '완료' : '건너뛰기',
      onPrimary: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focus.hasFocus
                    ? AppColors.coral
                    : AppColors.borderTertiary,
                width: _focus.hasFocus ? 1.0 : 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  maxLines: 5,
                  maxLength: _max,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_max),
                  ],
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '예) 함께 한잔 좋아하고, 처음 만나는 사람 환영해요 :)',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${_value.length}/$_max',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.bgMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: AppColors.textSuccess),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '좋아하는 모임, 분위기, 한마디를 적으면 모임에서 더 빨리 친해져요.\n나중에 프로필에서 바꿀 수 있어요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.textSuccess,
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

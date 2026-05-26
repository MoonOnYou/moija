import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 단일 텍스트(닉네임 또는 자기소개) 편집 풀스크린.
/// 저장 시 입력값을 pop으로 반환, 취소는 null.
class EditTextScreen extends StatefulWidget {
  const EditTextScreen({
    super.key,
    required this.title,
    required this.initial,
    required this.hint,
    this.maxLength,
    this.multiline = false,
  });

  final String title;
  final String initial;
  final String hint;
  final int? maxLength;
  final bool multiline;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initial,
    required String hint,
    int? maxLength,
    bool multiline = false,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditTextScreen(
          title: title,
          initial: initial,
          hint: hint,
          maxLength: maxLength,
          multiline: multiline,
        ),
      ),
    );
  }

  @override
  State<EditTextScreen> createState() => _EditTextScreenState();
}

class _EditTextScreenState extends State<EditTextScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _changed => _controller.text != widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _changed
                ? () => Navigator.of(context).pop(_controller.text.trim())
                : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.coral,
              disabledForegroundColor: AppColors.textTertiary,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: (_) => setState(() {}),
          minLines: widget.multiline ? 5 : 1,
          maxLines: widget.multiline ? 12 : 1,
          maxLength: widget.maxLength,
          keyboardType: widget.multiline
              ? TextInputType.multiline
              : TextInputType.text,
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
                fontSize: 15, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.borderTertiary, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.textPrimary, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

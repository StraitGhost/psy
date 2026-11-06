import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'question_card.dart';

class FillBlankWidget extends StatefulWidget {
  const FillBlankWidget({
    super.key,
    required this.sentence,
    this.checked = false,
    this.isCorrect,
    this.onChanged,
    this.placeholder = 'Escribe la respuesta...',
  });

  final String sentence;
  final bool checked;
  final bool? isCorrect;
  final ValueChanged<String>? onChanged;
  final String placeholder;

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _resultColor {
    if (!widget.checked) return AppColors.primary;
    return widget.isCorrect == true ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.sentence.split('___');
    final before = parts.first;
    final after = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final text = _controller.text.trim();

    const sentenceStyle = TextStyle(
      fontSize: 16,
      height: 1.9,
    );

    return QuestionCard(
      glow: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              style: sentenceStyle.copyWith(color: AppColors.textPrimary),
              children: [
                TextSpan(text: before),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 110),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _resultColor, width: 2),
                      ),
                    ),
                    child: Text(
                      text.isEmpty ? ' ' : text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _resultColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: after),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: _resultColor.withValues(alpha: 0.35), blurRadius: 16),
              ],
            ),
            child: TextField(
              controller: _controller,
              enabled: !widget.checked,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              cursorColor: AppColors.info,
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(value);
              },
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.edit_outlined, color: _resultColor),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                enabledBorder: _border(AppColors.primary.withValues(alpha: 0.85), width: 1.6),
                focusedBorder: _border(AppColors.info, width: 2),
                disabledBorder: _border(_resultColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.4}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum _OptionState { idle, selected, correct, wrong, dimmed }

class MultipleChoiceWidget extends StatelessWidget {
  const MultipleChoiceWidget({
    super.key,
    required this.options,
    required this.onSelected,
    this.selectedIndex,
    this.correctIndex,
    this.locked = false,
  });

  final List<String> options;
  final ValueChanged<int> onSelected;
  final int? selectedIndex;
  final int? correctIndex;
  final bool locked;

  _OptionState _stateFor(int i) {
    if (locked && correctIndex != null) {
      if (i == correctIndex) return _OptionState.correct;
      if (i == selectedIndex) return _OptionState.wrong;
      return _OptionState.dimmed;
    }
    return i == selectedIndex ? _OptionState.selected : _OptionState.idle;
  }

  Widget _tile(int i, bool big) => _OptionTile(
        letter: String.fromCharCode(65 + i),
        text: options[i],
        state: _stateFor(i),
        big: big,
        onTap: locked ? null : () => onSelected(i),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final big = c.maxWidth >= 480;
        final twoCols = c.maxWidth >= 900;
        final gap = big ? 16.0 : 10.0;

        if (!twoCols) {
          return Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                SizedBox(width: double.infinity, child: _tile(i, big)),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < options.length; i += 2) {
          if (i > 0) rows.add(SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _tile(i, big)),
                  SizedBox(width: gap),
                  Expanded(
                    child: i + 1 < options.length
                        ? _tile(i + 1, big)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.big,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.border.withValues(alpha: 0.6);
    Color? badge;
    IconData? badgeIcon;
    var borderWidth = 1.2;

    switch (state) {
      case _OptionState.selected:
        border = AppColors.primary;
        badge = AppColors.primary;
        badgeIcon = Icons.check_rounded;
        borderWidth = 2;
        break;
      case _OptionState.correct:
        border = AppColors.success;
        badge = AppColors.success;
        badgeIcon = Icons.check_rounded;
        borderWidth = 2;
        break;
      case _OptionState.wrong:
        border = AppColors.error;
        badge = AppColors.error;
        badgeIcon = Icons.close_rounded;
        borderWidth = 2;
        break;
      case _OptionState.dimmed:
      case _OptionState.idle:
        break;
    }

    final letterSize = big ? 48.0 : 40.0;

    return AnimatedOpacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1,
      duration: const Duration(milliseconds: 200),
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(minHeight: big ? 84 : 0),
            padding: EdgeInsets.symmetric(
              horizontal: big ? 20 : 14,
              vertical: big ? 18 : 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(big ? 20 : 16),
              border: Border.all(color: border, width: borderWidth),
              boxShadow: badge != null
                  ? [BoxShadow(color: badge.withValues(alpha: 0.35), blurRadius: 18)]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: letterSize,
                  height: letterSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: big ? 19 : 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: big ? 18 : 14),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: big ? 17 : 14,
                      height: 1.4,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: badge),
                    child: Icon(badgeIcon, size: 20, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'question_card.dart';

class MatchPair {
  const MatchPair(this.term, this.description);
  final String term;
  final String description;
}

class MatchingWidget extends StatefulWidget {
  const MatchingWidget({
    super.key,
    required this.pairs,
    this.leftTitle = 'Términos',
    this.rightTitle = 'Descripciones',
    this.checked = false,
    this.onChanged,
  });

  final List<MatchPair> pairs;
  final String leftTitle;
  final String rightTitle;
  final bool checked;
  final void Function(bool complete, bool correct)? onChanged;

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> {
  late final List<int> _order;
  final Map<int, int> _placed = {};

  @override
  void initState() {
    super.initState();
    _order = List<int>.generate(widget.pairs.length, (i) => i)..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  void _notify() {
    final complete = _placed.length == widget.pairs.length;
    final correct = complete && _placed.entries.every((e) => _order[e.key] == e.value);
    widget.onChanged?.call(complete, correct);
  }

  void _place(int row, int term) {
    if (widget.checked) return;
    setState(() {
      _placed.removeWhere((_, t) => t == term);
      _placed[row] = term;
    });
    _notify();
  }

  void _remove(int row) {
    if (widget.checked) return;
    setState(() => _placed.remove(row));
    _notify();
  }

  void _placeInFirstEmpty(int term) {
    for (var row = 0; row < _order.length; row++) {
      if (!_placed.containsKey(row)) {
        _place(row, term);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final used = _placed.values.toSet();
    final available = [
      for (var i = 0; i < widget.pairs.length; i++)
        if (!used.contains(i)) i,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _Panel(
            title: widget.leftTitle,
            children: [
              for (final t in available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _draggableTerm(t),
                ),
              if (available.isEmpty)
  Padding(  // ← Sin 'const'
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'Todos colocados',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
  ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: _Panel(
            title: widget.rightTitle,
            children: [
              for (var row = 0; row < _order.length; row++) _slot(row),
            ],
          ),
        ),
      ],
    );
  }

  Widget _draggableTerm(int t) {
    final label = widget.pairs[t].term;
    return Draggable<int>(
      data: t,
      maxSimultaneousDrags: widget.checked ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: _TermChip(label: label, lifted: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _TermChip(label: label)),
      child: GestureDetector(
        onTap: () => _placeInFirstEmpty(t),
        child: _TermChip(label: label),
      ),
    );
  }

  Widget _slot(int row) {
    final description = widget.pairs[_order[row]].description;

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !widget.checked,
      onAcceptWithDetails: (details) => _place(row, details.data),
      builder: (context, candidates, rejected) {
        final term = _placed[row];
        final hovering = candidates.isNotEmpty;

        var border = AppColors.border.withValues(alpha: 0.6);
        if (widget.checked && term != null) {
          border = _order[row] == term ? AppColors.success : AppColors.error;
        } else if (hovering) {
          border = AppColors.info;
        } else if (term != null) {
          border = AppColors.primary.withValues(alpha: 0.8);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border,
              width: (widget.checked || hovering) ? 1.8 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (term == null) ...[
                CustomPaint(
                  painter: _DashedRRectPainter(
                    color: hovering ? AppColors.info : AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: hovering ? AppColors.info : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (term != null) ...[
                      GestureDetector(
                        onTap: () => _remove(row),
                        child: _TermChip(
                          label: widget.pairs[term].term,
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    if (widget.checked && term != null && _order[row] != term) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Correcto: ${widget.pairs[_order[row]].term}',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return QuestionCard(
      radius: 14,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _TermChip extends StatelessWidget {
  const _TermChip({required this.label, this.lifted = false, this.compact = false});
  final String label;
  final bool lifted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 7 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondary, AppColors.primary]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.9)),
        boxShadow: lifted ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 18)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded, size: 14, color: AppColors.textOnPrimary.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) => oldDelegate.color != color;
}
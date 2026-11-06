import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OrderingWidget extends StatefulWidget {
  final List<String> items;
  final List<String> correctOrder;
  final bool checked;
  final Function(bool correct, List<int> wrongPositions) onChanged;

  const OrderingWidget({
    super.key,
    required this.items,
    required this.correctOrder,
    required this.checked,
    required this.onChanged,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  late List<String> _currentItems;
  List<int> _wrongPositions = [];

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(OrderingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _currentItems = List.from(widget.items);
      _wrongPositions = [];
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    if (widget.checked) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _currentItems.removeAt(oldIndex);
    _currentItems.insert(newIndex, item);
    _checkCorrectness();
  }

  void _checkCorrectness() {
    List<int> wrong = [];
    for (int i = 0; i < widget.correctOrder.length; i++) {
      if (i < _currentItems.length && _currentItems[i] != widget.correctOrder[i]) {
        wrong.add(i);
      }
    }
    setState(() {
      _wrongPositions = wrong;
    });
    final isCorrect = _wrongPositions.isEmpty;
    widget.onChanged(isCorrect, _wrongPositions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentItems.length,
          onReorder: (int oldIndex, int newIndex) {
            if (!widget.checked) {
              _reorder(oldIndex, newIndex);
            }
          },
          itemBuilder: (context, index) {
            final isWrong = widget.checked && _wrongPositions.contains(index);
            final isCorrect = widget.checked && !_wrongPositions.contains(index);

            return Container(
              key: ValueKey(_currentItems[index]),
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: widget.checked
                    ? (isWrong
                        ? AppColors.error.withValues(alpha: 0.2)
                        : (isCorrect ? AppColors.success.withValues(alpha: 0.2) : AppColors.surface))
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.checked
                      ? (isWrong
                          ? AppColors.error
                          : (isCorrect ? AppColors.success : AppColors.border))
                      : AppColors.border,
                  width: widget.checked ? 2 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.checked
                        ? (isWrong
                            ? AppColors.error.withValues(alpha: 0.3)
                            : (isCorrect ? AppColors.success.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.16)))
                        : AppColors.primary.withValues(alpha: 0.16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: widget.checked
                            ? (isWrong
                                ? AppColors.error
                                : (isCorrect ? AppColors.success : AppColors.primary.withValues(alpha: 0.7)))
                            : AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  _currentItems[index],
                  style: TextStyle(
                    color: widget.checked
                        ? (isWrong
                            ? AppColors.error
                            : (isCorrect ? AppColors.success : AppColors.textPrimary))
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: widget.checked
                    ? Icon(
                        isCorrect ? Icons.check_circle : Icons.error,
                        color: isCorrect ? AppColors.success : AppColors.error,
                        size: 20,
                      )
                    : Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
              ),
            );
          },
        ),
        
        // ✅ PANEL DE ORDEN CORRECTO ACTUALIZADO CON AppColors.primary
        if (widget.checked && _wrongPositions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1), // ✅ Cambiado de info a primary
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)), // ✅ Cambiado de info a primary
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orden correcto:',
                  style: TextStyle(
                    color: AppColors.primary, // ✅ Cambiado de info a primary
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < widget.correctOrder.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2), // ✅ Cambiado de info a primary
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: AppColors.primary, // ✅ Cambiado de info a primary
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.correctOrder[i],
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
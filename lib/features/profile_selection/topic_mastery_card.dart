// lib/features/profile_selection/topic_mastery_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:psy/features/profile_selection/profile_panel.dart';

import '../../core/theme/app_colors.dart';
import 'profile_data.dart';

class TopicMasteryCard extends StatelessWidget {
  final UserStats stats;

  const TopicMasteryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return ProfilePanel(
      icon: Icons.hub_rounded,
      title: 'Dominio por tema',
      subtitle: 'Tu desempeño en cada área del conocimiento',
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 700;

          final radar = AspectRatio(
            aspectRatio: wide ? 1.1 : 1.0,
            child: CustomPaint(
              painter: _RadarPainter(
                labels: [for (final t in topics) t.name],
                values: [for (final t in topics) (stats.mastery[t.id] ?? 0) / 100],
                grid: AppColors.border,
                fill: AppColors.primary.withValues(alpha: 0.25),
                line: AppColors.primary,
                labelColor: AppColors.textPrimary,
                pctColor: AppColors.primary,
              ),
            ),
          );
          final list = _list();

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: radar),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: list),
              ],
            );
          }
          return Column(children: [radar, const SizedBox(height: 12), list]);
        },
      ),
    );
  }

  Widget _list() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          for (var i = 0; i < topics.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.borderLight),
            _row(topics[i], stats.mastery[topics[i].id] ?? 0),
          ],
        ],
      ),
    );
  }

  Widget _row(Topic t, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          // El icono mantiene su color único del tema (profile_data.dart)
          Icon(t.icon, color: t.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              t.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${pct.round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: pct > 0 ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Radar
// ─────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color grid;
  final Color fill;
  final Color line;
  final Color labelColor;
  final Color pctColor;

  _RadarPainter({
    required this.labels,
    required this.values,
    required this.grid,
    required this.fill,
    required this.line,
    required this.labelColor,
    required this.pctColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width / 2 - 70, size.height / 2 - 36);
    if (radius <= 0) return;

    Offset pt(int i, double f) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return center + Offset(math.cos(a), math.sin(a)) * radius * f;
    }

    Path polygon(double f) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final o = pt(i, f);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid;

    for (var r = 1; r <= 5; r++) {
      canvas.drawPath(polygon(r / 5), gridPaint);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, pt(i, 1), gridPaint);
    }

    final data = Path();
    for (var i = 0; i < n; i++) {
      final o = pt(i, values[i].clamp(0.0, 1.0));
      i == 0 ? data.moveTo(o.dx, o.dy) : data.lineTo(o.dx, o.dy);
    }
    data.close();

    canvas.drawPath(data, Paint()..color = fill);

    canvas.drawPath(
      data,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );

    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
          pt(i, values[i].clamp(0.0, 1.0)), 4.5, Paint()..color = line);
    }

    // Etiquetas
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final dir = Offset(math.cos(a), math.sin(a));
      final tp = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(children: [
          TextSpan(
            text: labels[i],
            style: TextStyle(
                fontSize: 11.5,
                color: labelColor,
                fontWeight: FontWeight.w500,
                height: 1.25),
          ),
          TextSpan(
            text: '\n${(values[i] * 100).round()}%',
            style: TextStyle(
                fontSize: 11.5,
                color: pctColor,
                fontWeight: FontWeight.w800,
                height: 1.25),
          ),
        ]),
      )..layout();

      final c = center + dir * (radius + 30);
      final shift = Offset(dir.dx * tp.width * 0.18, dir.dy * tp.height * 0.18);
      tp.paint(canvas, c + shift - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values.toString() != values.toString() ||
      old.line != line ||
      old.grid != grid ||
      old.labelColor != labelColor;
}
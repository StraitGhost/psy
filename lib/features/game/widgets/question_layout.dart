import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Contenedor de la pantalla de pregunta, a todo el ancho:
///
///   header + barra de progreso
///   ── pregunta (arriba, visible) ──
///   ── respuestas ──
///   ── feedback ──
///   footer (pista + botón)
///
/// En pantallas anchas aumenta márgenes y espacios; [questionBuilder]
/// recibe `wide` para que el hero use texto más grande.
class QuestionLayout extends StatelessWidget {
  const QuestionLayout({
    super.key,
    required this.header,
    required this.questionBuilder,
    required this.answers,
    required this.footer,
    this.feedback,
    this.progress = 0,
    this.wideBreakpoint = 900,
    this.controller,
    this.maxContentWidth = 1600,
  });

  final Widget header;
  final Widget Function(bool wide) questionBuilder;
  final Widget answers;
  final Widget? feedback;
  final Widget footer;

  /// 0..1
  final double progress;
  final double wideBreakpoint;

  /// Controller del scroll (para el auto-scroll al responder).
  final ScrollController? controller;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= wideBreakpoint;
              final hPad = c.maxWidth >= 1400 ? 72.0 : (wide ? 40.0 : 16.0);
              final gap = wide ? 22.0 : 14.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 10),
                    _ProgressBar(value: progress),
                    SizedBox(height: gap),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            questionBuilder(wide),
                            SizedBox(height: gap),
                            answers,
                            if (feedback != null) ...[
                              SizedBox(height: gap),
                              feedback!,
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    footer,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Barra de progreso a todo el ancho.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, c) => AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          width: c.maxWidth * value.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Botón en forma de píldora. Con `onPressed: null` se ve apagado.
///
/// Atajos: `NextButtonWidget.next(...)` → "Siguiente →"
///         `NextButtonWidget.verify(...)` → "✓ Verificar"
class NextButtonWidget extends StatelessWidget {
  const NextButtonWidget({
    super.key,
    required this.label,
    required this.icon,
    this.iconLeading = false,
    this.onPressed,
  });

  const NextButtonWidget.next({super.key, this.onPressed})
      : label = 'Siguiente',
        icon = Icons.arrow_forward_rounded,
        iconLeading = false;

  const NextButtonWidget.verify({super.key, this.onPressed})
      : label = 'Verificar',
        icon = Icons.check_rounded,
        iconLeading = true;

  final String label;
  final IconData icon;
  final bool iconLeading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    
    // ✅ Colores de texto e icono adaptativos
    final iconWidget = Icon(icon, size: 18, color: AppColors.textOnPrimary);
    final text = Text(
      label,
      style: TextStyle(
        color: AppColors.textOnPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              // ✅ Gradiente dinámico con los colores del agente
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(24),
              // ✅ Borde y sombra que brillan con el color primario del agente
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5), 
                width: 1.2
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35), 
                        blurRadius: 14
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: iconLeading
                  ? [iconWidget, const SizedBox(width: 8), text]
                  : [text, const SizedBox(width: 8), iconWidget],
            ),
          ),
        ),
      ),
    );
  }
}
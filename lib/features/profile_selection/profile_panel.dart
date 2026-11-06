// lib/features/profile/profile_panel.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tarjeta con degradado, borde de color del tema y encabezado opcional.
/// Todas las secciones del perfil usan este mismo contenedor.
class ProfilePanel extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onHeaderTap;
  final bool collapsed;
  final Widget child;

  const ProfilePanel({
    super.key,
    required this.child,
    this.icon,
    this.title,
    this.subtitle,
    this.trailing,
    this.onHeaderTap,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.withValues(alpha: 0.16), AppColors.surface],
        ),
        border: Border.all(color: p.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            InkWell(
              onTap: onHeaderTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: p, size: 22),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (!collapsed) ...[
            if (title != null) const SizedBox(height: 14),
            child,
          ],
        ],
      ),
    );
  }
}
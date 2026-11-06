// lib/features/home/widgets/home_footer.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        // ✅ CORREGIDO: Se quitó 'const' de Border/BorderSide porque AppColors.border es dinámico
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      // ✅ CORREGIDO: Se quitó 'const' del Row porque sus hijos usan colores dinámicos
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PsyCase',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            'v1.0.0',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
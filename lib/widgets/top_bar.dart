// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../features/profile_selection/profile_settings_screen.dart';
import '../features/profile_selection/profile_selection_screen.dart';
import '../../features/auth/login_screen.dart';
import '../models/profile.dart';
import '../services/profile_data_service.dart';

class TopBar extends StatelessWidget {
  final UserProfile profile;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const TopBar({
    super.key,
    required this.profile,
    required this.searchController,
    required this.onSearchChanged,
  });

  static int _safeInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // OPCIÓN 1: Ver Perfil y Configuración
              ListTile(
                leading: Icon(Icons.person_outline, color: AppColors.primary),
                title: Text(
                  'Ver Perfil y Configuración',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileSettingsScreen(profile: profile)),
                  );
                },
              ),

              const Divider(height: 1),

              // OPCIÓN 2: Cambiar de Perfil (sin cerrar sesión)
              ListTile(
                leading: Icon(Icons.swap_horiz_rounded, color: AppColors.info),
                title: Text(
                  'Cambiar de Perfil',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileSelectionScreen()),
                    (route) => false,
                  );
                },
              ),

              const Divider(height: 1),

              // OPCIÓN 3: Cerrar Sesión
              ListTile(
                leading: Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _freezeCounter() {
    final ref = ProfileDataService.refFor(profile.id);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref?.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? <String, dynamic>{};
        final freezes = _safeInt(data['streakFreezes']);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ac_unit, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                '$freezes',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Barra de búsqueda
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar conceptos, casos, síndromes...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Contador de congeladores de racha (del perfil)
        _freezeCounter(),
        const SizedBox(width: 12),

        // Perfil de usuario
        GestureDetector(
          onTap: () => _showProfileMenu(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      profile.name.isEmpty
                          ? '?'
                          : profile.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(profile.career ?? 'Estudiante',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
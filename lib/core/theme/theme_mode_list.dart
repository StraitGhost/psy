  // lib/core/theme/theme_mode_list.dart
  import 'package:flutter/material.dart';
  import 'agent_theme.dart';
  import 'app_colors.dart';
  import 'theme_preferences.dart';

  class ThemeModeList extends StatelessWidget {
    const ThemeModeList({super.key});

    // ✅ CORREGIDO: Ahora guarda la preferencia en el dispositivo
    Future<void> _select(String id) async {
      await ThemePreferences.instance.setThemeMode(id);
    }

    @override
    Widget build(BuildContext context) {
      return ValueListenableBuilder<String>(
        valueListenable: ThemePreferences.instance.themeMode,
        builder: (context, mode, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header('Apariencia'),
              _ModeTile(
                title: 'Sistema',
                subtitle: 'Sigue el tema de tu dispositivo',
                selected: mode == 'system',
                leading: const _IconBadge(Icons.brightness_auto_rounded),
                onTap: () => _select('system'),
              ),
              _ModeTile(
                title: 'Claro',
                selected: mode == 'light',
                leading: const _IconBadge(Icons.light_mode_rounded),
                onTap: () => _select('light'),
              ),
              _ModeTile(
                title: 'Oscuro',
                selected: mode == 'dark',
                leading: const _IconBadge(Icons.dark_mode_rounded),
                onTap: () => _select('dark'),
              ),
              const SizedBox(height: 18),
              const _Header('Temas de Agentes'),
              for (final p in agentPalettes)
                _ModeTile(
                  title: p.name,
                  selected: mode == '$kAgentPrefix${p.id}',
                  accent: p.primary,
                  leading: _GradientBadge(p),
                  onTap: () => _select('$kAgentPrefix${p.id}'),
                ),
            ],
          );
        },
      );
    }
  }

  class _Header extends StatelessWidget {
    final String text;
    const _Header(this.text);

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
  }

  class _IconBadge extends StatelessWidget {
    final IconData icon;
    const _IconBadge(this.icon);

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      );
    }
  }

  class _GradientBadge extends StatelessWidget {
    final AgentPalette p;
    const _GradientBadge(this.p);

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.primary, p.secondary],
          ),
          border: Border.all(color: p.background, width: 2),
        ),
      );
    }
  }

  class _ModeTile extends StatelessWidget {
    final String title;
    final String? subtitle;
    final bool selected;
    final Widget leading;
    final Color? accent;
    final VoidCallback onTap;

    const _ModeTile({
      required this.title,
      required this.selected,
      required this.leading,
      required this.onTap,
      this.subtitle,
      this.accent,
    });

    @override
    Widget build(BuildContext context) {
      final c = accent ?? AppColors.primary;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? c.withValues(alpha: 0.10) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? c : AppColors.borderLight,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: selected ? c : AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
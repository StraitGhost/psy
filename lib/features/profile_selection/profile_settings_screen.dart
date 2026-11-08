// lib/features/profile/profile_settings_screen.dart
import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/agent_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_preferences.dart';
import '../../models/profile.dart';
import '../../models/avatar_model.dart';
import '../../services/avatar_service.dart';
import '../../services/achievement_service.dart';
import '../../services/profile_service.dart';
import '../../services/streak_service.dart';
import '../achievements/achievements_screen.dart';
import '../achievements/models/achievement_model.dart';
import '../profile_selection/profile_selection_screen.dart';
import '../auth/login_screen.dart';

int _asInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class ProfileSettingsScreen extends StatefulWidget {
  final UserProfile profile;

  /// Valores iniciales de respaldo; los datos reales se cargan de Firestore.
  final int level;
  final int streakDays;
  final int points; // ya no se muestra (ahora se muestran gemas)

  const ProfileSettingsScreen({
    super.key,
    required this.profile,
    this.level = 0,
    this.streakDays = 0,
    this.points = 0,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ScrollController _agentsScroll = ScrollController();
  final ScrollController _achScroll = ScrollController();
  bool _appearanceExpanded = true;

  // Datos dinámicos desde Firebase
  int _gems = 0;
  late int _streakDays;
  String? _avatarRaw;
  int? _avatarIndex;
  List<AvatarModel> _avatars = [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  // Valores editados por el usuario. Mientras sean null se usa lo que trae
  // el perfil (widget.profile), así siempre se cargan los datos reales.
  String? _career;
  String? _objective;
  String? _experienceLevel;
  String? _personalMessage;

  String? get _careerValue => _career ?? widget.profile.career;
  String? get _objectiveValue => _objective ?? widget.profile.objective;
  String? get _experienceValue =>
      _experienceLevel ?? widget.profile.experienceLevel;
  String? get _messageValue =>
      _personalMessage ?? widget.profile.personalMessage;

  /// Agrega el valor actual a las opciones si no está en la lista,
  /// para que aparezca seleccionado al editar.
  List<String> _withCurrent(List<String> base, String? current) {
    final c = current?.trim();
    if (c == null || c.isEmpty || base.contains(c)) return base;
    return [c, ...base];
  }

  // Opciones del editor (ajústalas a las de profile_creation_screen.dart)
  static const _careerOptions = [
    'Psicología',
    'Medicina',
    'Enfermería',
    'Psiquiatría',
    'Otra',
  ];
  static const _objectiveOptions = [
    'Aprender',
    'Practicar',
    'Prepararme para exámenes',
    'Repasar',
  ];
  static const _experienceOptions = [
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];

  final List<(String, String, IconData)> _modes = const [
    ('dark', 'Oscuro', Icons.dark_mode_rounded),
    ('light', 'Claro', Icons.light_mode_rounded),
    ('system', 'Sistema', Icons.brightness_auto_rounded),
  ];

  final _service = AchievementService.instance;

  @override
  void initState() {
    super.initState();
    _streakDays = widget.streakDays;
    _readAvatarFromProfile();
    _loadAvatars();
    _service.load(); // carga los logros reales desde Firebase
    _listenUserData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _agentsScroll.dispose();
    _achScroll.dispose();
    super.dispose();
  }

  Future<void> _loadAvatars() async {
    try {
      final list = await AvatarService.loadAvatars();
      if (mounted) setState(() => _avatars = list);
    } catch (e) {
      debugPrint('Error cargando avatares: $e');
    }
  }

  /// Lee el avatar (índice o ruta) desde el UserProfile.
  void _readAvatarFromProfile() {
    final p = widget.profile as dynamic;
    try {
      final v = p.avatarIndex;
      if (v is int) _avatarIndex = v;
    } catch (_) {}
    if (_avatarIndex != null) return;
    for (final read in <dynamic Function()>[
      () => p.avatar,
      () => p.avatarId,
      () => p.avatarPath,
      () => p.avatarUrl,
    ]) {
      try {
        final v = read();
        if (v != null && v.toString().trim().isNotEmpty) {
          _avatarRaw = v.toString();
          return;
        }
      } catch (_) {}
    }
  }

  String? _avatarFromDoc(Map<String, dynamic> data) {
    for (final k in const [
      'avatarIndex',
      'avatar',
      'avatarId',
      'avatarPath',
      'avatarUrl',
      'selectedAvatar'
    ]) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  /// Escucha en vivo el documento del usuario (igual que ProgressScreen).
  void _listenUserData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        if (!doc.exists || !mounted) return;
        final data = doc.data() ?? <String, dynamic>{};

        setState(() {
          _gems = _asInt(data['gems']);

          // Racha del PERFIL activo (no la de la raíz)
          final mine = StreakService.findProfile(data, widget.profile.id);
          if (mine != null) {
            _streakDays = StreakService.displayStreak(mine);
          }

          final fromDoc = _avatarFromDoc(data);
          if (fromDoc != null && _avatarIndex == null) {
            final asInt = int.tryParse(fromDoc);
            if (asInt != null && _avatars.isNotEmpty) {
              _avatarIndex = asInt;
            } else {
              _avatarRaw = fromDoc;
            }
          }
        });
      },
      onError: (e) => debugPrint('Error cargando datos de usuario: $e'),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Estás seguro de que deseas salir?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Salir',
                style: TextStyle(color: AppColors.textOnPrimary)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final navigator = Navigator.of(context);
      await FirebaseAuth.instance.signOut();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changeProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSelectionScreen()),
    );

    if (result == true && mounted) {
      _listenUserData();
    }
  }

  /// Abre el panel para editar la información del perfil y la guarda.
  Future<void> _editProfileInfo() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        career: _careerValue,
        objective: _objectiveValue,
        experienceLevel: _experienceValue,
        personalMessage: _messageValue,
        careerOptions: _withCurrent(_careerOptions, _careerValue),
        objectiveOptions: _withCurrent(_objectiveOptions, _objectiveValue),
        experienceOptions: _withCurrent(_experienceOptions, _experienceValue),
      ),
    );
    if (result == null || !mounted) return;

    try {
      await ProfileService.updateProfileInfo(
        widget.profile.id,
        career: result['career'],
        objective: result['objective'],
        experienceLevel: result['experienceLevel'],
        personalMessage: result['personalMessage'],
      );
      if (!mounted) return;
      setState(() {
        _career = result['career'];
        _objective = result['objective'];
        _experienceLevel = result['experienceLevel'];
        _personalMessage = result['personalMessage'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemePreferences.instance.themeMode,
      builder: (context, _, __) {
        return ValueListenableBuilder<String>(
          valueListenable: ThemePreferences.instance.colorPalette,
          builder: (context, _, __) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.background),
                      AppColors.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopBar(),
                                const SizedBox(height: 16),
                                _buildProfileCard(wide),
                                const SizedBox(height: 16),
                                _buildProfileInfo(),
                                const SizedBox(height: 16),
                                _buildAppearanceCard(),
                                const SizedBox(height: 16),
                                _buildAchievementsCard(),
                                const SizedBox(height: 28),
                                _buildChangeProfileButton(),
                                const SizedBox(height: 12),
                                _buildLogoutButton(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleButton(Icons.arrow_back, () => Navigator.of(context).maybePop()),
        const SizedBox(width: 14),
        Text(
          'Perfil y Configuración',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Colors.transparent],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _circleButton(Icons.settings, () {}),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  // ───────────────────── Avatar ─────────────────────

  ImageProvider? _avatarProvider() {
    final i = _avatarIndex;
    if (i != null && i >= 0 && i < _avatars.length) {
      return AssetImage(_avatars[i].image);
    }
    final raw = _avatarRaw?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return NetworkImage(raw);
    if (raw.startsWith('assets/')) return AssetImage(raw);
    if (RegExp(r'^\d+$').hasMatch(raw)) {
      return AssetImage('assets/avatars/avatar_$raw.png');
    }
    final file = raw.contains('.') ? raw : '$raw.png';
    return AssetImage('assets/avatars/$file');
  }

  Widget _buildAvatar(String name) {
    final letter = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final provider = _avatarProvider();
    if (provider == null) return ClipOval(child: letter);

    return ClipOval(
      child: Image(
        image: provider,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => letter,
      ),
    );
  }

  Widget _buildProfileCard(bool wide) {
    final name = widget.profile.name;
    final career = _careerValue ?? 'Estudiante';

    final identity = Row(
      children: [
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _buildAvatar(name),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.verified, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        career,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    );

    final stats = ListenableBuilder(
      listenable: _service,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _buildStat(Icons.bar_chart_rounded, 'Nivel', '${_service.level}'),
              _buildStatDivider(),
              _buildStat(
                  Icons.local_fire_department, 'Racha', '$_streakDays días'),
              _buildStatDivider(),
              _buildStat(Icons.diamond_rounded, 'Gemas', '$_gems'),
            ],
          ),
        ),
      ),
    );

    return _glassCard(
      child: wide
          ? Row(
              children: [
                Expanded(flex: 4, child: identity),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: stats),
              ],
            )
          : Column(
              children: [
                Align(alignment: Alignment.centerLeft, child: identity),
                const SizedBox(height: 16),
                stats,
              ],
            ),
    );
  }

  // ───────────────────── Información del perfil ─────────────────────

  Widget _buildProfileInfo() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.person_outline),
              const SizedBox(width: 12),
              Expanded(
                child: _sectionTitle(
                  'Información del Perfil',
                  'Tus datos personales',
                ),
              ),
              _circleButton(Icons.edit_outlined, _editProfileInfo),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('🎓 Carrera', _careerValue ?? 'No especificada'),
          const SizedBox(height: 12),
          _infoRow('🎯 Objetivo', _objectiveValue ?? 'No especificado'),
          const SizedBox(height: 12),
          _infoRow('⭐ Nivel de experiencia',
              _experienceValue ?? 'No especificado'),
          if (_messageValue != null && _messageValue!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow('💬 Mensaje personal', _messageValue!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Apariencia ─────────────────────

  Widget _buildAppearanceCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                setState(() => _appearanceExpanded = !_appearanceExpanded),
            child: Row(
              children: [
                _sectionIcon(Icons.palette_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: _sectionTitle(
                    'Apariencia',
                    'Personaliza la apariencia de tu aplicación',
                  ),
                ),
                Icon(
                  _appearanceExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _appearanceExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _subHeader(Icons.brightness_6_outlined, 'Modo'),
                        const SizedBox(height: 12),
                        _buildModeSelector(),
                        const SizedBox(height: 24),
                        _subHeader(Icons.smart_toy_outlined, 'Temas'),
                        const SizedBox(height: 4),
                        Text(
                          'Desplázate dentro del cuadro para ver todos los temas',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Scrollbar(
                              controller: _agentsScroll,
                              thumbVisibility: true,
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final cols = c.maxWidth >= 520 ? 3 : 2;
                                  return ValueListenableBuilder<String>(
                                    valueListenable:
                                        ThemePreferences.instance.themeMode,
                                    builder: (context, mode, _) {
                                      return GridView.builder(
                                        controller: _agentsScroll,
                                        padding: const EdgeInsets.all(10),
                                        itemCount: agentPalettes.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          mainAxisExtent: 46,
                                        ),
                                        itemBuilder: (context, i) {
                                          final a = agentPalettes[i];
                                          final modeId = '$kAgentPrefix${a.id}';
                                          return _buildThemeOption(
                                            name: a.name,
                                            color: a.primary,
                                            color2: a.secondary,
                                            isSelected: mode == modeId,
                                            onTap: () => ThemePreferences
                                                .instance
                                                .setThemeMode(modeId),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _subHeader(Icons.auto_awesome, 'Temas de Colores'),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<String>(
                          valueListenable:
                              ThemePreferences.instance.colorPalette,
                          builder: (context, currentPalette, _) {
                            return LayoutBuilder(
                              builder: (context, c) {
                                const gap = 10.0;
                                final cols = c.maxWidth >= 520 ? 3 : 2;
                                final w =
                                    (c.maxWidth - gap * (cols - 1)) / cols;
                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    for (final t
                                        in ThemePreferences.colorThemes)
                                      SizedBox(
                                        width: w,
                                        height: 46,
                                        child: _buildThemeOption(
                                          name: t.$2,
                                          color: t.$3,
                                          isSelected: currentPalette == t.$1,
                                          onTap: () => ThemePreferences
                                              .instance
                                              .setColorPalette(t.$1),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return ValueListenableBuilder<String>(
      valueListenable: ThemePreferences.instance.themeMode,
      builder: (context, current, _) {
        return Row(
          children: [
            for (int i = 0; i < _modes.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _buildModeOption(
                  label: _modes[i].$2,
                  icon: _modes[i].$3,
                  isSelected: current == _modes[i].$1,
                  onTap: () =>
                      ThemePreferences.instance.setThemeMode(_modes[i].$1),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String name,
    required Color color,
    Color? color2,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color2 == null ? color : null,
                gradient: color2 == null
                    ? null
                    : LinearGradient(
                        colors: [color, color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : AppColors.textMuted.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Logros ─────────────────────

  Widget _buildAchievementsCard() {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final unlockedList = kAchievements
            .where((a) => _service.isUnlocked(a.id))
            .toList()
          ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
        final lockedList = kAchievements
            .where((a) => !_service.isUnlocked(a.id))
            .toList()
          ..sort((a, b) =>
              _service.progressOf(b).compareTo(_service.progressOf(a)));

        // Todos los desbloqueados + los 3 más cercanos a desbloquear.
        final shown = [...unlockedList, ...lockedList.take(3)];

        return _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sectionIcon(Icons.emoji_events_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sectionTitle(
                        'Logros', 'Tu progreso y metas alcanzadas'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${unlockedList.length}/${kAchievements.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _scrollArrow(Icons.chevron_left_rounded, -1),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SizedBox(
                      height: 146,
                      child: ScrollConfiguration(
                        // Permite arrastrar con mouse/trackpad además del dedo.
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: Scrollbar(
                          controller: _achScroll,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _achScroll,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: shown.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              if (i == shown.length) {
                                return _buildViewAllTile();
                              }
                              final a = shown[i];
                              return _buildAchievement(
                                  a, _service.isUnlocked(a.id));
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _scrollArrow(Icons.chevron_right_rounded, 1),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Flecha para desplazar la lista de logros (útil con mouse).
  Widget _scrollArrow(IconData icon, int direction) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        if (!_achScroll.hasClients) return;
        final target = (_achScroll.offset + direction * 220).clamp(
          0.0,
          _achScroll.position.maxScrollExtent,
        );
        _achScroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  void _openAllAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementsScreen(userProfile: widget.profile),
      ),
    );
  }

  Widget _buildViewAllTile() {
    return GestureDetector(
      onTap: _openAllAchievements,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_rounded,
                color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              'Ver todos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement(Achievement a, bool unlocked) {
    final color = unlocked ? a.color : AppColors.textMuted;
    final borderColor = unlocked ? a.rarity.color : Colors.transparent;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? a.color.withValues(alpha: 0.12)
            : AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Icon(a.icon, color: color, size: 22),
              ),
              if (!unlocked)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.lock, size: 11, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
              color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Botones de acción ─────────────────────

  Widget _buildChangeProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _changeProfile,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Cambiar de Perfil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    // Color fijo para logout (no cambia con el agente)
    const Color red = Color(0xFFFF5A6E);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            red.withValues(alpha: 0.18),
            red.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: red.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: red.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _logout,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: red.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.logout_rounded, color: red, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: red,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Helpers de UI ─────────────────────

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 24),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.primary.withValues(alpha: 0.25),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PANEL DE EDICIÓN DE INFORMACIÓN DEL PERFIL
// ═══════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final String? career, objective, experienceLevel, personalMessage;
  final List<String> careerOptions, objectiveOptions, experienceOptions;

  const _EditProfileSheet({
    required this.career,
    required this.objective,
    required this.experienceLevel,
    required this.personalMessage,
    required this.careerOptions,
    required this.objectiveOptions,
    required this.experienceOptions,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  String? _career, _objective, _experience;
  late final TextEditingController _message;

  @override
  void initState() {
    super.initState();
    _career = widget.career;
    _objective = widget.objective;
    _experience = widget.experienceLevel;
    _message = TextEditingController(text: widget.personalMessage ?? '');
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 18),
        child: Text(t,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      );

  Widget _option(String name, bool selected, VoidCallback onTap) {
    final color = AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? color : AppColors.textPrimary,
                )),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? color
                      : AppColors.textMuted.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(
      List<String> options, String? current, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in options) _option(o, current == o, () => onPick(o)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Editar información',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                _label('🎓 Carrera'),
                _group(widget.careerOptions, _career,
                    (v) => setState(() => _career = v)),
                _label('🎯 Objetivo'),
                _group(widget.objectiveOptions, _objective,
                    (v) => setState(() => _objective = v)),
                _label('⭐ Nivel de experiencia'),
                _group(widget.experienceOptions, _experience,
                    (v) => setState(() => _experience = v)),
                _label('💬 Mensaje personal'),
                TextField(
                  controller: _message,
                  maxLines: 3,
                  maxLength: 200,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: 'Escribe un mensaje (opcional)',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'career': _career,
                          'objective': _objective,
                          'experienceLevel': _experience,
                          'personalMessage': _message.text.trim(),
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
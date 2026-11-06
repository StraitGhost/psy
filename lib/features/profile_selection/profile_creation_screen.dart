// lib/features/profile_selection/profile_creation_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/profile_service.dart';
import '../../services/avatar_service.dart';
import '../../models/avatar_model.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  int selectedAvatar = 0;
  int selectedStyle = 0;
  String? career;
  String? objective;
  String? experience;

  List<AvatarModel> avatars = [];
  bool _avatarsLoaded = false;

  // Los colores de estilo se mantienen para que el usuario pueda elegirlos,
  // pero la UI alrededor usará AppColors dinámicos.
  final List<ColorStyle> styleColors = const [
    ColorStyle(Color(0xFF5965FF), 'violet'),
    ColorStyle(Color(0xFF39C5BD), 'teal'),
    ColorStyle(Color(0xFFD27C9E), 'pink'),
    ColorStyle(Color(0xFFEE923A), 'orange'),
    ColorStyle(Color(0xFF50779B), 'blue'),
  ];

  final List<String> _careers = [
    'Psicología',
    'Medicina',
    'Enfermería',
    'Educación',
    'Otra carrera',
  ];

  final List<String> _objectives = [
    'Aprender Psicopatología',
    'Prepararme para un examen',
    'Practicar casos',
    'Repasar conceptos',
  ];

  final List<String> _levels = [
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  bool _hasTextContent() {
    return _nameController.text.trim().isNotEmpty ||
        _messageController.text.trim().isNotEmpty ||
        career != null ||
        objective != null ||
        experience != null;
  }

  Future<bool> _onWillPop() async {
    if (_hasTextContent()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('¿Salir sin guardar?', style: TextStyle(color: AppColors.textPrimary)),
          content: Text('Perderás la información no guardada.', style: TextStyle(color: AppColors.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Quedarme', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text('Salir', style: TextStyle(color: AppColors.textOnPrimary)),
            ),
          ],
        ),
      );
      return confirm ?? false;
    }
    return true;
  }

  Future<void> _loadAvatars() async {
    final loadedAvatars = await AvatarService.loadAvatars();
    if (mounted) {
      setState(() {
        avatars = loadedAvatars;
        _avatarsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text('Escribe tu nombre para continuar.', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
      return;
    }

    final hasData = _hasTextContent();
    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text('Completa al menos un campo antes de guardar.', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.save_outlined, color: AppColors.textOnPrimary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Guardar perfil?',
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Revisa tu información',
                          style: TextStyle(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estás a punto de guardar:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (career != null) _infoRow(label: '🎓 Carrera', value: career!),
                    if (objective != null) _infoRow(label: '🎯 Objetivo', value: objective!),
                    if (experience != null) _infoRow(label: '⭐ Nivel', value: experience!),
                    if (_messageController.text.trim().isNotEmpty)
                      _infoRow(label: '💬 Mensaje', value: _messageController.text.trim()),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('Confirmar y Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final newProfile = await ProfileService.createProfile(
          name: name,
          avatarIndex: selectedAvatar,
          career: career,
          objective: objective,
          experienceLevel: experience,
          personalMessage: _messageController.text.trim(),
          colorStyle: styleColors[selectedStyle].name,
        );

        await ProfileService.selectProfile(newProfile.id);

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Text('Error al guardar: ${e.toString()}', style: TextStyle(color: AppColors.textOnPrimary)),
            ),
          );
        }
      }
    }
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _BackgroundDecoration(),
            SafeArea(
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 54 : 20, vertical: 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1650),
                          child: Column(
                            children: [
                              _heroSection(isWide: isWide),
                              const SizedBox(height: 26),
                              _profileForm(isWide: isWide),
                              const SizedBox(height: 26),
                              _SaveButton(onPressed: _saveProfile),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroSection({required bool isWide}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 54 : 24, vertical: isWide ? 34 : 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(colors: [AppColors.surface, AppColors.surfaceCard, AppColors.background]),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 18))],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _heroText()),
                const SizedBox(width: 30),
                _AvatarPreview(avatar: avatars.isNotEmpty ? avatars[selectedAvatar] : null, accent: styleColors[selectedStyle].color, large: true),
                const SizedBox(width: 90),
                const Expanded(child: _QuoteBlock()),
              ],
            )
          : Column(
              children: [
                _heroText(),
                const SizedBox(height: 24),
                _AvatarPreview(avatar: avatars.isNotEmpty ? avatars[selectedAvatar] : null, accent: styleColors[selectedStyle].color, large: false),
                const SizedBox(height: 22),
                const _QuoteBlock(),
              ],
            ),
    );
  }

  Widget _heroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 42, height: 1.05, fontWeight: FontWeight.w700),
            children: [
              TextSpan(text: 'Crear ', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'Perfil', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Personaliza tu experiencia en PsyCase.\nTu progreso y logros quedarán guardados aquí.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.55),
        ),
        const SizedBox(height: 18),
        Container(
          width: 54,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          ),
        ),
      ],
    );
  }

  Widget _profileForm({required bool isWide}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 34 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8), 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: AppColors.border)
      ),
      child: Column(
        children: [
          _NameField(controller: _nameController),
          const SizedBox(height: 20),
          if (isWide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _avatarSelector()), const SizedBox(width: 20), Expanded(child: _styleSelector())])
          else
            Column(children: [_avatarSelector(), const SizedBox(height: 16), _styleSelector()]),
          const SizedBox(height: 20),
          if (isWide)
            Row(
              children: [
                Expanded(child: _InlineDropdown(title: 'Carrera o profesión', icon: Icons.school_rounded, value: career, items: _careers, hint: 'Selecciona tu carrera', onChanged: (v) => setState(() => career = v))),
                const SizedBox(width: 16),
                Expanded(child: _InlineDropdown(title: 'Tu objetivo', icon: Icons.track_changes_rounded, value: objective, items: _objectives, hint: '¿Qué te motiva?', onChanged: (v) => setState(() => objective = v))),
                const SizedBox(width: 16),
                Expanded(child: _InlineDropdown(title: 'Nivel de experiencia', icon: Icons.star_rounded, value: experience, items: _levels, hint: 'Selecciona tu nivel', onChanged: (v) => setState(() => experience = v))),
              ],
            )
          else
            Column(
              children: [
                _InlineDropdown(title: 'Carrera o profesión', icon: Icons.school_rounded, value: career, items: _careers, hint: 'Selecciona tu carrera', onChanged: (v) => setState(() => career = v)),
                const SizedBox(height: 14),
                _InlineDropdown(title: 'Tu objetivo', icon: Icons.track_changes_rounded, value: objective, items: _objectives, hint: '¿Qué te motiva?', onChanged: (v) => setState(() => objective = v)),
                const SizedBox(height: 14),
                _InlineDropdown(title: 'Nivel de experiencia', icon: Icons.star_rounded, value: experience, items: _levels, hint: 'Selecciona tu nivel', onChanged: (v) => setState(() => experience = v)),
              ],
            ),
          const SizedBox(height: 20),
          _MessageField(controller: _messageController),
        ],
      ),
    );
  }

  Widget _avatarSelector() {
    return _SectionCard(
      icon: Icons.face_rounded,
      title: 'Elige tu avatar',
      child: _avatarsLoaded
          ? (avatars.isEmpty
              ? Padding(padding: const EdgeInsets.all(20), child: Text('No hay avatares disponibles.', style: TextStyle(color: AppColors.textMuted)))
              : SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatars.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() => selectedAvatar = index),
                      child: _AvatarImageChoice(avatar: avatars[index], selected: selectedAvatar == index, accent: styleColors[selectedStyle].color),
                    ),
                  ),
                ))
          : Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary))),
    );
  }

  Widget _styleSelector() {
    return _SectionCard(
      icon: Icons.palette_outlined,
      title: 'Selecciona tu estilo',
      child: Wrap(
        spacing: 18,
        children: List.generate(styleColors.length, (index) => GestureDetector(onTap: () => setState(() => selectedStyle = index), child: _ColorChoice(color: styleColors[index].color, selected: selectedStyle == index))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8), 
        border: Border(bottom: BorderSide(color: AppColors.border))
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceCard, 
            borderRadius: BorderRadius.circular(14), 
            child: InkWell(
              borderRadius: BorderRadius.circular(14), 
              onTap: () => Navigator.maybePop(context), 
              child: const SizedBox(width: 48, height: 48, child: Icon(Icons.arrow_back_rounded, color: Colors.white))
            )
          ),
          const SizedBox(width: 18),
          Icon(Icons.psychology_outlined, color: AppColors.primary, size: 34),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800), 
              children: [
                TextSpan(text: 'Psy', style: TextStyle(color: AppColors.textPrimary)), 
                TextSpan(text: 'Case', style: TextStyle(color: AppColors.primary))
              ]
            )
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -220, left: -160, child: _Glow(size: 520, color: AppColors.primary.withValues(alpha: 0.18))),
        Positioned(top: 80, right: -160, child: _Glow(size: 480, color: AppColors.secondary.withValues(alpha: 0.12))),
        Positioned(bottom: -300, left: 200, child: _Glow(size: 650, color: AppColors.secondary.withValues(alpha: 0.08))),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size * .45, spreadRadius: size * .08)]),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final AvatarModel? avatar;
  final Color accent;
  final bool large;
  const _AvatarPreview({this.avatar, required this.accent, required this.large});
  @override
  Widget build(BuildContext context) {
    final size = large ? 150.0 : 125.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: AppColors.surface, 
        border: Border.all(color: accent, width: 2), 
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.34), blurRadius: 38, spreadRadius: 8)]
      ),
      child: avatar != null
          ? ClipOval(child: Image.asset(avatar!.image, width: size, height: size, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: size * .42, color: AppColors.textMuted)))
          : Icon(Icons.person, size: size * .42, color: AppColors.textMuted),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: TextField(
        controller: controller, 
        style: TextStyle(color: AppColors.textPrimary, fontSize: 16), 
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary), 
          hintText: '¿Cómo te llamas?', 
          hintStyle: TextStyle(color: AppColors.textMuted), 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.symmetric(vertical: 18)
        )
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(children: [
            Icon(icon, size: 21, color: AppColors.textSecondary), 
            const SizedBox(width: 10), 
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary))
          ]), 
          const SizedBox(height: 18), 
          child
        ]
      ),
    );
  }
}

class _AvatarImageChoice extends StatelessWidget {
  final AvatarModel avatar;
  final bool selected;
  final Color accent;
  const _AvatarImageChoice({required this.avatar, required this.selected, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 72, height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: AppColors.surface,
        border: Border.all(color: selected ? accent : AppColors.border, width: selected ? 3 : 1),
        boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)] : null,
      ),
      child: ClipOval(
        child: Image.asset(
          avatar.image,
          width: 72, height: 72, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.surface,
              child: Icon(Icons.person, size: 34, color: selected ? AppColors.textOnPrimary : AppColors.textMuted),
            );
          },
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool selected;
  const _ColorChoice({required this.color, required this.selected});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220), width: 56, height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: color,
        border: Border.all(color: selected ? Colors.white : Colors.transparent, width: selected ? 3 : 0),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 3), BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 1)] : [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 28, color: Colors.white) : null,
    );
  }
}

class _InlineDropdown extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _InlineDropdown({
    required this.title,
    required this.icon,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.textSecondary),
              const SizedBox(width: 9),
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border, width: 1),
                  ),
                  offset: const Offset(0, 50),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  itemBuilder: (context) {
                    return items.map((item) {
                      return PopupMenuItem<String>(
                        value: item,
                        child: Row(
                          children: [
                            if (item == value)
                              Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
                            if (item != value)
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(
                              item,
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  onSelected: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  final TextEditingController controller;
  const _MessageField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.edit_note_rounded, size: 21, color: AppColors.textSecondary), 
          const SizedBox(width: 9), 
          Text('Mensaje personal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)), 
          const SizedBox(width: 5), 
          Text('(opcional)', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: controller, 
          maxLength: 200, 
          minLines: 2, 
          maxLines: 4, 
          style: TextStyle(color: AppColors.textPrimary), 
          decoration: InputDecoration(
            hintText: 'Cuéntanos algo sobre ti...', 
            hintStyle: TextStyle(color: AppColors.textMuted), 
            border: InputBorder.none, 
            counterStyle: TextStyle(color: AppColors.textMuted)
          )
        ),
      ]),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SaveButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18), 
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]), 
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))]
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, 
            shadowColor: Colors.transparent, 
            foregroundColor: AppColors.textOnPrimary, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(Icons.person_add_alt_1_rounded), 
              SizedBox(width: 10), 
              Text('Guardar perfil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), 
              SizedBox(width: 12), 
              Icon(Icons.arrow_forward_rounded)
            ]
          ),
        ),
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(
          'El primer paso para\ncomprender la mente,\nes mirarla sin prejuicios.', 
          style: TextStyle(fontSize: 16, height: 1.65, color: AppColors.textMuted, fontStyle: FontStyle.italic)
        ),
        const SizedBox(height: 14),
        SizedBox(width: 48, child: Divider(thickness: 3, color: AppColors.primary)),
        const SizedBox(height: 12),
        Icon(Icons.psychology_outlined, size: 34, color: AppColors.primary),
      ]
    );
  }
}

class ColorStyle {
  final Color color;
  final String name;
  const ColorStyle(this.color, this.name);
}
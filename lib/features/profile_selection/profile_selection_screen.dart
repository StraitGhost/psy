// lib/features/profile_selection/profile_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../models/avatar_model.dart';
import '../../services/profile_service.dart';
import '../../services/avatar_service.dart';
import '../home/home_screen.dart';
import 'profile_creation_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/loading_transition.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<UserProfile> _profiles = [];
  List<AvatarModel> _avatars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profiles = await ProfileService.getAllProfiles();
    final avatars = await AvatarService.loadAvatars();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _avatars = avatars;
        _loading = false;
      });
    }
  }

  Future<void> _selectProfile(UserProfile profile) async {
    await ProfileService.selectProfile(profile.id);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            LoadingTransition(
              message: 'Entrando a ${profile.name}...',
              child: HomeScreen(profile: profile),
            ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _createNewProfile() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const ProfileCreationScreen())
    ).then((_) => _loadData());
  }

  String _getAvatarImage(UserProfile profile) {
    if (profile.avatarIndex >= 0 && profile.avatarIndex < _avatars.length) {
      return _avatars[profile.avatarIndex].image;
    }
    return 'assets/avatars/avatar_1.png';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar sesión',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Salir',
              style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology, color: AppColors.textOnPrimary, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'PsyCase', 
                    style: TextStyle(color: AppColors.textOnPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simulador de Psicopatología', 
                    style: TextStyle(color: AppColors.textOnPrimary.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // ✅ ELIMINADO: Opción "Ver Datos"
                  Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: AppColors.textPrimary, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Icon(Icons.psychology, color: AppColors.textOnPrimary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PsyCase', style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                      Text(
                        'Simulador de Psicopatología',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selecciona tu perfil',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _createNewProfile,
                    icon: Icon(Icons.add, color: AppColors.primary),
                    label: Text(
                      'Nuevo perfil',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                Center(child: CircularProgressIndicator(color: AppColors.primary))
              else if (_profiles.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
                          child: Icon(Icons.person_add, size: 50, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No hay perfiles creados',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer perfil para comenzar',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _createNewProfile, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ), 
                          icon: const Icon(Icons.add), 
                          label: Text('Crear perfil', style: TextStyle(color: AppColors.textOnPrimary)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      mainAxisSpacing: 20, 
                      crossAxisSpacing: 20, 
                      childAspectRatio: 0.85
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      return _ProfileCard(
                        profile: _profiles[index],
                        avatarImage: _getAvatarImage(_profiles[index]),
                        onTap: () => _selectProfile(_profiles[index]),
                        onDelete: () => _deleteProfile(_profiles[index]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProfile(UserProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar perfil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${profile.name}"? Este progreso no se podrá recuperar.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ), 
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ProfileService.deleteProfile(profile.id);
      _loadData();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS DE TARJETA DE PERFIL
// ══════════════════════════════════════════════════════════════

class _ProfileCard extends StatefulWidget {
  final UserProfile profile;
  final String avatarImage;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  
  const _ProfileCard({
    required this.profile, 
    required this.avatarImage, 
    required this.onTap, 
    required this.onDelete
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    setState(() => _isPressed = true);
    await _animationController.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final completedCases = (widget.profile.progress['completedCases'] as List?)?.length ?? 0;
    final streakDays = widget.profile.dayStreak;
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard, 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(
                  color: _isPressed ? AppColors.primary : AppColors.border,
                  width: _isPressed ? 3 : 1
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 80, 
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isPressed 
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.1), 
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary, 
                                  width: _isPressed ? 3 : 2
                                ),
                                boxShadow: _isPressed
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.6),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  widget.avatarImage, 
                                  width: 80, 
                                  height: 80, 
                                  fit: BoxFit.cover, 
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 48,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                widget.profile.name, 
                                style: TextStyle(
                                  color: _isPressed ? AppColors.primary : AppColors.textPrimary, 
                                  fontSize: 18, 
                                  fontWeight: _isPressed ? FontWeight.w800 : FontWeight.w700
                                ), 
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isPressed ? AppColors.primary : AppColors.border,
                                  width: _isPressed ? 2 : 1
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _StatItem(
                                    icon: Icons.check_circle_outline, 
                                    label: 'Casos', 
                                    value: '$completedCases', 
                                    highlight: _isPressed,
                                  ),
                                  Container(width: 1, height: 24, color: AppColors.border),
                                  _StatItem(
                                    icon: Icons.local_fire_department, 
                                    label: 'Racha', 
                                    value: '$streakDays días',
                                    highlight: _isPressed,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface, 
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isPressed
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.delete_outline,
                                      color: AppColors.textMuted,
                                      size: 16,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: widget.onDelete, 
                              child: Text(
                                'Eliminar', 
                                style: TextStyle(
                                  color: _isPressed ? AppColors.textMuted : AppColors.error, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600
                                )
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isPressed)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Entrando...',
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  
  const _StatItem({
    required this.icon, 
    required this.label, 
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 14, 
              color: AppColors.primary
            ),
            const SizedBox(width: 4),
            Text(
              label, 
              style: TextStyle(
                color: highlight ? AppColors.primary : AppColors.textMuted, 
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              )
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            color: highlight ? AppColors.primary : AppColors.textPrimary, 
            fontSize: 14, 
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w700
          ),
        ),
      ],
    );
  }
}
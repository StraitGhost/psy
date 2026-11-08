// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:psy/features/profile_selection/profile_data.dart';
import 'package:psy/services/profile_data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../services/achievement_service.dart';
import '../achievements/models/achievement_model.dart';
import 'widgets/home_body.dart';
import '../game/game_screen.dart';
import '../mistakes/mistakes_screen.dart';
import '../progress/progress_screen.dart';
import '../achievements/achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserProfile _profile;
  bool _isSidebarOpen = false;

  StreamSubscription? _profileSub;
  StreamSubscription? _unlockSub;

  final List<String> _menuItems = ['Inicio', 'Mis Errores', 'Progreso', 'Logros'];
  final List<IconData> _menuIcons = [
    Icons.home_outlined,
    Icons.error_outline,
    Icons.bar_chart_outlined,
    Icons.emoji_events_outlined,
  ];

  final List<Map<String, dynamic>> _learningModules = const [
    {'name': 'Conciencia', 'icon': Icons.wb_sunny_outlined, 'color': Color(0xFF00B4DB)},
    {'name': 'Orientación', 'icon': Icons.explore_outlined, 'color': Color(0xFF11998E)},
    {'name': 'Atención', 'icon': Icons.center_focus_weak_outlined, 'color': Color(0xFFFF512F)},
    {'name': 'Memoria', 'icon': Icons.memory_outlined, 'color': Color(0xFF8E2DE2)},
    {'name': 'Percepción', 'icon': Icons.visibility_outlined, 'color': Color(0xFF00C6FF)},
    {'name': 'Pensamiento', 'icon': Icons.psychology_outlined, 'color': Color(0xFFDA22FF)},
    {'name': 'Sueño', 'icon': Icons.nightlight_round, 'color': Color(0xFF2193b0)},
    {'name': 'Apetito', 'icon': Icons.restaurant_outlined, 'color': Color(0xFF56ab2f)},
    {'name': 'Sexualidad', 'icon': Icons.favorite_outline, 'color': Color(0xFFff9a9e)},
    {'name': 'Síndromes', 'icon': Icons.medical_services_outlined, 'color': Color(0xFF536976)},
  ];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _initAchievements();
  }

  void _initAchievements() {
    // Asegura que todo el progreso se lea/escriba en ESTE perfil
    ProfileDataService.setActive(_profile.id);

    final ach = AchievementService.instance;
    ach.recordDailyVisit();

    final ref = ProfileDataService.refFor(_profile.id);
    if (ref != null) {
      _profileSub = ref.snapshots().listen((snap) {
        final data = snap.data();
        if (data != null) ach.syncFromProfile(data);
      });
    }

    _unlockSub = ach.onUnlocked.listen((a) {
      if (mounted) _showAchievementUnlocked(context, a);
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _unlockSub?.cancel();
    super.dispose();
  }

  void _showAchievementUnlocked(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                achievement.color.withValues(alpha: 0.1),
                achievement.color.withValues(alpha: 0.3)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.color.withValues(alpha: 0.2),
                  border: Border.all(color: achievement.color, width: 3),
                ),
                child: Icon(achievement.icon, color: achievement.color, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '🏆 ¡Logro Desbloqueado!',
                style: TextStyle(color: achievement.color, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: achievement.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '+${achievement.xp} XP',
                      style: TextStyle(color: achievement.color, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: achievement.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('¡Genial!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSidebar() => setState(() => _isSidebarOpen = !_isSidebarOpen);
  void _closeSidebar() => setState(() => _isSidebarOpen = false);

  Future<void> _handleMenuSelection(int index) async {
    _closeSidebar();

    if (index == 1) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => MistakesScreen(userProfile: _profile)));
      if (mounted) setState(() => _isSidebarOpen = false);
    } else if (index == 2) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressScreen(userProfile: _profile)));
      if (mounted) setState(() => _isSidebarOpen = false);
    } else if (index == 3) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen(userProfile: _profile)));
      if (mounted) setState(() => _isSidebarOpen = false);
    } else if (index >= _menuItems.length) {
      final moduleIndex = index - _menuItems.length;
      final moduleName = _learningModules[moduleIndex]['name'] as String;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(moduleName: moduleName, userProfile: _profile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (_isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSidebar,
                child: Container(color: Colors.black.withValues(alpha: 0.54)),
              ),
            ),
          HomeBody(
            profile: _profile,
            isSidebarOpen: _isSidebarOpen,
            onToggleSidebar: _toggleSidebar,
            onMenuSelection: _handleMenuSelection,
            menuItems: _menuItems,
            menuIcons: _menuIcons,
            learningModules: _learningModules,
          ),
        ],
      ),
    );
  }
}
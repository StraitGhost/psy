// lib/features/home/widgets/home_body.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/profile.dart';
import '../../../services/profile_data_service.dart';
import '../../../services/streak_service.dart';
import '../../../widgets/sidebar.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/hero_banner.dart';
import '../../../widgets/stats_row.dart';
import '../../../widgets/modules_grid.dart';
import '../../../widgets/progress_panel.dart';
import '../../../widgets/level_panel.dart';
import 'home_section_title.dart';
import 'home_footer.dart';
import '../../streak/streak_shop_screen.dart';
import '../../pet/pet_screen.dart';

class HomeBody extends StatefulWidget {
  final UserProfile profile;
  final bool isSidebarOpen;
  final VoidCallback onToggleSidebar;
  final Function(int) onMenuSelection;
  final List<String> menuItems;
  final List<IconData> menuIcons;
  final List<Map<String, dynamic>> learningModules;

  const HomeBody({
    super.key,
    required this.profile,
    required this.isSidebarOpen,
    required this.onToggleSidebar,
    required this.onMenuSelection,
    required this.menuItems,
    required this.menuIcons,
    required this.learningModules,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _dataStream;

  @override
  void initState() {
    super.initState();
    // Datos de ESTE perfil: usuarios/{uid}/perfiles/{profileId}
    _dataStream = ProfileDataService.refFor(widget.profile.id)?.snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  int _calculateLevel(int correct, int wrong) {
    final total = correct + wrong;
    if (total == 0) return 0;
    final accuracy = correct / total;
    if (accuracy >= 0.95) return 5;
    if (accuracy >= 0.80) return 4;
    if (accuracy >= 0.70) return 3;
    if (accuracy >= 0.60) return 2;
    if (accuracy >= 0.50) return 1;
    return 0;
  }

  String _getLevelName(int level) {
    switch (level) {
      case 0:
        return 'Principiante';
      case 1:
        return 'Intermedio';
      case 2:
        return 'Avanzado';
      case 3:
        return 'Experto';
      case 4:
        return 'Experto Avanzado';
      case 5:
        return 'Maestro';
      default:
        return 'Principiante';
    }
  }

  Widget _buildStreakPanel(int dayStreak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                'Tu racha actual',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🔥 ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(
                '$dayStreak días',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dayStreak > 0
                      ? '¡Sigue así, no la rompas!'
                      : '¡Completa una lección hoy!',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StreakShopScreen()));
                  },
                  icon: const Icon(Icons.shopping_cart, size: 20),
                  label: const Text('Tienda de racha',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PetScreen()));
                  },
                  icon: const Icon(Icons.pets, size: 20),
                  label: const Text('Mascota',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1200;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.isSidebarOpen ? 280 : 0,
          child: widget.isSidebarOpen
              ? AppSidebar(
                  selectedIndex: 0,
                  onItemSelected: widget.onMenuSelection,
                  menuItems: widget.menuItems,
                  menuIcons: widget.menuIcons,
                  profile: widget.profile,
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _dataStream,
            builder: (context, snapshot) {
              if (_dataStream == null) {
                return Center(
                  child: Text('No hay sesión activa',
                      style: TextStyle(color: AppColors.textPrimary)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error al cargar: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, dynamic> userData = {};
              if (snapshot.hasData && snapshot.data!.exists) {
                userData = snapshot.data!.data() ?? <String, dynamic>{};
              }

              final correctAnswers = _safeInt(userData['correctAnswers']);
              final wrongAnswers = _safeInt(userData['wrongAnswers']);
              final totalAnswers = correctAnswers + wrongAnswers;
              final accuracy = totalAnswers > 0
                  ? ((correctAnswers / totalAnswers) * 100).round()
                  : 0;
              final xp = _safeInt(userData['xp']);

              int completedCases = 0;
              if (userData['completedModules'] is Map) {
                final modules = userData['completedModules'] as Map;
                completedCases = modules.values.where((m) {
                  return m is Map && m['allCorrect'] == true;
                }).length;
              }

              final studyTime = _safeInt(userData['studyTime'] ?? (xp ~/ 2));

              // topicMastery: nombre del tema -> fracción 0..1
              final Map<String, double> topicMasteryMap = {};
              if (userData['topicMastery'] is Map) {
                final rawMap = userData['topicMastery'] as Map;
                rawMap.forEach((key, value) {
                  final d = value is num
                      ? value.toDouble()
                      : double.tryParse('${value ?? ''}');
                  if (key is String && d != null) {
                    topicMasteryMap[key] = d;
                  }
                });
              }

              // Racha real del perfil (0 si pasó más de 1 día sin lección)
              final currentStreak = StreakService.displayStreak(userData);
              final gems = _safeInt(userData['gems']);

              final currentLevel =
                  _calculateLevel(correctAnswers, wrongAnswers);
              final levelName = _getLevelName(currentLevel);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                              widget.isSidebarOpen ? Icons.close : Icons.menu,
                              color: AppColors.textPrimary,
                              size: 28),
                          onPressed: widget.onToggleSidebar,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TopBar(
                            // TopBar lee los congeladores de perfiles/{id}
                            profile: widget.profile,
                            searchController: _searchController,
                            onSearchChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.diamond,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$gems',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const HeroBanner(),
                                const SizedBox(height: 24),
                                StatsRow(
                                  completedCases: completedCases,
                                  totalCases: 12,
                                  accuracy: accuracy,
                                  errors: wrongAnswers,
                                  studyTimeMinutes: studyTime,
                                  profileId: widget.profile.id,
                                ),
                                const SizedBox(height: 28),
                                const HomeSectionTitle(
                                  title: 'Módulos de aprendizaje',
                                  subtitle:
                                      'Explora las diferentes áreas de la Psicopatología.',
                                ),
                                const SizedBox(height: 16),
                                ModulesGrid(
                                  currentUserProfile: widget.profile,
                                  searchQuery: _searchQuery,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 360,
                            child: Column(
                              children: [
                                ProgressPanel(
    profileId: widget.profile.id,
    completedCases: completedCases,
    totalCases: 12,
    topicMastery: topicMasteryMap),
                                const SizedBox(height: 20),
                                LevelPanel(
                                    correctAnswers: correctAnswers,
                                    wrongAnswers: wrongAnswers,
                                    currentLevel: currentLevel,
                                    levelName: levelName),
                                const SizedBox(height: 20),
                                _buildStreakPanel(currentStreak),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeroBanner(),
                          const SizedBox(height: 24),
                          StatsRow(
                              completedCases: completedCases,
                              totalCases: 12,
                              accuracy: accuracy,
                              errors: wrongAnswers,
                              studyTimeMinutes: studyTime,
                              profileId: widget.profile.id),
                          const SizedBox(height: 24),
                          const HomeSectionTitle(
                              title: 'Módulos de aprendizaje',
                              subtitle:
                                  'Explora las áreas de la Psicopatología.'),
                          const SizedBox(height: 16),
                          ModulesGrid(
                            currentUserProfile: widget.profile,
                            searchQuery: _searchQuery,
                          ),
                          const SizedBox(height: 24),
                          ProgressPanel(
    profileId: widget.profile.id,
    completedCases: completedCases,
    totalCases: 12,
    topicMastery: topicMasteryMap),
                          const SizedBox(height: 20),
                          LevelPanel(
                              correctAnswers: correctAnswers,
                              wrongAnswers: wrongAnswers,
                              currentLevel: currentLevel,
                              levelName: levelName),
                          const SizedBox(height: 20),
                          _buildStreakPanel(currentStreak),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const HomeFooter(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
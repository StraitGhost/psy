import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../services/achievement_service.dart';

// ✅ IMPORTACIÓN CLAVE: Trae los modelos (Achievement, AchievementCategory, kAchievements)
import 'models/achievement_model.dart';

// Imports de los widgets separados
import 'widgets/top_bar.dart';
import 'widgets/profile_card.dart';
import 'widgets/category_menu.dart';
import 'widgets/block_title.dart';
import 'widgets/next_up_card.dart';
import 'widgets/section_title.dart';
import 'widgets/appear.dart';
import 'widgets/achievement_tile.dart';
import 'widgets/detail_sheet.dart';

class AchievementsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AchievementsScreen({super.key, required this.userProfile});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _service = AchievementService.instance;
  AchievementCategory? _filter;

  @override
  void initState() {
    super.initState();
    _service.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        TopBar(service: _service, padding: const EdgeInsets.fromLTRB(24, 16, 24, 8)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 290,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ProfileCard(service: _service, compact: false),
                        const SizedBox(height: 16),
                        CategoryMenu(
                          service: _service,
                          selected: _filter,
                          onSelect: (category) => setState(() => _filter = category),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: _buildContentSlivers(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: TopBar(service: _service, padding: const EdgeInsets.fromLTRB(12, 12, 16, 8)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProfileCard(service: _service, compact: true),
          ),
        ),
        SliverToBoxAdapter(child: _buildCategoryChips()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMainAxisGroup(slivers: _buildContentSlivers()),
        ),
      ],
    );
  }

  List<Widget> _buildContentSlivers() {
    final sections = _buildSections();
    final nextUp = _getNextUpAchievements();

    return [
      if (_filter == null && nextUp.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: BlockTitle(title: '🎯 Cerca de desbloquear', subtitle: 'Te falta poco para estos'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nextUp.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => NextUpCard(
                achievement: nextUp[i],
                service: _service,
                onTap: () => _showDetail(nextUp[i]),
              ),
            ),
          ),
        ),
      ],
      for (final entry in sections.entries) ...[
        SliverToBoxAdapter(child: SectionTitle(category: entry.key, service: _service)),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 190,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => Appear(
              index: index,
              child: AchievementTile(
                achievement: entry.value[index],
                service: _service,
                onTap: () => _showDetail(entry.value[index]),
              ),
            ),
            childCount: entry.value.length,
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];
  }

  List<Achievement> _getNextUpAchievements() {
    final locked = kAchievements.where((a) => !_service.isUnlocked(a.id)).toList()
      ..sort((a, b) => _service.progressOf(b).compareTo(_service.progressOf(a)));
    return locked.take(3).toList();
  }

  Map<AchievementCategory, List<Achievement>> _buildSections() {
    final result = <AchievementCategory, List<Achievement>>{};
    for (final category in AchievementCategory.values) {
      if (_filter != null && _filter != category) continue;
      
      final list = kAchievements.where((a) => a.category == category).toList()
        ..sort((a, b) {
          final isUnlockedA = _service.isUnlocked(a.id) ? 1 : 0;
          final isUnlockedB = _service.isUnlocked(b.id) ? 1 : 0;
          if (isUnlockedA != isUnlockedB) return isUnlockedB - isUnlockedA;
          return _service.progressOf(b).compareTo(_service.progressOf(a));
        });
        
      if (list.isNotEmpty) result[category] = list;
    }
    return result;
  }

  Widget _buildCategoryChips() {
    Widget chip(String label, bool isSelected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Color(0xFF7568FF), Color(0xFF2D8CFF)])
                : null,
            color: isSelected ? null : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        children: [
          chip('✨ Todos', _filter == null, () => setState(() => _filter = null)),
          for (final category in AchievementCategory.values)
            chip('${category.emoji} ${category.label}', _filter == category, () => setState(() => _filter = category)),
        ],
      ),
    );
  }

  void _showDetail(Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => DetailSheet(achievement: achievement, service: _service),
    );
  }
}
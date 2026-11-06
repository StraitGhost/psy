// lib/widgets/modules_grid.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/game/game_screen.dart';
import '../models/profile.dart';

class AppModule {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final String? imageAsset;

  const AppModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    this.imageAsset,
  });
}

class ModulesGrid extends StatelessWidget {
  final UserProfile currentUserProfile;
  final String searchQuery; // ✅ ESTE ES EL PARÁMETRO QUE FALTABA

  const ModulesGrid({
    super.key,
    required this.currentUserProfile,
    required this.searchQuery, // ✅ Se agrega aquí
  });

  @override
  Widget build(BuildContext context) {
    final List<AppModule> allModules = [
      const AppModule(
        title: 'Conciencia',
        description: 'Alerta, obnubilación, delirium, coma.',
        icon: Icons.wb_sunny_outlined,
        gradient: LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/conciencia.png',
      ),
      const AppModule(
        title: 'Orientación',
        description: 'Tiempo, espacio y persona.',
        icon: Icons.explore_outlined,
        gradient: LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/orientacion.png',
      ),
      const AppModule(
        title: 'Atención',
        description: 'Hipervigilancia, aprosexia, distractibilidad.',
        icon: Icons.center_focus_weak_outlined,
        gradient: LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/atencion.png',
      ),
      const AppModule(
        title: 'Memoria',
        description: 'Amnesias, hipermnesias y paramnesias.',
        icon: Icons.memory_outlined,
        gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/memoria.png',
      ),
      const AppModule(
        title: 'Percepción',
        description: 'Ilusiones, alucinaciones y alucinosis.',
        icon: Icons.visibility_outlined,
        gradient: LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/percepcion.png',
      ),
      const AppModule(
        title: 'Pensamiento',
        description: 'Ideas delirantes, fóbicas e intrusas.',
        icon: Icons.psychology_outlined,
        gradient: LinearGradient(colors: [Color(0xFFDA22FF), Color(0xFF9733EE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/pensamiento.png',
      ),
      const AppModule(
        title: 'Sueño',
        description: 'Disomnias y parasomnias.',
        icon: Icons.nightlight_round,
        gradient: LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/sueno.png',
      ),
      const AppModule(
        title: 'Apetito',
        description: 'Pica, malacia, coprofagia.',
        icon: Icons.restaurant_outlined,
        gradient: LinearGradient(colors: [Color(0xFF56ab2f), Color(0xFFa8e063)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/apetito.png',
      ),
      const AppModule(
        title: 'Sexualidad',
        description: 'Anafrodisia, aversión, dispareunia.',
        icon: Icons.favorite_outline,
        gradient: LinearGradient(colors: [Color(0xFFff9a9e), Color(0xFFfecfef)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/sexualidad.png',
      ),
      const AppModule(
        title: 'Síndromes',
        description: 'Cerebrales, demencial, maníaco, etc.',
        icon: Icons.medical_services_outlined,
        gradient: LinearGradient(colors: [Color(0xFF536976), Color(0xFF292E49)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        imageAsset: 'assets/images/sindromes.png',
      ),
    ];

    // ✅ Filtra los módulos según el texto que viene de la barra de búsqueda
    final filteredModules = allModules.where((module) {
      return module.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
             module.description.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (filteredModules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No se encontraron módulos',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: filteredModules.length, // ✅ Usa la lista filtrada
      itemBuilder: (context, index) {
        return _ModuleCard(
          module: filteredModules[index], // ✅ Usa el módulo filtrado
          currentUserProfile: currentUserProfile,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TU DISEÑO ORIGINAL DE TARJETA (INTACTO, SIN CAMBIOS DE COLOR)
// ═══════════════════════════════════════════════════════════════
class _ModuleCard extends StatelessWidget {
  final AppModule module;
  final UserProfile currentUserProfile;

  const _ModuleCard({
    required this.module,
    required this.currentUserProfile,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              moduleName: module.title,
              userProfile: currentUserProfile,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: module.gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: module.gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (module.imageAsset != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    module.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            if (module.imageAsset != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(module.icon, color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 40,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
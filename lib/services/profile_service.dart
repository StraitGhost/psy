import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import 'storage_service.dart';

class ProfileService {
  // Obtener todos los perfiles desde Firestore
  static Future<List<UserProfile>> getAllProfiles() async {
    try {
      final profilesData = await StorageService.getProfiles();
      return profilesData.map((data) => UserProfile.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error obteniendo perfiles: $e');
      return [];
    }
  }

  // Guardar un perfil (crea o actualiza)
  static Future<void> saveProfile(UserProfile profile) async {
    try {
      final profiles = await getAllProfiles();
      final index = profiles.indexWhere((p) => p.id == profile.id);
      
      if (index != -1) {
        profiles[index] = profile;
      } else {
        profiles.add(profile);
      }

      final profilesJson = profiles.map((p) => p.toJson()).toList();
      await StorageService.saveProfiles(profilesJson);
      debugPrint('Perfil guardado: ${profile.name}');
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      rethrow;
    }
  }

  // Actualizar solo la información editable del perfil
  // (carrera, objetivo, nivel de experiencia y mensaje personal).
  // El resto de datos del perfil (progreso, racha, avatar...) no se toca.
  static Future<void> updateProfileInfo(
    String profileId, {
    String? career,
    String? objective,
    String? experienceLevel,
    String? personalMessage,
  }) async {
    try {
      final profiles = await getAllProfiles();
      final index = profiles.indexWhere((p) => p.id == profileId);
      if (index == -1) throw Exception('Perfil no encontrado');

      final json = Map<String, dynamic>.from(profiles[index].toJson());
      json['career'] = career;
      json['objective'] = objective;
      json['experienceLevel'] = experienceLevel;
      json['personalMessage'] = personalMessage;

      await saveProfile(UserProfile.fromJson(json));
      debugPrint('Información de perfil actualizada: $profileId');
    } catch (e) {
      debugPrint('Error actualizando información del perfil: $e');
      rethrow;
    }
  }

  // Crear un nuevo perfil
  static Future<UserProfile> createProfile({
    required String name,
    int avatarIndex = 0,
    Map<String, dynamic>? avatarConfig,
    String? career,
    String? objective,
    String? experienceLevel,
    String? personalMessage,
    String colorStyle = 'violet',
  }) async {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      avatarIndex: avatarIndex,
      avatarConfig: avatarConfig,
      career: career,
      objective: objective,
      experienceLevel: experienceLevel,
      personalMessage: personalMessage,
      colorStyle: colorStyle,
      createdAt: DateTime.now(),
      progress: _createInitialProgress(),
    );
    
    await saveProfile(profile);
    debugPrint('Perfil creado: ${profile.name}');
    return profile;
  }

  // Crear estructura de progreso inicial
  static Map<String, dynamic> _createInitialProgress() {
    return {
      'completedCases': <String>[],
      'masteredConcepts': <String>[],
      'studyTime': 0,
      'correctAnswers': 0,
      'wrongAnswers': 0,
      'currentCaseId': null,
    };
  }

  // Eliminar un perfil
  static Future<void> deleteProfile(String profileId) async {
    try {
      final profiles = await getAllProfiles();
      profiles.removeWhere((p) => p.id == profileId);
      
      final profilesJson = profiles.map((p) => p.toJson()).toList();
      await StorageService.saveProfiles(profilesJson);
      
      final currentId = await StorageService.getCurrentProfile();
      if (currentId == profileId) {
        await StorageService.removeData('current_profile_id');
      }
      
      debugPrint('Perfil eliminado: $profileId');
    } catch (e) {
      debugPrint('Error eliminando perfil: $e');
      rethrow;
    }
  }

  // Obtener el perfil actualmente activo
  static Future<UserProfile?> getCurrentProfile() async {
    try {
      final currentId = await StorageService.getCurrentProfile();
      if (currentId == null) return null;
      
      final profiles = await getAllProfiles();
      return profiles.firstWhere(
        (p) => p.id == currentId,
        orElse: () => throw Exception('Perfil no encontrado'),
      );
    } catch (e) {
      debugPrint('Error obteniendo perfil actual: $e');
      return null;
    }
  }

  // Seleccionar un perfil como activo
  static Future<void> selectProfile(String profileId) async {
    await StorageService.saveCurrentProfile(profileId);
    debugPrint('Perfil seleccionado: $profileId');
  }

  // Cerrar sesion (quitar perfil activo)
  static Future<void> logout() async {
    await StorageService.removeData('current_profile_id');
    debugPrint('Sesion cerrada');
  }

  // Debug: imprimir perfiles en consola
  static Future<void> debugPrintProfiles() async {
    final profiles = await getAllProfiles();
    debugPrint('Total de perfiles: ${profiles.length}');
    for (var profile in profiles) {
      debugPrint('  - ${profile.name} (${profile.id})');
      debugPrint('    Carrera: ${profile.career ?? "N/A"}');
      debugPrint('    Progreso: ${profile.progress}');
    }
  }
}
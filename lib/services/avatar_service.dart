import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/avatar_model.dart';

class AvatarService {
  static List<AvatarModel>? _cachedAvatars;

  static Future<List<AvatarModel>> loadAvatars() async {
    if (_cachedAvatars != null) return _cachedAvatars!;

    try {
      debugPrint('📂 Cargando avatares desde JSON...');
      final jsonString = await rootBundle.loadString('assets/avatars/avatars.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final avatarsList = jsonData['avatars'] as List<dynamic>;
      
      _cachedAvatars = avatarsList.map((json) {
        return AvatarModel.fromJson(json as Map<String, dynamic>);
      }).toList();
      
      debugPrint('Avatares cargados: ${_cachedAvatars!.length}');
      return _cachedAvatars!;
    } catch (e) {
      debugPrint('Error cargando avatares: $e');
      // Fallback con rutas correctas por si el JSON falla
      _cachedAvatars = [
        const AvatarModel(id: 'avatar_1', label: 'Avatar 1', image: 'assets/avatars/avatar_1.png'),
        const AvatarModel(id: 'avatar_2', label: 'Avatar 2', image: 'assets/avatars/avatar_2.png'),
      ];
      return _cachedAvatars!;
    }
  }
}
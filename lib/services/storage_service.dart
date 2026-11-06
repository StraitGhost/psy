import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';
  static const String _currentProfileKey = 'current_profile_id';

  // UID de la cuenta actual (lanza error si no hay sesión)
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No hay una sesión activa');
    }
    return uid;
  }

  // Documento propio de la cuenta: usuarios/{uid}
  static DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection(_usersCollection).doc(_uid);

  // Clave local única por cuenta
  static String get _localCurrentKey => '${_currentProfileKey}_$_uid';

  // ── Perfiles (Firestore, por cuenta) ──────────────────────
  static Future<void> saveProfiles(List<Map<String, dynamic>> profiles) async {
    try {
      await _userDoc.set({
        'profiles': profiles,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Perfiles guardados para $_uid: ${profiles.length}');
    } catch (e) {
      debugPrint('Error guardando perfiles en Firestore: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getProfiles() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) return [];
      final data = doc.data();
      if (data == null || data['profiles'] == null) return [];

      return (data['profiles'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Error cargando perfiles desde Firestore: $e');
      return [];
    }
  }

  // ── Perfil activo (local, por cuenta) ─────────────────────
  static Future<void> saveCurrentProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localCurrentKey, profileId);
      debugPrint('Perfil activo guardado localmente: $profileId');
    } catch (e) {
      debugPrint('Error guardando perfil activo: $e');
    }
  }

  static Future<String?> getCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_localCurrentKey);
    } catch (e) {
      debugPrint('Error leyendo perfil activo: $e');
      return null;
    }
  }

  // Elimina un dato local. Si es el perfil activo, borra la clave de la cuenta.
  static Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final realKey = key == _currentProfileKey ? _localCurrentKey : key;
      await prefs.remove(realKey);
      debugPrint('Dato eliminado localmente: $realKey');
    } catch (e) {
      debugPrint('Error eliminando dato: $e');
    }
  }

  // Limpiar todo (solo local)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('Almacenamiento local limpiado');
    } catch (e) {
      debugPrint('Error limpiando almacenamiento: $e');
    }
  }

  // ── Métodos individuales (ahora también por cuenta) ───────
  // Perfil individual: usuarios/{uid}/perfiles/{profileId}
  static Future<void> saveUserProfile(
      String profileId, Map<String, dynamic> profileData) async {
    try {
      await _userDoc
          .collection('perfiles')
          .doc(profileId)
          .set(profileData, SetOptions(merge: true));
      debugPrint('Perfil individual guardado: $profileId');
    } catch (e) {
      debugPrint('Error guardando perfil individual: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String profileId) async {
    try {
      final doc = await _userDoc.collection('perfiles').doc(profileId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error obteniendo perfil individual: $e');
      return null;
    }
  }
}
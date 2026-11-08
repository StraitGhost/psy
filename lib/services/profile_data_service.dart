
// lib/services/profile_data_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

typedef ProfileRef = DocumentReference<Map<String, dynamic>>;

/// Datos de progreso POR PERFIL:
///   usuarios/{uid}/perfiles/{profileId}
///     + subcolecciones: mistakes, question_progress, purchases
///
/// El array `profiles` de usuarios/{uid} solo guarda la identidad del perfil
/// (nombre, avatar, carrera...). Todo lo demás vive en este documento.
class ProfileDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const List<String> _subcollections = [
    'mistakes',
    'question_progress',
    'purchases',
  ];

  // Campos mínimos que debe tener el documento de cada perfil
  static const Map<String, dynamic> _defaults = {
    'gems': 0,
    'xp': 0,
    'correctAnswers': 0,
    'wrongAnswers': 0,
    'completedCases': 0,
    'currentStreak': 0,
    'dayStreak': 0,
    'streakShields': 0,
    'streakFreezes': 0,
  };

  static String? _activeId;
  static String? _activeUid;
  static String? _checkedUid;
  static Future<void>? _migrating;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ───────────── Referencias ─────────────

  /// Documento de datos de un perfil concreto (síncrono).
  static ProfileRef? refFor(String profileId) {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('perfiles')
        .doc(profileId);
  }

  // ───────────── Perfil activo ─────────────

  static void setActive(String profileId) {
    _activeUid = _uid;
    _activeId = profileId;
  }

  static void clearActive() {
    _activeId = null;
    _activeUid = null;
    _checkedUid = null;
  }

  static Future<String?> activeProfileId() async {
    final uid = _uid;
    if (uid == null) return null;
    if (_activeUid != uid) {
      _activeId = null;
      _activeUid = uid;
    }
    _activeId ??= await StorageService.getCurrentProfile();
    return _activeId;
  }

  /// Documento de datos del perfil activo (null si no hay sesión o perfil).
  static Future<ProfileRef?> activeRef() async {
    final id = await activeProfileId();
    if (id == null) return null;
    return refFor(id);
  }

  // ───────────── Inicialización ─────────────

  /// Crea los campos que falten, SIN pisar los que ya existen.
  static Future<void> initProfile(String profileId) async {
    final ref = refFor(profileId);
    if (ref == null) return;

    final snap = await ref.get();
    final data = snap.data() ?? <String, dynamic>{};

    final missing = <String, dynamic>{
      for (final e in _defaults.entries)
        if (!data.containsKey(e.key)) e.key: e.value,
      if (!data.containsKey('topicMastery')) 'topicMastery': <String, dynamic>{},
    };
    if (missing.isEmpty) return;

    await ref.set(missing, SetOptions(merge: true));
  }

  // ───────────── Migración (una sola vez) ─────────────

  /// Copia los datos viejos de la raíz de usuarios/{uid} al PRIMER perfil.
  /// La raíz no se modifica (queda de respaldo), solo se marca como migrada.
  static Future<void> migrateIfNeeded(List<String> profileIds) async {
    final uid = _uid;
    if (uid == null || profileIds.isEmpty) return;
    if (_checkedUid == uid) return;
    if (_migrating != null) return _migrating;

    _migrating = _migrate(uid, profileIds).whenComplete(() => _migrating = null);
    return _migrating;
  }

  static Future<void> _migrate(String uid, List<String> ids) async {
    try {
      final root = _db.collection('usuarios').doc(uid);
      final snap = await root.get();
      final data = snap.data();

      if (data != null && data['profileDataMigrated'] != true) {
        final firstId = ids.first;
        final target = root.collection('perfiles').doc(firstId);

        final copy = Map<String, dynamic>.from(data)
          ..remove('profiles')
          ..remove('updated_at')
          ..removeWhere((k, _) => k.startsWith('profileData'));

        if (copy.isNotEmpty) {
          await target.set(copy, SetOptions(merge: true));
        }
        for (final s in _subcollections) {
          await _copyCollection(root.collection(s), target.collection(s));
        }

        await root.set({
          'profileDataMigrated': true,
          'profileDataMigratedTo': firstId,
        }, SetOptions(merge: true));

        debugPrint('Datos de la cuenta migrados al perfil $firstId');
      }

      for (final id in ids) {
        await initProfile(id);
      }
      _checkedUid = uid;
    } catch (e) {
      debugPrint('Error migrando datos a perfiles: $e');
    }
  }

  // ───────────── Eliminar ─────────────

  static Future<void> deleteProfileData(String profileId) async {
    final ref = refFor(profileId);
    if (ref == null) return;
    for (final s in _subcollections) {
      await _deleteCollection(ref.collection(s));
    }
    await ref.delete();
  }

  // ───────────── Helpers ─────────────

  static Future<void> _copyCollection(
    CollectionReference<Map<String, dynamic>> from,
    CollectionReference<Map<String, dynamic>> to,
  ) async {
    final snap = await from.get();
    var batch = _db.batch();
    var n = 0;
    for (final d in snap.docs) {
      batch.set(to.doc(d.id), d.data());
      if (++n == 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }

  static Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final snap = await col.get();
    var batch = _db.batch();
    var n = 0;
    for (final d in snap.docs) {
      batch.delete(d.reference);
      if (++n == 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }
}
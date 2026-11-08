// lib/services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_data_service.dart';

class StreakService {
  static int _safeInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Solo año/mes/día (en UTC para que la resta de días no falle con cambios de hora)
  static DateTime _dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return _dayOnly(v.toDate());
    if (v is String) {
      final p = DateTime.tryParse(v);
      if (p != null) return _dayOnly(p);
    }
    return null;
  }

  static int _daysSince(DateTime last) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return today.difference(last).inDays;
  }

  // ───────────── LECTURA ─────────────

  /// Compatibilidad: busca un perfil dentro del array `profiles` (ya no se usa
  /// para progreso).
  static Map<String, dynamic>? findProfile(
      Map<String, dynamic> userData, String profileId) {
    final list = (userData['profiles'] as List?) ?? const [];
    for (final p in list) {
      if (p is Map && p['id']?.toString() == profileId) {
        return Map<String, dynamic>.from(p);
      }
    }
    return null;
  }

  /// Recibe el documento perfiles/{id}.
  /// Racha a MOSTRAR: si pasó más de 1 día sin lección es 0, salvo que el
  /// perfil tenga protectores (se consumirá uno en la próxima lección).
  static int displayStreak(Map<String, dynamic> profile) {
    final saved = _safeInt(profile['dayStreak']);
    final last = _parseDate(profile['lastLessonDate']);
    if (saved == 0 || last == null) return saved;

    if (_daysSince(last) <= 1) return saved;

    final protectors = _safeInt(profile['streakFreezes']) +
        _safeInt(profile['streakShields']);
    return protectors > 0 ? saved : 0;
  }

  // ───────────── ESCRITURA ─────────────

  /// Llama esto cuando el perfil activo completa una lección:
  /// StreakService.updateStreakOnLessonCompleted(profile.id)
  /// Devuelve la nueva racha (o null si no hay sesión).
  static Future<int?> updateStreakOnLessonCompleted(String profileId) async {
    final ref = ProfileDataService.refFor(profileId);
    if (ref == null) return null;

    final db = FirebaseFirestore.instance;

    return db.runTransaction<int?>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final currentStreak = _safeInt(data['dayStreak']);
      var freezes = _safeInt(data['streakFreezes']);
      var shields = _safeInt(data['streakShields']);
      final best = _safeInt(data['bestStreak']);

      final now = DateTime.now();
      final lastDate = _parseDate(data['lastLessonDate']);

      int newStreak;
      if (lastDate == null) {
        newStreak = 1;
      } else {
        final diff = _daysSince(lastDate);
        if (diff <= 0) {
          // mismo día
          newStreak = currentStreak < 1 ? 1 : currentStreak;
        } else if (diff == 1) {
          // ayer
          newStreak = currentStreak + 1;
        } else if (currentStreak > 0 && (freezes > 0 || shields > 0)) {
          // se rompió la racha: un protector la salva
          if (freezes > 0) {
            freezes--;
          } else {
            shields--;
          }
          newStreak = currentStreak + 1;
        } else {
          newStreak = 1;
        }
      }

      tx.set(
        ref,
        {
          'dayStreak': newStreak,
          'currentStreak': newStreak,
          'bestStreak': newStreak > best ? newStreak : best,
          'streakFreezes': freezes,
          'streakShields': shields,
          // medianoche LOCAL para que no cambie de día al leerla
          'lastLessonDate':
              Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        },
        SetOptions(merge: true),
      );
      return newStreak;
    });
  }
}
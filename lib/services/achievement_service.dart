// lib/services/achievement_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/achievements/models/achievement_model.dart';
import 'profile_data_service.dart';

class AchievementService extends ChangeNotifier {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  static const xpPerLevel = 100;
  static const levelTitles = ['Novato', 'Aprendiz', 'Estudiante', 'Experto', 'Maestro', 'Leyenda'];

  UserStats stats = UserStats();
  final Map<String, String> _unlocked = {};
  final List<DateTime> _recentAnswers = [];
  final _controller = StreamController<Achievement>.broadcast();

  // Ruta del documento (cuenta + perfil) cuyos datos están cargados
  String? _loadedKey;
  String? _loadingKey;
  Future<void>? _loading;

  Stream<Achievement> get onUnlocked => _controller.stream;

  bool isUnlocked(String id) => _unlocked.containsKey(id);
  DateTime? unlockedAt(String id) => DateTime.tryParse(_unlocked[id] ?? '');
  int get unlockedCount => _unlocked.length;
  int get totalCount => kAchievements.length;
  double get completion => totalCount == 0 ? 0.0 : unlockedCount / totalCount;

  num currentOf(Achievement a) => math.min(a.current(stats), a.target);
  double progressOf(Achievement a) => a.target == 0 ? 1.0 : (a.current(stats) / a.target).clamp(0.0, 1.0).toDouble();

  int get totalXp => kAchievements.where((a) => isUnlocked(a.id)).fold(0, (total, a) => total + a.xp);
  int get level => 1 + totalXp ~/ xpPerLevel;
  int get xpInLevel => totalXp % xpPerLevel;
  String get levelTitle => levelTitles[math.min((level - 1) ~/ 2, levelTitles.length - 1)];

  // ──────────────────────────────────────────────────────────
  // Gestión de los 3 slots destacados
  // ──────────────────────────────────────────────────────────
  List<String> get featuredAchievements => [
    stats.featuredSlot1,
    stats.featuredSlot2,
    stats.featuredSlot3,
  ].where((id) => id.isNotEmpty).toList();

  bool isFeatured(String achievementId) {
    return achievementId == stats.featuredSlot1 ||
           achievementId == stats.featuredSlot2 ||
           achievementId == stats.featuredSlot3;
  }

  int getFeaturedSlotIndex(String achievementId) {
    if (achievementId == stats.featuredSlot1) return 0;
    if (achievementId == stats.featuredSlot2) return 1;
    if (achievementId == stats.featuredSlot3) return 2;
    return -1;
  }

  Future<void> addToFeaturedSlot(String achievementId, int slotIndex) async {
    await load();

    if (stats.featuredSlot1 == achievementId) stats.featuredSlot1 = '';
    if (stats.featuredSlot2 == achievementId) stats.featuredSlot2 = '';
    if (stats.featuredSlot3 == achievementId) stats.featuredSlot3 = '';

    if (slotIndex == 0) stats.featuredSlot1 = achievementId;
    if (slotIndex == 1) stats.featuredSlot2 = achievementId;
    if (slotIndex == 2) stats.featuredSlot3 = achievementId;

    await _save();
    notifyListeners();
  }

  Future<void> removeFromFeaturedSlot(int slotIndex) async {
    await load();

    if (slotIndex == 0) stats.featuredSlot1 = '';
    if (slotIndex == 1) stats.featuredSlot2 = '';
    if (slotIndex == 2) stats.featuredSlot3 = '';

    await _save();
    notifyListeners();
  }

  // ── Carga: documento del PERFIL ACTIVO ──
  void _resetState() {
    stats = UserStats();
    _unlocked.clear();
    _recentAnswers.clear();
  }

  Future<void> load() async {
    final ref = await ProfileDataService.activeRef();
    if (ref == null) return;

    final key = ref.path;
    if (_loadedKey == key) return;
    if (_loading != null && _loadingKey == key) return _loading;

    _loadingKey = key;
    _loading = _doLoad(ref).whenComplete(() => _loading = null);
    return _loading;
  }

  Future<void> _doLoad(ProfileRef ref) async {
    _resetState();

    final docSnapshot = await ref.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;

      if (data['achStats'] is Map) {
        stats = UserStats.fromJson(Map<String, dynamic>.from(data['achStats'] as Map));
      } else {
        stats = UserStats(
          correctAnswers: data['correctAnswers'] ?? 0,
          currentStreak: data['currentStreak'] ?? 0,
          studyMinutes: data['studyTime'] ?? ((data['xp'] ?? 0) ~/ 2),
          questionsAnswered: (data['correctAnswers'] ?? 0) + (data['wrongAnswers'] ?? 0),
        );
      }

      if (data['achUnlocked'] is Map) {
        _unlocked.addAll(Map<String, String>.from(data['achUnlocked'] as Map));
      }
    }

    _loadedKey = ref.path;
    notifyListeners();
  }

  Future<void> _save() async {
    final ref = await ProfileDataService.activeRef();
    // Si cambió el perfil mientras tanto, no se escribe en el equivocado
    if (ref == null || ref.path != _loadedKey) return;

    await ref.set({
      'achStats': stats.toJson(),
      'achUnlocked': _unlocked,
    }, SetOptions(merge: true));
  }

  // ── Sincronizar con los datos del perfil ──
  Future<void> syncFromProfile(Map<String, dynamic> data) async {
    await load();

    int n(String k) => data[k] is num ? (data[k] as num).toInt() : 0;
    var changed = false;

    void raise(int current, int value, void Function(int) set) {
      if (value > current) {
        set(value);
        changed = true;
        notifyListeners();
      }
    }

    final correct = n('correctAnswers');
    final wrong = n('wrongAnswers');

    raise(stats.correctAnswers, correct, (v) => stats.correctAnswers = v);
    raise(stats.questionsAnswered, correct + wrong, (v) => stats.questionsAnswered = v);
    raise(stats.bestStreak, n('currentStreak'), (v) => stats.bestStreak = v);
    raise(stats.studyMinutes, n('studyTime'), (v) => stats.studyMinutes = v);

    if (changed) await _evaluate();
  }

  // ── Eventos ──
  Future<void> recordAnswer({required bool correct}) async {
    await load();
    stats.questionsAnswered++;
    if (correct) {
      stats.correctAnswers++;
      stats.currentStreak++;
      stats.bestStreak = math.max(stats.bestStreak, stats.currentStreak);
    } else {
      stats.currentStreak = 0;
    }

    final now = DateTime.now();
    _recentAnswers
      ..add(now)
      ..removeWhere((t) => now.difference(t).inMinutes >= 5);
    stats.bestIn5Min = math.max(stats.bestIn5Min, _recentAnswers.length);

    await _evaluate();
  }

  Future<void> recordExam({required int correct, required int total}) async {
    await load();
    if (total <= 0) return;

    stats.examsCompleted++;
    stats.questionsAnswered += total;
    stats.correctAnswers += correct;
    stats.bestExamPercent = math.max(stats.bestExamPercent, (correct * 100 ~/ total));

    if (correct == total && total >= 5) {
      stats.perfectExams++;
      stats.perfectExamStreak++;
    } else {
      stats.perfectExamStreak = 0;
    }

    await _evaluate();
  }

  Future<void> recordModule({required int correct, required int total}) async {
    await load();
    stats.modulesCompleted++;
    if (total > 0 && correct == total) stats.perfectModules++;
    await _evaluate();
  }

  Future<void> addStudyMinutes(int minutes) async {
    await load();
    stats.studyMinutes += minutes;
    await _evaluate();
  }

  Future<void> recordDailyVisit() async {
    await load();
    final now = DateTime.now();
    final today = _day(now);

    if (stats.lastVisit == today) return;

    stats.dayStreak = stats.lastVisit == _day(now.subtract(const Duration(days: 1)))
        ? stats.dayStreak + 1
        : 1;
    stats.lastVisit = today;

    await _evaluate();
  }

  String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _evaluate() async {
    for (final a in kAchievements) {
      if (!isUnlocked(a.id) && a.current(stats) >= a.target) {
        _unlocked[a.id] = DateTime.now().toIso8601String();
        _controller.add(a);
      }
    }
    await _save();
    notifyListeners();
  }
}
// lib/services/learning_progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:psy/features/profile_selection/profile_data.dart';
import 'profile_data_service.dart';

/// Todo el progreso se guarda en el PERFIL ACTIVO:
/// usuarios/{uid}/perfiles/{profileId} (+ mistakes, question_progress)
class LearningProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ProfileRef> _profileRef() async {
    final ref = await ProfileDataService.activeRef();
    if (ref == null) throw Exception('No hay un perfil activo');
    return ref;
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> recordAttempt({
    required String questionId,
    required String tema,
    required bool isCorrect,
    required Map<String, dynamic> questionData,
  }) async {
    final userRef = await _profileRef();
    final questionRef = userRef.collection('question_progress').doc(questionId);
    final mistakesRef = userRef.collection('mistakes').doc(questionId);

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (userDoc.exists) {
        final currentData = userDoc.data()!;
        final currentCorrect = _int(currentData['correctAnswers']);
        final currentWrong = _int(currentData['wrongAnswers']);
        final currentXP = _int(currentData['xp']);
        final currentCompleted = _int(currentData['completedCases']);
        final currentStreak = _int(currentData['currentStreak']);

        transaction.update(userRef, {
          'correctAnswers': currentCorrect + (isCorrect ? 1 : 0),
          'wrongAnswers': currentWrong + (isCorrect ? 0 : 1),
          'xp': currentXP + (isCorrect ? 10 : 0),
          'currentStreak': isCorrect ? currentStreak + 1 : 0,
          'completedCases': currentCompleted + (isCorrect ? 1 : 0),
        });
      } else {
        transaction.set(
          userRef,
          {
            'correctAnswers': isCorrect ? 1 : 0,
            'wrongAnswers': isCorrect ? 0 : 1,
            'xp': isCorrect ? 10 : 0,
            'currentStreak': isCorrect ? 1 : 0,
            'completedCases': isCorrect ? 1 : 0,
            'level': 0,
            'topicMastery': {},
            'totalLessons': 0,
          },
          SetOptions(merge: true),
        );
      }
    });

    final questionDoc = await questionRef.get();
    if (questionDoc.exists) {
      await questionRef.update({
        'attempts': FieldValue.increment(1),
        'correctAnswers': FieldValue.increment(isCorrect ? 1 : 0),
        'wrongAnswers': FieldValue.increment(isCorrect ? 0 : 1),
        'lastAnswerCorrect': isCorrect,
        'lastAttempt': FieldValue.serverTimestamp(),
      });
    } else {
      await questionRef.set({
        'questionId': questionId,
        'tema': tema,
        'attempts': 1,
        'correctAnswers': isCorrect ? 1 : 0,
        'wrongAnswers': isCorrect ? 0 : 1,
        'lastAnswerCorrect': isCorrect,
        'lastAttempt': FieldValue.serverTimestamp(),
      });
    }

    if (!isCorrect) {
      await mistakesRef.set({
        'questionId': questionId,
        'tema': tema,
        'questionData': questionData,
        'failedAt': FieldValue.serverTimestamp(),
        'attempts': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } else {
      await mistakesRef.delete();
    }

    await _updateTopicMastery(userRef, tema);
    debugPrint('✅ Progreso actualizado en ${userRef.path} - Tema: $tema - Correcta: $isCorrect');
  }

  Stream<List<Map<String, dynamic>>> getMistakes() async* {
    final ref = await _profileRef();
    yield* ref
        .collection('mistakes')
        .orderBy('failedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<int> getMistakesCount() async* {
    final ref = await _profileRef();
    yield* ref
        .collection('mistakes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> clearMistake(String questionId) async {
    final ref = await _profileRef();
    await ref.collection('mistakes').doc(questionId).delete();
    debugPrint('✅ Error eliminado: $questionId');
  }

  Future<void> _updateTopicMastery(ProfileRef userRef, String tema) async {
    try {
      final questionsRef = userRef.collection('question_progress');
      final snapshot = await questionsRef.where('tema', isEqualTo: tema).get();

      int totalAttempts = 0;
      int totalCorrect = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalAttempts += _int(data['attempts']);
        totalCorrect += _int(data['correctAnswers']);
      }

      final mastery = totalAttempts > 0 ? (totalCorrect / totalAttempts).clamp(0.0, 1.0) : 0.0;

      await userRef.update({'topicMastery.$tema': mastery});
      debugPrint('📊 Tema "$tema": $totalCorrect/$totalAttempts = ${(mastery * 100).round()}%');
    } catch (e) {
      debugPrint('❌ Error actualizando topicMastery: $e');
    }
  }

  Future<void> updateLevel(String newLevel, int totalLessons) async {
    final ref = await _profileRef();
    await ref.set({
      'level': newLevel,
      'totalLessons': totalLessons,
      'lastLevelExam': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> canTakeLevelExam() async {
    final ref = await _profileRef();
    final doc = await ref.get();
    if (!doc.exists) return true;

    final data = doc.data()!;
    final lastExam = data['lastLevelExam'] as Timestamp?;
    final totalLessons = _int(data['totalLessons']);

    if (lastExam == null) return true;

    final daysSinceExam = DateTime.now().difference(lastExam.toDate()).inDays;
    return daysSinceExam >= 7 || totalLessons >= 100;
  }

  Stream<Map<String, double>> getTopicMasteryStream() async* {
    final ref = await _profileRef();
    yield* ref.snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final masteryMap = data['topicMastery'] as Map<String, dynamic>? ?? {};
        return masteryMap.map((key, value) =>
            MapEntry(key, (value is num ? value.toDouble() : 0.0).clamp(0.0, 1.0)));
      }
      return <String, double>{};
    });
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LearningProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No hay usuario autenticado');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _userRef => _db.collection('usuarios').doc(_uid);

  Future<void> recordAttempt({
    required String questionId,
    required String tema,
    required bool isCorrect,
    required Map<String, dynamic> questionData,
  }) async {
    final questionRef = _userRef.collection('question_progress').doc(questionId);
    final mistakesRef = _userRef.collection('mistakes').doc(questionId);

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(_userRef);

      if (userDoc.exists) {
        final currentData = userDoc.data()!;
        final currentCorrect = (currentData['correctAnswers'] ?? 0) as int;
        final currentWrong = (currentData['wrongAnswers'] ?? 0) as int;
        final currentXP = (currentData['xp'] ?? 0) as int;
        final currentCompleted = (currentData['completedCases'] ?? 0) as int; // ✅ CLAVE

        transaction.update(_userRef, {
          'correctAnswers': currentCorrect + (isCorrect ? 1 : 0),
          'wrongAnswers': currentWrong + (isCorrect ? 0 : 1),
          'xp': currentXP + (isCorrect ? 10 : 0),
          'currentStreak': isCorrect ? (currentData['currentStreak'] ?? 0) + 1 : 0,
          'completedCases': currentCompleted + (isCorrect ? 1 : 0), // ✅ AQUÍ SE INCREMENTA
        });
      } else {
        transaction.set(_userRef, {
          'correctAnswers': isCorrect ? 1 : 0,
          'wrongAnswers': isCorrect ? 0 : 1,
          'xp': isCorrect ? 10 : 0,
          'currentStreak': isCorrect ? 1 : 0,
          'completedCases': isCorrect ? 1 : 0, // ✅ INICIALIZA EN 1
          'level': 0,
          'topicMastery': {},
          'totalLessons': 0,
        });
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

    await _updateTopicMastery(tema);
    debugPrint('✅ Progreso actualizado en usuarios/$_uid - Tema: $tema - Correcta: $isCorrect');
  }

  Stream<List<Map<String, dynamic>>> getMistakes() {
    return _userRef
        .collection('mistakes')
        .orderBy('failedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<int> getMistakesCount() {
    return _userRef
        .collection('mistakes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> clearMistake(String questionId) async {
    await _userRef.collection('mistakes').doc(questionId).delete();
    debugPrint('✅ Error eliminado: $questionId');
  }

  Future<void> _updateTopicMastery(String tema) async {
    try {
      final questionsRef = _userRef.collection('question_progress');
      final snapshot = await questionsRef.where('tema', isEqualTo: tema).get();

      int totalAttempts = 0;
      int totalCorrect = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalAttempts += (data['attempts'] ?? 0) as int;
        totalCorrect += (data['correctAnswers'] ?? 0) as int;
      }

      final mastery = totalAttempts > 0 ? (totalCorrect / totalAttempts).clamp(0.0, 1.0) : 0.0;

      await _userRef.update({'topicMastery.$tema': mastery});
      debugPrint('📊 Tema "$tema": $totalCorrect/$totalAttempts = ${(mastery * 100).round()}%');
    } catch (e) {
      debugPrint('❌ Error actualizando topicMastery: $e');
    }
  }

  Future<void> updateLevel(String newLevel, int totalLessons) async {
    await _userRef.update({
      'level': newLevel,
      'totalLessons': totalLessons,
      'lastLevelExam': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> canTakeLevelExam() async {
    final doc = await _userRef.get();
    if (!doc.exists) return true;

    final data = doc.data()!;
    final lastExam = data['lastLevelExam'] as Timestamp?;
    final totalLessons = (data['totalLessons'] ?? 0) as int;

    if (lastExam == null) return true;

    final daysSinceExam = DateTime.now().difference(lastExam.toDate()).inDays;
    return daysSinceExam >= 7 || totalLessons >= 100;
  }

  Stream<Map<String, double>> getTopicMasteryStream() {
    return _userRef.snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final masteryMap = data['topicMastery'] as Map<String, dynamic>? ?? {};
        return masteryMap.map((key, value) =>
            MapEntry(key, (value is num ? value.toDouble() : 0.0).clamp(0.0, 1.0)));
      }
      return {};
    });
  }
}
// lib/models/question_progress.dart
import 'package:cloud_firestore/cloud_firestore.dart';

int _toInt(dynamic v) =>
    v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

/// Documento: usuarios/{uid}/perfiles/{profileId}/question_progress/{questionId}
class QuestionProgress {
  final String questionId;
  final String tema;
  final int attempts;
  final int correctAnswers;
  final int wrongAnswers;
  final bool lastAnswerCorrect;
  final bool isPendingReview;
  final bool isMastered;
  final DateTime? lastAttempt;

  QuestionProgress({
    required this.questionId,
    required this.tema,
    required this.attempts,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.lastAnswerCorrect,
    required this.isPendingReview,
    required this.isMastered,
    this.lastAttempt,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'tema': tema,
      'attempts': attempts,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'lastAnswerCorrect': lastAnswerCorrect,
      'isPendingReview': isPendingReview,
      'isMastered': isMastered,
      'lastAttempt':
          lastAttempt != null ? Timestamp.fromDate(lastAttempt!) : null,
    };
  }

  factory QuestionProgress.fromMap(Map<String, dynamic> map) {
    final la = map['lastAttempt'];
    return QuestionProgress(
      questionId: map['questionId'] as String? ?? '',
      tema: map['tema'] as String? ?? 'General',
      attempts: _toInt(map['attempts']),
      correctAnswers: _toInt(map['correctAnswers']),
      wrongAnswers: _toInt(map['wrongAnswers']),
      lastAnswerCorrect: map['lastAnswerCorrect'] as bool? ?? false,
      isPendingReview: map['isPendingReview'] as bool? ?? false,
      isMastered: map['isMastered'] as bool? ?? false,
      lastAttempt: la is Timestamp ? la.toDate() : null,
    );
  }
}

/// Progreso de UN perfil.
/// Documento: usuarios/{uid}/perfiles/{profileId}
/// topicMastery: nombre del tema -> fracción 0..1
class ProfileProgress {
  final int gems;
  final int xp;
  final int level;
  final int currentStreak;
  final int dayStreak;
  final int streakShields;
  final int streakFreezes;
  final int correctAnswers;
  final int wrongAnswers;
  final int completedCases;
  final Map<String, double> topicMastery;

  const ProfileProgress({
    this.gems = 0,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.dayStreak = 0,
    this.streakShields = 0,
    this.streakFreezes = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.completedCases = 0,
    this.topicMastery = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'gems': gems,
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'dayStreak': dayStreak,
      'streakShields': streakShields,
      'streakFreezes': streakFreezes,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'completedCases': completedCases,
      'topicMastery': topicMastery,
    };
  }

  factory ProfileProgress.fromMap(Map<String, dynamic> map) {
    final raw = map['topicMastery'];
    final cc = map['completedCases'];
    return ProfileProgress(
      gems: _toInt(map['gems']),
      xp: _toInt(map['xp']),
      level: map['level'] == null ? 1 : _toInt(map['level']),
      currentStreak: _toInt(map['currentStreak']),
      dayStreak: _toInt(map['dayStreak']),
      streakShields: _toInt(map['streakShields']),
      streakFreezes: _toInt(map['streakFreezes']),
      correctAnswers: _toInt(map['correctAnswers']),
      wrongAnswers: _toInt(map['wrongAnswers']),
      // puede venir como número o como lista de casos
      completedCases: cc is List ? cc.length : _toInt(cc),
      topicMastery: raw is Map
          ? {for (final e in raw.entries) e.key.toString(): _toDouble(e.value)}
          : const <String, double>{},
    );
  }
}
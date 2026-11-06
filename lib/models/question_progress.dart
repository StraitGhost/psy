import 'package:cloud_firestore/cloud_firestore.dart';

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
      'lastAttempt': lastAttempt != null ? Timestamp.fromDate(lastAttempt!) : null,
    };
  }

  factory QuestionProgress.fromMap(Map<String, dynamic> map) {
    return QuestionProgress(
      questionId: map['questionId'] ?? '',
      tema: map['tema'] ?? 'General',
      attempts: map['attempts'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      lastAnswerCorrect: map['lastAnswerCorrect'] ?? false,
      isPendingReview: map['isPendingReview'] ?? false,
      isMastered: map['isMastered'] ?? false,
      lastAttempt: map['lastAttempt'] != null 
          ? (map['lastAttempt'] as Timestamp).toDate() 
          : null,
    );
  }
}

class UserStats {
  final int xp;
  final int level;
  final int currentStreak;
  final int correctAnswers;
  final int wrongAnswers;
  final Map<String, double> topicMastery;

  UserStats({
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.topicMastery,
  });

  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'topicMastery': topicMastery,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      currentStreak: map['currentStreak'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      topicMastery: Map<String, double>.from(map['topicMastery'] ?? {}),
    );
  }
}
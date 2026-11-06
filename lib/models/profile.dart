import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final int avatarIndex;
  final Map<String, dynamic> avatarConfig;
  final String? career;
  final String? objective;
  final String? experienceLevel;
  final String? personalMessage;
  final String colorStyle;
  final DateTime createdAt;
  final Map<String, dynamic> progress;
  final int streakFreezes;
  final int dayStreak; // ✅ NUEVO: Campo directo de Firebase

  UserProfile({
    required this.id,
    required this.name,
    this.avatarIndex = 0,
    Map<String, dynamic>? avatarConfig,
    this.career,
    this.objective,
    this.experienceLevel,
    this.personalMessage,
    this.colorStyle = 'violet',
    required this.createdAt,
    Map<String, dynamic>? progress,
    this.streakFreezes = 0,
    this.dayStreak = 0, // ✅ NUEVO
  })  : avatarConfig = avatarConfig ?? {},
        progress = progress ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarIndex': avatarIndex,
      'avatarConfig': avatarConfig,
      'career': career,
      'objective': objective,
      'experienceLevel': experienceLevel,
      'personalMessage': personalMessage,
      'colorStyle': colorStyle,
      'createdAt': createdAt.toIso8601String(),
      'progress': progress,
      'streakFreezes': streakFreezes,
      'dayStreak': dayStreak, // ✅ NUEVO: Se guarda en Firebase
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.parse(dateValue);
      if (dateValue is DateTime) return dateValue;
      if (dateValue is Timestamp) return dateValue.toDate();
      return DateTime.now();
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Usuario',
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      avatarConfig: json['avatarConfig'] != null 
          ? Map<String, dynamic>.from(json['avatarConfig']) 
          : {},
      career: json['career'] as String?,
      objective: json['objective'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      personalMessage: json['personalMessage'] as String?,
      colorStyle: json['colorStyle'] as String? ?? 'violet',
      createdAt: parseDate(json['createdAt']),
      progress: json['progress'] != null 
          ? Map<String, dynamic>.from(json['progress']) 
          : {},
      streakFreezes: json['streakFreezes'] as int? ?? 0,
      dayStreak: json['dayStreak'] as int? ?? 0, // ✅ NUEVO: Se lee de Firebase
    );
  }
}
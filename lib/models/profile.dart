// lib/models/profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// SOLO identidad del perfil (array `profiles` de usuarios/{uid}).
/// El progreso (gemas, xp, rachas...) vive en usuarios/{uid}/perfiles/{id}.
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
  }) : avatarConfig = avatarConfig ?? {};

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
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Usuario',
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
      avatarConfig: json['avatarConfig'] is Map
          ? Map<String, dynamic>.from(json['avatarConfig'] as Map)
          : {},
      career: json['career'] as String?,
      objective: json['objective'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      personalMessage: json['personalMessage'] as String?,
      colorStyle: json['colorStyle'] as String? ?? 'violet',
      createdAt: parseDate(json['createdAt']),
    );
  }
}
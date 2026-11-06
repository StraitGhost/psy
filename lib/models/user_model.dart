class UserModel {
  final String id;
  final String email;
  final String displayName;
  final List<ProfileModel> profiles;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.profiles = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      profiles: (map['profiles'] as List<dynamic>?)
              ?.map((p) => ProfileModel.fromMap(p))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'profiles': profiles.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// models/profile_model.dart
class ProfileModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String color;
  final bool isKids;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.color,
    this.isKids = false,
    required this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      color: map['color'] ?? '#FF0000',
      isKids: map['isKids'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'color': color,
      'isKids': isKids,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
class AvatarModel {
  final String id;
  final String label;
  final String image;

  const AvatarModel({
    required this.id,
    required this.label,
    required this.image,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'] as String,
      label: json['label'] as String,
      image: json['image'] as String,
    );
  }
}
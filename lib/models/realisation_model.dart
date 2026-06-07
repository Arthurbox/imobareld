import 'dart:convert';

class RealisationModel {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> images;
  final List<String> videoUrls;
  final DateTime createdAt;

  RealisationModel({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.images = const [],
    this.videoUrls = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'images': images, // Supabase handles this list internally if it's JSONB
      'video_urls': videoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RealisationModel.fromMap(Map<String, dynamic> map) {
    return RealisationModel(
      id: map['id'],
      ownerId: map['owner_id'] ?? map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: _parseList(map['images']),
      videoUrls: _parseList(map['video_urls'] ?? map['videoUrls']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  RealisationModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    List<String>? images,
    List<String>? videoUrls,
    DateTime? createdAt,
  }) {
    return RealisationModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      videoUrls: videoUrls ?? this.videoUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

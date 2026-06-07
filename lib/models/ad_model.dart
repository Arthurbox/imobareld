class AdModel {
  final String? id;
  final String imageUrl; // Or videoBase64
  final String? targetUrl;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final String type; // 'image' or 'video'

  AdModel({
    this.id,
    required this.imageUrl,
    this.targetUrl,
    this.priority = 0,
    this.isActive = true,
    required this.createdAt,
    this.type = 'image',
  });

  factory AdModel.fromMap(Map<String, dynamic> map, String id) {
    return AdModel(
      id: id,
      imageUrl: (map['image_url'] ?? map['imageUrl'] ?? '').toString(),
      targetUrl: (map['target_url'] ?? map['targetUrl'])?.toString(),
      priority: int.tryParse((map['priority'] ?? 0).toString()) ?? 0,
      isActive: map['is_active'] ?? map['isActive'] ?? true,
      type: (map['type'] ?? 'image').toString(),
      createdAt: (map['created_at'] ?? map['createdAt']) != null 
          ? DateTime.tryParse((map['created_at'] ?? map['createdAt']).toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'target_url': targetUrl,
      'priority': priority,
      'is_active': isActive,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AdModel copyWith({
    String? id,
    String? imageUrl,
    String? targetUrl,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
    String? type,
  }) {
    return AdModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}

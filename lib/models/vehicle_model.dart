class VehicleModel {
  final String id;
  final String companyName;
  final String model;
  final String city;
  final double pricePerDay;
  final List<String> images;
  final String description;
  final String ownerId;
  final DateTime createdAt;
  final List<String> videoUrls;

  VehicleModel({
    required this.id,
    required this.companyName,
    required this.model,
    required this.city,
    required this.pricePerDay,
    required this.images,
    required this.description,
    required this.ownerId,
    required this.createdAt,
    this.videoUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'model': model,
      'city': city,
      'price_per_day': pricePerDay,
      'images': images,
      'video_urls': videoUrls,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      companyName: map['company_name'] ?? map['companyName'] ?? '',
      model: map['model'] ?? '',
      city: map['city'] ?? 'Ouagadougou',
      pricePerDay: double.tryParse((map['price_per_day'] ?? map['pricePerDay'] ?? 0).toString()) ?? 0.0,
      images: List<String>.from(map['images'] ?? (map['image_url'] != null ? [map['image_url']] : (map['imageUrl'] != null ? [map['imageUrl']] : []))),
      description: map['description'] ?? '',
      ownerId: (map['owner_id'] ?? map['ownerId'] ?? map['owner'] ?? '').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()),
      videoUrls: List<String>.from(map['video_urls'] ?? map['videoUrls'] ?? []),
    );
  }

  /// Retourne l'image principale (la première de la liste) pour la compatibilité descendante
  String get imageUrl => images.isNotEmpty ? images.first : '';
}

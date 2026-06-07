/// Modèle de données pour représenter une propriété (annonce) dans l'application IMOBARELD
class PropertyModel {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String city;
  final String quartier;
  final List<String> images;
  final int pieces;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final int likesCount;
  final List<String> videoUrls;
  final bool isOwnerVerified;
  final String? ownerName;
  final String? ownerPhone;
  final String priceDuration; // 'Mois' ou 'Jour'
  final List<String> amenities;
  final bool isCertified;
  final double averageRating;
  final int reviewCount;
  final String transactionType; // 'Vente' ou 'Location'
  final int rentAdvanceMonths;
  final int securityDepositMonths;
  final bool isBoosted;
  final bool isLiked;
  final DateTime? boostExpiryDate;
  final String? boostPlanType;
  final int commentsCount;

  PropertyModel({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.city = 'Ouagadougou',
    required this.quartier,
    required this.images,
    required this.pieces,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.likesCount = 0,
    this.isLiked = false,
    this.videoUrls = const [],
    this.isOwnerVerified = false,
    this.ownerName,
    this.ownerPhone,
    this.priceDuration = 'mois',
    this.amenities = const [],
    this.isCertified = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.transactionType = 'Location',
    this.rentAdvanceMonths = 0,
    this.securityDepositMonths = 0,
    this.isBoosted = false,
    this.boostExpiryDate,
    this.boostPlanType,
    this.commentsCount = 0,
  });

  PropertyModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? city,
    String? quartier,
    List<String>? images,
    int? pieces,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    int? likesCount,
    bool? isLiked,
    List<String>? videoUrls,
    bool? isOwnerVerified,
    String? ownerName,
    String? ownerPhone,
    String? priceDuration,
    List<String>? amenities,
    bool? isCertified,
    double? averageRating,
    int? reviewCount,
    String? transactionType,
    int? rentAdvanceMonths,
    int? securityDepositMonths,
    bool? isBoosted,
    DateTime? boostExpiryDate,
    String? boostPlanType,
    int? commentsCount,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      city: city ?? this.city,
      quartier: quartier ?? this.quartier,
      images: images ?? this.images,
      pieces: pieces ?? this.pieces,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      videoUrls: videoUrls ?? this.videoUrls,
      isOwnerVerified: isOwnerVerified ?? this.isOwnerVerified,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      priceDuration: priceDuration ?? this.priceDuration,
      amenities: amenities ?? this.amenities,
      isCertified: isCertified ?? this.isCertified,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      transactionType: transactionType ?? this.transactionType,
      rentAdvanceMonths: rentAdvanceMonths ?? this.rentAdvanceMonths,
      securityDepositMonths: securityDepositMonths ?? this.securityDepositMonths,
      isBoosted: isBoosted ?? this.isBoosted,
      boostExpiryDate: boostExpiryDate ?? this.boostExpiryDate,
      boostPlanType: boostPlanType ?? this.boostPlanType,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      ownerId: (map['owner_id'] ?? map['ownerId'] ?? (map['owner'] is Map ? map['owner']['id'] : map['owner']) ?? '').toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Maison',
      price: double.tryParse((map['price'] ?? 0).toString()) ?? 0.0,
      city: map['city'] ?? 'Ouagadougou',
      quartier: map['quartier'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      pieces: int.tryParse((map['pieces'] ?? 0).toString()) ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : (map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now()),
      latitude: double.tryParse((map['latitude'] ?? '').toString()),
      longitude: double.tryParse((map['longitude'] ?? '').toString()),
      likesCount: int.tryParse((map['likesCount'] ?? map['likes_count'] ?? 0).toString()) ?? 0,
      isLiked: map['isLiked'] ?? map['is_liked'] ?? false,
      videoUrls: List<String>.from(map['video_urls'] ?? map['videoUrls'] ?? (map['video_url'] != null ? [map['video_url']] : (map['videoUrl'] != null ? [map['videoUrl']] : (map['videoBase64'] != null ? [map['videoBase64']] : (map['video_base64'] != null ? [map['video_base64']] : []))))),
      isOwnerVerified: map['isOwnerVerified'] ?? map['is_owner_verified'] ?? false,
      ownerName: map['ownerName'] ?? map['owner_name'],
      ownerPhone: map['ownerPhone'] ?? map['owner_phone'],
      priceDuration: (map['priceDuration'] ?? map['price_duration'] ?? 'mois').toString().toLowerCase(),
      amenities: List<String>.from(map['amenities'] ?? []),
      isCertified: map['isCertified'] ?? map['is_certified'] ?? false,
      averageRating: (map['averageRating'] ?? map['average_rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? map['review_count'] ?? 0,
      transactionType: map['transactionType'] ?? map['transaction_type'] ?? 'Location',
      rentAdvanceMonths: map['rentAdvanceMonths'] ?? map['rent_advance_months'] ?? 0,
      securityDepositMonths: map['securityDepositMonths'] ?? map['security_deposit_months'] ?? 0,
      isBoosted: map['isBoosted'] ?? map['is_boosted'] ?? false,
      boostExpiryDate: (map['boostExpiryDate'] ?? map['boost_expiry_date']) != null
          ? DateTime.tryParse((map['boostExpiryDate'] ?? map['boost_expiry_date']).toString())
          : null,
      boostPlanType: map['boostPlanType'] ?? map['boost_plan_type'],
      commentsCount: int.tryParse((map['commentsCount'] ?? map['comments_count'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'city': city,
      'quartier': quartier,
      'images': images,
      'pieces': pieces,
      'latitude': latitude,
      'longitude': longitude,
      'likes_count': likesCount,
      'video_urls': videoUrls,
      'is_owner_verified': isOwnerVerified,
      'price_duration': priceDuration,
      'amenities': amenities,
      'is_certified': isCertified,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'transaction_type': transactionType,
      'rent_advance_months': rentAdvanceMonths,
      'security_deposit_months': securityDepositMonths,
      'is_boosted': isBoosted,
      'boost_expiry_date': boostExpiryDate?.toIso8601String(),
      'boost_plan_type': boostPlanType,
    };
  }

  /// Retourne un Map filtré ne contenant que les clés fournies
  Map<String, dynamic> toFilteredMap(List<String> validKeys) {
    final Map<String, dynamic> fullMap = toMap();
    final Map<String, dynamic> filteredMap = {};
    
    for (var key in validKeys) {
      if (fullMap.containsKey(key)) {
        filteredMap[key] = fullMap[key];
      }
    }
    
    // Cas spécial pour la compatibilité vidéo si video_urls n'est pas dans la liste
    if (!validKeys.contains('video_urls') && validKeys.contains('video_url')) {
      filteredMap['video_url'] = videoUrls.isNotEmpty ? videoUrls.first : null;
    }

    return filteredMap;
  }
}

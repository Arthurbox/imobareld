class ReviewModel {
  final String? id;
  final String propertyId;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      propertyId: (map['property_id'] ?? map['propertyId'] ?? map['property'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? map['user'] ?? '').toString(),
      userName: map['user_name'] ?? map['userName'] ?? 'Anonyme',
      userProfilePicture: map['user_profile_picture'] ?? map['userProfilePicture'],
      rating: double.tryParse((map['rating'] ?? 0.0).toString()) ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: (map['created_at'] ?? map['createdAt']) != null 
          ? DateTime.parse((map['created_at'] ?? map['createdAt']).toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'property_id': propertyId,
      'user_id': userId,
      'user_name': userName,
      'user_profile_picture': userProfilePicture,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

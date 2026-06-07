class CommentModel {
  final String? id;
  final String propertyId;
  final String authorId;
  final String authorName;
  final String? authorProfilePicture;
  final String content;
  final DateTime createdAt;

  CommentModel({
    this.id,
    required this.propertyId,
    required this.authorId,
    required this.authorName,
    this.authorProfilePicture,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      propertyId: (map['property_id'] ?? map['propertyId'] ?? map['property'] ?? '').toString(),
      authorId: (map['author_id'] ?? map['authorId'] ?? map['author'] ?? '').toString(),
      authorName: map['author_name'] ?? map['authorName'] ?? 'Anonyme',
      authorProfilePicture: map['author_profile_picture'] ?? map['authorProfilePicture'],
      content: map['content'] ?? '',
      createdAt: (map['created_at'] ?? map['createdAt']) != null 
          ? DateTime.parse((map['created_at'] ?? map['createdAt']).toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'property_id': propertyId,
      'author_id': authorId,
      'author_name': authorName,
      'author_profile_picture': authorProfilePicture,
      'content': content,
    };
  }
}

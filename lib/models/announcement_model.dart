class AnnouncementModel {
  final String? id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToAuthorName;

  AnnouncementModel({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.replyToId,
    this.replyToContent,
    this.replyToAuthorName,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      authorId: (map['author_id'] ?? map['authorId'] ?? map['author'] ?? '').toString(),
      authorName: map['author_name'] ?? map['authorName'] ?? 'Anonyme',
      content: map['content'] ?? '',
      createdAt: (map['created_at'] ?? map['createdAt']) != null 
          ? DateTime.parse((map['created_at'] ?? map['createdAt']).toString()) 
          : DateTime.now(),
      replyToId: (map['reply_to_id'] ?? map['replyToId'])?.toString(),
      replyToContent: map['reply_to_content'] ?? map['replyToContent'],
      replyToAuthorName: map['reply_to_author_name'] ?? map['replyToAuthorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'reply_to_id': replyToId,
      'reply_to_content': replyToContent,
      'reply_to_author_name': replyToAuthorName,
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    String? replyToId,
    String? replyToContent,
    String? replyToAuthorName,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToAuthorName: replyToAuthorName ?? this.replyToAuthorName,
    );
  }
}

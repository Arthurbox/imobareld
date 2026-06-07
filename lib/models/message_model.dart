/// Modèle de données pour un message dans le chat
class MessageModel {
  final String? id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: (map['sender_id'] ?? map['senderId'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? map['receiverId'] ?? '').toString(),
      message: map['content'] ?? map['message'] ?? '',
      timestamp: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : (map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now()),
      isRead: map['is_read'] ?? map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': message,
      'is_read': isRead,
    };
  }
}

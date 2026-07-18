enum MessageSender {
  user,
  assistant,
}

class HealthAssistantMessage {
  final int? id;
  final int userId;
  final String message;
  final MessageSender sender;
  final DateTime createdAt;

  HealthAssistantMessage({
    this.id,
    required this.userId,
    required this.message,
    required this.sender,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'message': message,
      'sender': sender.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthAssistantMessage.fromMap(Map<String, dynamic> map) {
    return HealthAssistantMessage(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      message: map['message'] as String,
      sender: MessageSender.values[map['sender'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

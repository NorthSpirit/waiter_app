class ChatMessage {
  final int id;
  final String senderName;
  final String message;
  final String sentAt;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      senderName: json['sender_name'] as String,
      message: json['message'] as String,
      sentAt: json['sent_at'] as String,
    );
  }
}
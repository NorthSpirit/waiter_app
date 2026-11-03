// Single chat message class for the waiter's app, mirroring "chat_messages" of the system
// They have their own id, employee id, message text itself and time, at which it was sent
// They also have restaurant ID to know, to which chat room/restaurant they belong to
// But in waiter's app, waiter always sees his (the one they belong to) own restaurant only 
// Employee id in the chat_messages is used to get the name from the server.
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

  // Factories in dart just allows to use methods, without instanciating the class first (static in C#)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      senderName: json['sender_name'] as String,
      message: json['message'] as String,
      sentAt: json['sent_at'] as String,
    );
  }
}
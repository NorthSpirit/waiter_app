import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/models/chat_message.dart';

// Methods for the chat messaging system
// Note, all 3 of them are authenticated, but POST and GET have different defaults
class ChatApi {

  // Gets the restaurants chat messages, based on the ID of the restaurant waiter belongs to
  // And returns the list
  // Individual message has ID, sender name, message text and date when it was sent at
  static Future<List<ChatMessage>> list() async {
    final data = await ApiClient.get('/api/waiter/chat/messages') as List<dynamic>;
    return data.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Checks if there were any messages after the last one seen
  // Waiter's app sends the ID of the last message they've seen (messages of this restaurant)
  // And the server returns the relavent messages with the same stuff the one above
  static Future<List<ChatMessage>> pollAfter(int lastId) async {
    final data = await ApiClient.get('/api/waiter/chat/messages/after/$lastId') as List<dynamic>;
    return data.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Sends the message, note, cussing check is done even before this is reached, back in the chat screen.
  static Future<void> send(String message) {
    return ApiClient.post(
      '/api/waiter/chat/send',
      {'message': message},
      authenticated: true,
    );
  }
}
import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/models/chat_message.dart';

class ChatApi {
  static Future<List<ChatMessage>> list() async {
    final data = await ApiClient.get('/api/waiter/chat/messages') as List<dynamic>;
    return data.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<List<ChatMessage>> pollAfter(int lastId) async {
    final data = await ApiClient.get('/api/waiter/chat/messages/after/$lastId') as List<dynamic>;
    return data.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<void> send(String message) {
    return ApiClient.post(
      '/api/waiter/chat/send',
      {'message': message},
      authenticated: true,
    );
  }
}
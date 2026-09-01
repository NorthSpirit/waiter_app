import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/models/quick_item.dart';

class QuickItemsApi {
  static Future<List<QuickItem>> list() async {
    final data = await ApiClient.get('/api/waiter/quick-items') as List<dynamic>;
    return data.map((json) => QuickItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<void> add(int itemId, {int sortOrder = 0}) {
    return ApiClient.post(
      '/api/waiter/quick-items',
      {'item_id': itemId, 'sort_order': sortOrder},
      authenticated: true,
    );
  }

  static Future<void> remove(int itemId) {
    return ApiClient.delete('/api/waiter/quick-items/$itemId');
  }
}
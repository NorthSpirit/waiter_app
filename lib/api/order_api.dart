import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/models/order_status.dart';

class OrderApi {
  static Future<Map<String, dynamic>> submit(String idempotencyKey) {
    return ApiClient.post('/api/waiter/orders', {
      'idempotency_key': idempotencyKey,
      'table_id': Cart.instance.tableId,
      'notes': '',
      'items': Cart.instance.items
          .map(
            (i) => {
              'item_id': i.itemId,
              'quantity': i.quantity,
              'notes': i.notes,
            },
          )
          .toList(),
    }, authenticated: true);
  }

  static Future<List<OrderStatus>> listMyOrders() async {
    final data = await ApiClient.get('/api/waiter/orders') as List<dynamic>;
    return data
        .map((json) => OrderStatus.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> cancelOrder(int orderId) {
    return ApiClient.post('/api/waiter/orders/$orderId/cancel', {}, authenticated: true);
  }
}
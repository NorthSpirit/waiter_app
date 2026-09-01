import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/models/waiter_table.dart';

class TableApi {
  static Future<List<WaiterTable>> listTables() async {
    final data = await ApiClient.get('/api/waiter/tables') as List<dynamic>;
    return data.map((json) => WaiterTable.fromJson(json as Map<String, dynamic>)).toList();
  }
}
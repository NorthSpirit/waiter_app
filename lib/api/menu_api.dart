import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/models/item_detail.dart';
import 'package:waiter_app/models/menu.dart';
import 'package:waiter_app/models/menu_item.dart';

class MenuApi {
  static Future<List<RestaurantMenu>> listMenus() async {
    final data = await ApiClient.get('/api/waiter/menus') as List<dynamic>;
    return data
        .map((json) => RestaurantMenu.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<MenuItem>> listMenuItems(int menuId) async {
    final data =
        await ApiClient.get('/api/waiter/menus/$menuId/items') as List<dynamic>;
    return data
        .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<ItemDetail> getItemDetail(int itemId) async {
    final data =
        await ApiClient.get('/api/waiter/items/$itemId')
            as Map<String, dynamic>;
    return ItemDetail.fromJson(data);
  }

  static Future<List<MenuItem>> search(String query) async {
    final data =
        await ApiClient.get(
              '/api/waiter/search?q=${Uri.encodeQueryComponent(query)}',
            )
            as List<dynamic>;
    return data
        .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

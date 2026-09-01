import 'package:flutter/foundation.dart';
import 'package:waiter_app/models/cart_item.dart';

/// The waiter's in-progress order — items added from any menu screen
/// accumulate here until submitted, and a table isn't chosen until the
/// waiter taps the Status button and picks one. This is what lets a
/// waiter add a burger from one menu, a drink from another, then submit
/// everything together as one order.
class Cart extends ChangeNotifier {
  static final Cart instance = Cart._();
  Cart._();

  int? tableId;
  int? tableNumber;
  bool started = false;
  final List<CartItem> items = [];

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  void addItem(int itemId, String name, double price) {
    final existing = items.where((i) => i.itemId == itemId).firstOrNull;
    if (existing != null) {
      existing.quantity++;
    } else {
      items.add(CartItem(itemId: itemId, name: name, price: price));
    }
    notifyListeners();
  }

  void removeOne(int itemId) {
    final existing = items.where((i) => i.itemId == itemId).firstOrNull;
    if (existing == null) return;
    if (existing.quantity <= 1) {
      items.remove(existing);
    } else {
      existing.quantity--;
    }
    notifyListeners();
  }

  int quantityOf(int itemId) {
    return items.where((i) => i.itemId == itemId).firstOrNull?.quantity ?? 0;
  }

  void setTable(int? id, int? number) {
    tableId = id;
    tableNumber = number;
    started = true;
    notifyListeners();
  }

  void clear() {
    tableId = null;
    tableNumber = null;
    started = false;
    items.clear();
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';
import 'package:waiter_app/models/cart_item.dart';

// The waiter's in-progress order — items added from any menu screen are held here until submitted, 
// table is only chosen them waiter taps the Status button and picks one 
// This is what lets a waiter add a burger from one menu, a beer from another
// and when submit once everything is together as one order.
// It's extension of change notifier so widgets and screens would know to be updated, if values change.
class Cart extends ChangeNotifier {
  static final Cart instance = Cart._();
  Cart._();

  // Table number and id is gotten from main system's tables
  int? tableId;
  int? tableNumber;

  // Bool if it's started is used on the main screen, to know, which widgets to draw, for example clear/cancel.
  // Used to make sure, it doesn't ever go out of sync, bool is needed, because table = null is ambiguous - it can be take out too. 
  bool started = false;

  // Cart items is a representation of item_orders
  final List<CartItem> items = [];

  // Bool if it's empty is used on orders screen, while it is not needed, isEmpty looks better than items.isEmpty on said screen
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  // Adds item by either creating the item in the list or increasing quantity by 1 if there is one already
  void addItem(int itemId, String name, double price) {
    final existing = items.where((i) => i.itemId == itemId).firstOrNull;
    if (existing != null) {
      existing.quantity++;
    } else {
      items.add(CartItem(itemId: itemId, name: name, price: price));
    }
    notifyListeners();
  }

  // Same at add item, but in reverse, if quantity was 1, now it's removed, if it wasn't, it's reduced by 1
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

  // Returns how many of this item are in the cart (0 if none), used by the tiles to show the quantity and the remove button.
  // In pin mode the screens pass 0 instead, so the number/button is hidden even if the item is in the cart.
  int quantityOf(int itemId) {
    return items.where((i) => i.itemId == itemId).firstOrNull?.quantity ?? 0;
  }

  // Sets table based on the selection, doesn't have to be done at the start.
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
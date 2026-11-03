// Cart item for the waiter app, largely mirroring item_orders
// Which has the item_id, quantity, notes, price (as a snapshot at the time order was created), name (as a snapshot)
// Here name and price are only a copy taken when the waiter added the item to the cart, used to show it and the total.
// The app sends only item_id, quantity and notes - the server takes the price from the database and makes the real snapshot.
// It also has a corresponding order ID in item_orders, but in the app state there is no order ID yet
// (if it's cancelled/cleared there won't even be one)
class CartItem {
  final int itemId;
  final String name;
  final double price;
  int quantity;
  String notes;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes = '',
  });

  // Little helper to get total price.
  double get lineTotal => price * quantity;
}
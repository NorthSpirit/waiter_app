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

  double get lineTotal => price * quantity;
}
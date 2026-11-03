
// A simplified representation of the food_items from the main server app.
// it still has it's own id, name, description, price, check if it is still available (it can be ticked by managers or chefs)
// Same as with all, restaurant ID is the id of the logged in waiter/manager, thus representation object doesn't have one of it's own
class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  String get formattedPrice => '€${price.toStringAsFixed(2)}';
}
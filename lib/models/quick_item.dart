// Apps class mirroring the waiter's quick items (which has employee id, item id and sort order)
// employee id is based on the actual connected waiter/manger id, thus, it is not needed
// actual item's data - name, image url, price, is gotten from the food_item, based on the ID
// Sort order is, at the current iteration, not used 
class QuickItem {
  final int itemId;
  final String name;
  final String imageUrl;
  final double price;
  final int sortOrder;

  QuickItem({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.sortOrder,
  });

  factory QuickItem.fromJson(Map<String, dynamic> json) {
    return QuickItem(
      itemId: json['item_id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      sortOrder: json['sort_order'] as int,
    );
  }

  // Little helper method to format the price, like 4.5 turns into €4.50
  String get formattedPrice => '€${price.toStringAsFixed(2)}';
}
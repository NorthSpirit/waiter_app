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

  String get formattedPrice => '€${price.toStringAsFixed(2)}';
}
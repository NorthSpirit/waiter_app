// A representation of ingredient_in_item, as a joined selection
// ingredient_in_item in the real server has a measurement and the amount
// ingredient id is used to get the name of it.
class ItemIngredient {
  final String name;
  final String measurement;
  final double amount;

  ItemIngredient({required this.name, required this.measurement, required this.amount});

  factory ItemIngredient.fromJson(Map<String, dynamic> json) {
    return ItemIngredient(
      name: json['name'] as String,
      measurement: json['measurement'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

// An object amalgam of food_item + 
// it uses food_item's id, name, description, instructions, img url, price and check if it's available (on which can be checked by manager)
// it also gets the allergen's name (name only), based on the relationship in the food_item_allergen table
// And a list of items from ingredient_in_item shown above
class ItemDetail {
  final int id;
  final String name;
  final String description;
  final String instructions;
  final String imageUrl;
  final double price;
  final bool isAvailable;
  final List<ItemIngredient> ingredients;
  final List<String> allergens;

  ItemDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
    required this.ingredients,
    required this.allergens,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((j) => ItemIngredient.fromJson(j as Map<String, dynamic>))
          .toList(),
      allergens: (json['allergens'] as List<dynamic>? ?? []).map((a) => a as String).toList(),
    );
  }

  String get formattedPrice => '€${price.toStringAsFixed(2)}';
}
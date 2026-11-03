// A pretty direct mirror of the food_menu from the main server
// it has it's (menu's) id, name, description
// it also has image url, but I decided not to use custom images in the  waiter's app due to size and information limitations
// Also, it has a restaurant ID, but in waiter's app, it's always the connected waiter's restaurant anyhow
class RestaurantMenu {
  final int id;
  final String name;
  final String description;

  RestaurantMenu({required this.id, required this.name, required this.description});

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) {
    return RestaurantMenu(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}
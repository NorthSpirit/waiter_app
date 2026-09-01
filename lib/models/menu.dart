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
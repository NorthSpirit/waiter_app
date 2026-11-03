// Table as the waiter's app sees it. Tables belong to the whole food hall, not to a restaurant,
// so the server adds hasActiveOrder: whether THIS restaurant has an unfinished order (not delivered/cancelled) at the table.
// If it does, the order goes to that same order (items are added to it).
// other fields belong to the table - id, number, capacity
// section is not gotten to limit the data on the small screen.

class WaiterTable {
  final int id;
  final int number;
  final int capacity;
  final String status;
  final bool hasActiveOrder;

  WaiterTable({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    required this.hasActiveOrder,
  });

  factory WaiterTable.fromJson(Map<String, dynamic> json) {
    return WaiterTable(
      id: json['id'] as int,
      number: json['number'] as int,
      capacity: json['capacity'] as int,
      status: json['status'] as String,
      hasActiveOrder: json['has_active_order'] as bool? ?? false,
    );
  }
}
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
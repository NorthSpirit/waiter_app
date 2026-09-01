class OrderStatusItem {
  final int itemId;
  final String name;
  final int quantity;
  final double price;

  OrderStatusItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderStatusItem.fromJson(Map<String, dynamic> json) {
    return OrderStatusItem(
      itemId: json['item_id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderStatus {
  final int orderId;
  final int orderNumber;
  final int? tableNumber;
  final String status;
  final String createdAt;
  final String notes;
  final List<OrderStatusItem> items;

  OrderStatus({
    required this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    required this.status,
    required this.createdAt,
    required this.notes,
    required this.items,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      orderId: json['order_id'] as int,
      orderNumber: json['order_number'] as int,
      tableNumber: json['table_number'] as int?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      notes: json['notes'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((j) => OrderStatusItem.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}

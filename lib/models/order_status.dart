// Order status item model, to be held by order status
// Representing the item_orders, which holds item id, order it, quanity and price as a snapshot at the time of the order
// Item id, quantity and price is the direct correlationm
// name is item's name at the point of the snapshot (in case it was renamed) gooten from item_orders
// So if between ordering and now item was renamed, name would still be the one as ordered in this.
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

// Model, which closely mirrors the food_orders for the app
// Like the original, it has it's own id (orderId), also order number, which is not the id,
// for order numbers need to be readable outside of the database and might even be shared between other systems (banking stuff)
// Number, status, creation date and notes are a direction correlation
// Order Status items are gotten by joining orders with the item_orders belonging to said order (by id)
// Table number (not id) is nullable: the server gets it by joining the tables, and a take-out order has no table, so it stays null.
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

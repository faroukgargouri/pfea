class Order {
  final int id;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }

  get client => null;
}

class OrderItem {
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }
}

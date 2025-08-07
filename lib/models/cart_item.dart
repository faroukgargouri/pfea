import 'product.dart';

class CartItem {
  final int id;
  final int productId;
  final Product product;
  final int quantity;
  final int userId;
  final double price;

  CartItem({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.userId,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['productId'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      userId: json['userId'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'userId': userId,
      'price': price,
    };
  }
}

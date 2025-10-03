// lib/models/cart_item.dart
import 'product.dart';

class CartItem {
  final int id;

  /// Match Product.id type (String).
  final String productId;

  /// Optional nested product.
  final Product? product;

  final int quantity;
  final int userId;

  /// Per-unit price in the cart. If not present, fall back to product.prix.
  final double price;

  /// Convenience: total price for this line
  double get lineTotal => quantity * price;

  CartItem({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.userId,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    Product? prod;
    final p = json['product'];
    if (p is Map<String, dynamic>) {
      prod = Product.fromJson(p);
    }

    final pid = (json['productId'] ??
            json['itmref'] ??
            (prod != null ? prod.id : null) ??
            '')
        .toString();

    final unit = _firstDouble([
      json['price'],   // cart item price (preferred)
      json['prix'],    // sometimes backend might send 'prix'
      prod?.prix,      // fallback to product price
    ]);

    return CartItem(
      id: _toInt(json['id']),
      productId: pid,
      product: prod,
      quantity: _toInt(json['quantity']),
      userId: _toInt(json['userId']),
      price: unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'userId': userId,
      'price': price,
      if (product != null) 'product': product!.toJson(),
    };
  }
}

// ---- local tiny helpers (self-contained) ------------------------------------
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
}

double _firstDouble(List<dynamic> options) {
  for (final o in options) {
    final d = _toDouble(o);
    if (d > 0) return d;
  }
  return 0.0;
}

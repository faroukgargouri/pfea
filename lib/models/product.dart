class Product {
  final int? id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final String reference; // 👈 AJOUT

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.reference, // 👈 AJOUT
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      reference: json['reference'], // 👈 AJOUT
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'category': category,
      'reference': reference, // 👈 AJOUT
    };
  }
}

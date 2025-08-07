import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> allProducts = [];
  List<Product> filtered = [];
  Map<int, TextEditingController> qtyControllers = {};
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        allProducts = products;
        filtered = products;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur chargement produits")),
      );
    }
  }

  void _filterProducts(String category) {
    setState(() {
      selectedCategory = category;
      filtered = category.isEmpty
          ? allProducts
          : allProducts.where((p) => p.category == category).toList();
    });
  }

  Future<void> _commanderProduit(Product product, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    try {
      await ApiService.createOrder(userId, product.id!, quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.name} commandé avec succès.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur commande : ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Achat"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<String>(
              value: selectedCategory.isEmpty ? null : selectedCategory,
              hint: const Text("Filtrer par catégorie"),
              isExpanded: true,
              items: allProducts
                  .map((p) => p.category)
                  .toSet()
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) => _filterProducts(value ?? ''),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                final controller = qtyControllers.putIfAbsent(
                    product.id!, () => TextEditingController());

                return Card(
                  elevation: 3,
                  child: Column(
                    children: [
                      Image.network(product.imageUrl,
                          height: 100, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Text("${product.price.toStringAsFixed(3)} TND",
                          style: const TextStyle(color: Colors.indigo)),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Quantité",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final qty = int.tryParse(controller.text) ?? 0;
                          if (qty > 0) {
                            _commanderProduit(product, qty);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Quantité invalide")),
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text("Commander"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

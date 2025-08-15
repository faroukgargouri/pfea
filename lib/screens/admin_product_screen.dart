import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'dashboard_screen.dart';
import 'representant_list_screen.dart';
import 'admin_reclamation_screen.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  int _selectedIndex = 0;

  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();

  List<Product> products = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('http://192.168.0.103:5274/api/product'));
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        products = decoded.map((json) => Product.fromJson(json)).toList();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _addProduct() async {
    final product = Product(
      name: nameCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      price: double.tryParse(priceCtrl.text.trim()) ?? 0,
      imageUrl: imageUrlCtrl.text.trim(),
      category: categoryCtrl.text.trim(),
      reference: referenceCtrl.text.trim(),
    );

    final response = await http.post(
      Uri.parse('http://192.168.0.103:5274/api/product'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      nameCtrl.clear();
      descriptionCtrl.clear();
      priceCtrl.clear();
      imageUrlCtrl.clear();
      categoryCtrl.clear();
      referenceCtrl.clear();
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produit ajouté avec succès")),
        );
      }
    }
  }

  Future<void> _deleteProduct(int id) async {
    final response =
        await http.delete(Uri.parse('http://192.168.0.103:5274/api/product/$id'));
    if (response.statusCode == 200) {
      await _loadProducts();
    }
  }

  String? _safeUrl(String? url) {
    if (url == null) return null;
    final u = url.trim();
    if (u.isEmpty) return null;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return null;
  }

  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildProductPage(),
      const DashboardScreen(),
      const RepresentantListScreen(),
      const AdminReclamationScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _selectedIndex,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Représentants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            label: 'Réclamations',
          ),
        ],
      ),
    );
  }

  Widget _buildProductPage() {
    final width = MediaQuery.of(context).size.width;
    final crossAxis = width < 500 ? 2 : (width < 800 ? 3 : 4);

    double aspect;
    if (crossAxis == 2) {
      aspect = 0.60;
    } else if (crossAxis == 3) {
      aspect = 0.70;
    } else {
      aspect = 0.78;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("Admin - Produits"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Ajouter un produit",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: _input("Nom")),
            const SizedBox(height: 8),
            TextField(
                controller: descriptionCtrl, decoration: _input("Description")),
            const SizedBox(height: 8),
            TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _input("Prix")),
            const SizedBox(height: 8),
            TextField(controller: imageUrlCtrl, decoration: _input("Image URL")),
            const SizedBox(height: 8),
            TextField(controller: categoryCtrl, decoration: _input("Catégorie")),
            const SizedBox(height: 8),
            TextField(controller: referenceCtrl, decoration: _input("Référence")),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white, // text/icons white
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Ajouter",
                  style: TextStyle(
                    color: Colors.white, // force white text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Liste des produits",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (products.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text("Aucun produit pour le moment.")),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxis,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspect,
                ),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return _ProductCard(
                    product: p,
                    imageUrl: _safeUrl(p.imageUrl),
                    onDelete: () => _deleteProduct(p.id!),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String? imageUrl;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.imageUrl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 12,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl == null
                    ? _ImagePlaceholder(name: product.name)
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) =>
                            _ImagePlaceholder(name: product.name),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          iconSize: 18,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                    if (product.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${product.price.toStringAsFixed(3)} TND",
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Réf: ${product.reference}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String name;
  const _ImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase()
        : 'P';

    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey.shade400,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

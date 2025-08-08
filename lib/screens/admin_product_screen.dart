import 'package:flutter/material.dart';
import '../models/product.dart';
import 'dashboard_screen.dart';
import 'representant_list_screen.dart';
import 'admin_reclamation_screen.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

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
          await http.get(Uri.parse('http://192.168.1.18:5274/api/product'));
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
      Uri.parse('http://192.168.1.18:5274/api/product'),
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
    final response = await http.delete(
        Uri.parse('http://192.168.1.18:5274/api/product/$id'));
    if (response.statusCode == 200) {
      await _loadProducts();
    }
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
            TextField(controller: descriptionCtrl, decoration: _input("Description")),
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
            ElevatedButton(
              onPressed: _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Ajouter"),
            ),
            const Divider(height: 32),
            const Text("Liste des produits",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (isLoading)
              const CircularProgressIndicator()
            else
              ...products.map(
                (p) => Card(
                  child: ListTile(
                    leading: Image.network(
                      p.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                        "${p.category} • ${p.price.toStringAsFixed(3)} TND\nRef: ${p.reference}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(p.id!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

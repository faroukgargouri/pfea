import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/offline_cache.dart';
import 'order_list_screen.dart';
import 'representant_home_page.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const String apiBase = "http://192.168.0.103:5274";

  List<Product> allProducts = [];
  List<Product> filtered = [];
  final Map<int, TextEditingController> qtyControllers = {};
  String selectedCategory = '';
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // Try API first (ApiService internally caches when online, falls back offline)
      final products = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        allProducts = products;
        filtered = products;
      });
    } catch (e) {
      // Extra safety: direct read from OfflineCache if ApiService threw
      try {
        final cached = OfflineCache.getProducts();
        final products = cached.map((e) => Product.fromJson(e)).toList();
        if (!mounted) return;
        setState(() {
          allProducts = products;
          filtered = products;
        });
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur chargement produits: $e")),
        );
      }
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

  // ================= IMAGE HELPERS =================

  Widget _productImage(String src) {
    if (src.isEmpty) return _imagePlaceholder();

    String s = src.trim();

    if (!s.startsWith('http') && !s.startsWith('data:')) {
      s = apiBase + (s.startsWith('/') ? s : '/$s');
    }

    if (s.startsWith('data:')) {
      final base64Part = s.substring(s.indexOf(',') + 1);
      try {
        final bytes = base64Decode(base64Part);
        return _imageBox(Image.memory(bytes, fit: BoxFit.cover));
      } catch (_) {
        return _imagePlaceholder();
      }
    }

    final maybeBase64 = s.replaceAll(RegExp(r'\s'), '');
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    final looksBase64 =
        maybeBase64.length % 4 == 0 && base64Regex.hasMatch(maybeBase64);
    if (looksBase64) {
      try {
        final Uint8List bytes = base64Decode(maybeBase64);
        return _imageBox(Image.memory(bytes, fit: BoxFit.cover));
      } catch (_) {}
    }

    return _imageBox(
      Image.network(
        s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      ),
    );
  }

  Widget _imageBox(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(aspectRatio: 16 / 9, child: child),
      );

  Widget _imagePlaceholder() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: const Color(0xFFE9ECF4),
            child: const Icon(Icons.image_not_supported_outlined,
                size: 36, color: Colors.grey),
          ),
        ),
      );

  // ============== LAYOUT HELPERS (responsive) ==============
  int _columnsForSize(Size size) {
    final w = size.width;
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 3;
    return 2;
  }

  double _aspectForSize(Size size) {
    final w = size.width;
    final h = size.height;
    if (h < 640) return 0.52;
    if (w < 360) return 0.55;
    if (w < 420) return 0.58;
    if (w < 520) return 0.62;
    return 0.66;
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RepresentantHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cols = _columnsForSize(size);
    final aspect = _aspectForSize(size);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        automaticallyImplyLeading: false, // no back arrow
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 12),
            _Logo(),
            SizedBox(width: 12),
            Text(
              "Espace Achat",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderListScreen()),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Column(
        children: [
          _TopTabs(onChoixClient: _goHome),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: DropdownButtonFormField<String>(
              value: selectedCategory.isEmpty ? null : selectedCategory,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: const Text("Filtrer par catégorie"),
              isExpanded: true,
              items: allProducts
                  .map((p) => p.category)
                  .toSet()
                  .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) => _filterProducts(value ?? ''),
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: aspect,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                final controller = qtyControllers.putIfAbsent(
                  product.id!,
                  () => TextEditingController(),
                );

                return _ProductTile(
                  product: product,
                  controller: controller,
                  onOrder: (qty) => _commanderProduit(product, qty),
                  imageBuilder: _productImage,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------- Small UI pieces ----------------- */

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png', height: 34);
  }
}

class _TopTabs extends StatelessWidget {
  final VoidCallback onChoixClient;
  const _TopTabs({required this.onChoixClient});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: const Color(0xFF0D47A1),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _TabBtn('CHOIX CLIENT', onChoixClient),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TabBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/* ----------------- Product tile (responsive) ----------------- */

class _ProductTile extends StatelessWidget {
  final Product product;
  final TextEditingController controller;
  final void Function(int qty) onOrder;
  final Widget Function(String src) imageBuilder;

  const _ProductTile({
    required this.product,
    required this.controller,
    required this.onOrder,
    required this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: imageBuilder(product.imageUrl)),
          const SizedBox(height: 8),

          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),

          Text(
            "${product.price.toStringAsFixed(3)} TND",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.indigo, fontSize: 13),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Quantité",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              if (qty > 0) {
                onOrder(qty);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Quantité invalide")),
                );
              }
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text("Commander"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/admin_order_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'representant_list_screen.dart';
import 'admin_reclamation_screen.dart';
import 'admin_visit_screen.dart';

const kPrimaryBlue = Color(0xFF0D47A1);

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  int _selectedIndex = 0;
  List<Product> products = [];
  List<Product> filtered = [];
  bool isLoading = true;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(() {
      _applyFilter(_searchCtrl.text);
    });
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        products = result;
        filtered = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement produits: $e")),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _applyFilter(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() => filtered = products);
    } else {
      setState(() {
        filtered = products.where((p) {
          return p.itmdes1.toLowerCase().contains(q) ||
              p.itmref.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q) ||
              (p.DESIGNATIONCategorie.toLowerCase()).contains(q) ||
              (p.DesignationFamille.toLowerCase()).contains(q) ||
              (p.DesignationSousFamille.toLowerCase()).contains(q) ||
              (p.DesignationGamme.toLowerCase()).contains(q) ||
              (p.DesignationSKU.toLowerCase()).contains(q) ||
              p.prix.toString().toLowerCase().contains(q);
        }).toList();
      });
    }
  }

  Future<void> _performLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter')),
        ],
      ),
    );
    if (ok == true) await _performLogout();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildProductPage(),
      const DashboardScreen(),
      const RepresentantListScreen(),
      const AdminOrderScreen(),
      const AdminReclamationScreen(),
      const AdminVisiteScreen(),
    ];

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Image.asset('assets/logo.png', height: 34),
            const Spacer(),
          ],
        ),
        actions: [
          if (isMobile)
            IconButton(
              tooltip: 'Se déconnecter',
              icon: const Icon(Icons.logout, color: Colors.black87),
              onPressed: _confirmLogout,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Déconnexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black26),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
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
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            label: 'Réclamations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Visites',
          ),
        ],
      ),
    );
  }

  Widget _buildProductPage() {
    final size = MediaQuery.of(context).size;
    final cols = size.width < 500 ? 2 : (size.width < 800 ? 3 : 4);
    final aspect = cols == 2 ? 0.65 : (cols == 3 ? 0.7 : 0.75);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const Center(child: Text("Aucun produit."));
    }

    return Column(
      children: [
        // 🔎 Même search bar que AdminReclamationScreen
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: "Rechercher...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            itemBuilder: (_, i) {
              final p = filtered[i];
              return _ProductTile(product: p, onImageUpdated: _loadProducts);
            },
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatefulWidget {
  final Product product;
  final Future<void> Function() onImageUpdated;
  const _ProductTile({super.key, required this.product, required this.onImageUpdated});

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'], // 🔹 uniquement PNG
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImageBytes = result.files.first.bytes;
        _pickedImageName = "${widget.product.itmref}.png"; // 🔹 forcé PNG
      });

      try {
        await ApiService.updateProductImage(
          widget.product.itmref,
          _pickedImageBytes!,
          _pickedImageName!,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Image PNG mise à jour avec succès")),
        );
        await widget.onImageUpdated(); // 🔄 recharge toute la liste depuis API
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur upload image: $e")),
        );
      }
    }
  }

  Widget _imageBox(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(aspectRatio: 16 / 9, child: child),
      );

  Widget _imagePlaceholder() => _imageBox(
        Container(
          color: const Color(0xFFE9ECF4),
          child: const Icon(Icons.image_not_supported_outlined,
              size: 36, color: Colors.grey),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // ✅ ajout d’un cache-buster
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;

    final imgWidget = _pickedImageBytes != null
        ? _imageBox(Image.memory(_pickedImageBytes!, fit: BoxFit.cover))
        : _imageBox(
            Image.network(
              "${widget.product.fullImageUrl}?v=$cacheBuster", // 🔹 anti-cache
              fit: BoxFit.cover,
              headers: {"Cache-Control": "no-cache"}, // 🔹 force refresh
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            ),
          );

    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Changer l’image"),
            content: const Text("Voulez-vous sélectionner une nouvelle image PNG ?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Choisir")),
            ],
          ),
        );

        if (ok == true) {
          await _pickImage();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: imgWidget),
          const SizedBox(height: 8),
          Text(widget.product.itmdes1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text("${widget.product.itmref}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black, fontSize: 13)),
          Text("${widget.product.prix.toStringAsFixed(3)} TND",
              textAlign: TextAlign.center,
              style: const TextStyle(color: kPrimaryBlue, fontSize: 13)),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/offline_cache.dart';
import 'representant_home_page.dart';

const kPrimaryBlue = Color(0xFF0D47A1);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _qCtrl = TextEditingController();
  final TextEditingController _cartNoteCtrl = TextEditingController();
  final Map<String, String> _searchIndex = {};
  final Map<String, _CartEntry> _cart = {};

  static const _kCartNoteKey = 'cart_note_text';
  List<Product> allProducts = [];
  List<Product> filtered = [];
  int cartCount = 0;
  DateTime _deliveryDate = DateTime.now();

  // 🔹 Filter selections
  String? selectedGamme;
  String? selectedCategorie;
  String? selectedFamille;
  String? selectedSousFamille;
  String? selectedSKU;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartNote();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _cartNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCartNote() async {
    final sp = await SharedPreferences.getInstance();
    _cartNoteCtrl.text = sp.getString(_kCartNoteKey) ?? '';
  }

  Future<void> _saveCartNote() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCartNoteKey, _cartNoteCtrl.text.trim());
  }

  Future<void> _loadProducts() async {
    try {
      final online = await ApiService.ping();
      if (online) {
        final products = await ApiService.getProducts();
        if (!mounted) return;
        await OfflineCache.saveProducts(products.map((p) => p.toJson()).toList());
        setState(() {
          allProducts = products;
          filtered = products;
        });
        _rebuildSearchIndex();
      } else {
        final cached = OfflineCache.getProducts();
        if (cached.isNotEmpty) {
          final products = cached.map((e) => Product.fromJson(e)).toList();
          if (!mounted) return;
          setState(() {
            allProducts = products;
            filtered = products;
          });
          _rebuildSearchIndex();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Mode hors ligne : produits chargés du cache.")));
        }
      }
    } catch (e) {
      final cached = OfflineCache.getProducts();
      if (cached.isNotEmpty) {
        final products = cached.map((e) => Product.fromJson(e)).toList();
        if (!mounted) return;
        setState(() {
          allProducts = products;
          filtered = products;
        });
        _rebuildSearchIndex();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Mode hors ligne : produits chargés du cache.")));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur chargement produits: $e")));
      }
    }
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  void _rebuildSearchIndex() {
    _searchIndex.clear();
    for (final p in allProducts) {
      final buf = StringBuffer()
        ..write(' ${p.id}')
        ..write(' ${p.itmref}')
        ..write(' ${p.itmdes1}')
        ..write(' ${p.Categorie}')
        ..write(' ${p.Gamme}')
        ..write(' ${p.Famille}')
        ..write(' ${p.SousFamille}')
        ..write(' ${p.SKU}')
        ..write(' ${p.DESIGNATIONCategorie}')
        ..write(' ${p.DesignationGamme}')
        ..write(' ${p.DesignationFamille}')
        ..write(' ${p.DesignationSousFamille}')
        ..write(' ${p.DesignationSKU}')
        ..write(' ${p.prix.toStringAsFixed(3)}')
        ..write(' ${p.Quantity}');
      _searchIndex[p.itmref.isNotEmpty ? p.itmref : p.id] = _norm(buf.toString());
    }
  }

  void _applyGlobalFilter(String query) {
    final q = _norm(query);
    if (q.isEmpty) {
      setState(() => filtered = List<Product>.from(allProducts));
      return;
    }
    setState(() {
      filtered = allProducts.where((p) => (_searchIndex[p.id] ?? '').contains(q)).toList();
    });
  }

  int _qtyOf(String id) => _cart[id]?.qty ?? 0;

  void _inc(Product p) {
    setState(() {
      _cart[p.id] = _CartEntry(product: p, qty: _qtyOf(p.id) + 1);
      cartCount = _cart.length;
    });
  }

  void _dec(String id) {
    setState(() {
      final entry = _cart[id];
      if (entry == null) return;
      if (entry.qty <= 1) _cart.remove(id);
      else _cart[id] = entry.copyWith(qty: entry.qty - 1);
      cartCount = _cart.length;
    });
  }

  void _updateCartQty(Product p, int newQty) {
    setState(() {
      if (newQty <= 0) _cart.remove(p.id);
      else _cart[p.id] = _CartEntry(product: p, qty: newQty);
      cartCount = _cart.length;
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      cartCount = 0;
      _cartNoteCtrl.clear();
      _deliveryDate = DateTime.now();
    });
  }

  double get _cartTotal => _cart.values.fold(0.0, (s, e) => s + e.qty * e.product.prix);
  int get _cartLines => _cart.length;

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Panier vide")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('clientId') ?? '';
    final nomClient = prefs.getString('NomClient') ?? '';
    final adresseClient = prefs.getString('AdresseClient') ?? '';
    final nomRep = prefs.getString('NomRep') ?? '';
    final codeRep = prefs.getString('CodeRep') ?? '';

    final items = _cart.values.map((e) {
      return {
        'itmref': e.product.itmref,
        'quantity': e.qty,
        'unitPrice': e.product.prix,
        'totalPrice': e.product.prix * e.qty,
      };
    }).toList();

    final reference = "REF-${DateTime.now().millisecondsSinceEpoch}";

    try {
      await ApiService.createOrder(
        clientId: clientId,
        nomClient: nomClient,
        adresseClient: adresseClient,
        codeRep: codeRep,
        nomRep: nomRep,
        note: _cartNoteCtrl.text.trim(),
        reference: reference,
        items: items,
        dateLivraison: _deliveryDate,
      );

      if (!mounted) return;
      _clearCart();
      await _saveCartNote();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Commande validée avec succès ✅")));
    } catch (e) {
      await OfflineCache.saveOrder({
        "clientId": clientId,
        "nomClient": nomClient,
        "adresseClient": adresseClient,
        "codeRep": codeRep,
        "nomRep": nomRep,
        "reference": reference,
        "items": items,
        "note": _cartNoteCtrl.text.trim(),
        "deliveryDate": _deliveryDate.toIso8601String(),
      });

      if (!mounted) return;
      _clearCart();
      await _saveCartNote();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Commande enregistrée en mode hors ligne (sera synchronisée plus tard).")));
    }
  }

  // -------------------- FILTER DIALOG --------------------
  // 🔹 Construit un champ Dropdown stylé pour les filtres
Widget _buildDropdown(
  String label,
  List<String> items,
  String? selected,
  Function(String?) onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selected,
             isExpanded: true, // ✅ empêche l’overflow
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: items.map((e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis, // ✅ coupe le texte si trop long
                  
                 style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),

        // 🔸 Bouton "Effacer" individuel (optionnel)
        if (selected != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.redAccent, size: 20),
            tooltip: "Effacer ce filtre",
            onPressed: () => onChanged(null),
          ),
      ],
    ),
  );
}

void _openFilterDialog() {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Filtres de recherche",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setModal) {
            // ✅ Affiche les désignations au lieu des codes
            
            List<String> categories = allProducts
                .map((p) => p.DESIGNATIONCategorie)
                .whereType<String>()
                .toSet()
                .toList();
                List<String> gammes = allProducts
                .map((p) => p.DesignationGamme)
                .whereType<String>()
                .toSet()
                .toList();
            List<String> familles = allProducts
                .map((p) => p.DesignationFamille)
                .whereType<String>()
                .toSet()
                .toList();
            List<String> sousFamilles = allProducts
                .map((p) => p.DesignationSousFamille)
                .whereType<String>()
                .toSet()
                .toList();
            List<String> skus = allProducts
                .map((p) => p.DesignationSKU)
                .whereType<String>()
                .toSet()
                .toList();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdown(
                      "Catégorie", categories, selectedCategorie, (v) => setModal(() => selectedCategorie = v)),
                  _buildDropdown(
                      "Gamme", gammes, selectedGamme, (v) => setModal(() => selectedGamme = v)),
                  _buildDropdown(
                      "Famille", familles, selectedFamille, (v) => setModal(() => selectedFamille = v)),
                  _buildDropdown(
                      "Sous Famille", sousFamilles, selectedSousFamille, (v) => setModal(() => selectedSousFamille = v)),
                  _buildDropdown(
                      "SKU", skus, selectedSKU, (v) => setModal(() => selectedSKU = v)),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedGamme = null;
                selectedCategorie = null;
                selectedFamille = null;
                selectedSousFamille = null;
                selectedSKU = null;
                filtered = allProducts;
              });
              Navigator.pop(ctx);
            },
            child: const Text("Réinitialiser"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              _applyFilterSelection();
              Navigator.pop(ctx);
            },
            child: const Text("Appliquer"),
          ),
        ],
      );
    },
  );
}

void _applyFilterSelection() {
  setState(() {
    filtered = allProducts.where((p) {
      final matchGamme =
          selectedGamme == null || p.DesignationGamme == selectedGamme;
      final matchCat =
          selectedCategorie == null || p.DESIGNATIONCategorie == selectedCategorie;
      final matchFam =
          selectedFamille == null || p.DesignationFamille == selectedFamille;
      final matchSousFam = selectedSousFamille == null ||
          p.DesignationSousFamille == selectedSousFamille;
      final matchSku =
          selectedSKU == null || p.DesignationSKU == selectedSKU;

      return matchGamme && matchCat && matchFam && matchSousFam && matchSku;
    }).toList();
  });
  
}

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    int cols = size.width < 600 ? 2 : size.width < 900 ? 3 : 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(children: const [SizedBox(width: 8), _Logo()]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RepresentantHomePage()),
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                  onPressed: _openCartSheet),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Search + Filter icon
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    onChanged: _applyGlobalFilter,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: (_qCtrl.text.isEmpty)
                          ? null
                          : IconButton(icon: const Icon(Icons.clear), onPressed: () => _applyGlobalFilter("")),
                      hintText: "Rechercher...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: kPrimaryBlue),
                  tooltip: "Filtrer",
                  onPressed: _openFilterDialog,
                ),
              ],
            ),
          ),

        Expanded(
  child: filtered.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off, size: 70, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "Aucun produit trouvé",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        )
      : GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: size.width < 600 ? 0.95 : 0.8,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final p = filtered[i];
            return _ShopTile(
              product: p,
              qty: _qtyOf(p.id),
              onMinus: () => _dec(p.id),
              onPlus: () => _inc(p),
              onUpdate: (newQty) => _updateCartQty(p, newQty),
            );
          },
        ),
),

          if (_cart.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_cartLines article(s) • Total: ${_cartTotal.toStringAsFixed(3)} TND',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _clearCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Vider'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Valider'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openCartSheet() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Panier vide")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(ctx).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🛒 Mon Panier",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView(
                        children: _cart.values.map((e) {
                          return ListTile(
                            title: Text(e.product.itmdes1),
                            subtitle: Text("Code: ${e.product.itmref}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () => setModal(() => _dec(e.product.id))),
                                Text("${e.qty}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: kPrimaryBlue),
                                    onPressed: () => setModal(() => _inc(e.product))),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    TextField(
                      controller: _cartNoteCtrl,
                      decoration: const InputDecoration(
                        labelText: "Note du panier",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "📅 Livraison : ${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: kPrimaryBlue),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: _deliveryDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModal(() => _deliveryDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Total : ${_cartTotal.toStringAsFixed(3)} TND",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  setModal(() {
                                    _clearCart();
                                    _cartNoteCtrl.clear();
                                    _deliveryDate = DateTime.now();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text("Vider", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _checkout();
                                  setModal(() {
                                    _cartNoteCtrl.clear();
                                    _deliveryDate = DateTime.now();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text("Valider", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ------------------- Logo ------------------- */
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png', height: 32);
  }
}

/* ------------------- Product Card ------------------- */
class _ShopTile extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final Function(int) onUpdate;

  const _ShopTile({
    required this.product,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final controller = TextEditingController(text: qty.toString());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: EdgeInsets.all(isSmall ? 6 : 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: product.fullImageUrl, // ✅ reste ton URL
              height: isSmall ? 70 : 120,
              fit: BoxFit.contain,
              placeholder: (ctx, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (ctx, url, error) =>
                  const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          Text(product.itmdes1,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isSmall ? 11 : 13, fontWeight: FontWeight.w600)),
          Text("${product.prix.toStringAsFixed(3)} TND",
              style: TextStyle(color: kPrimaryBlue, fontSize: isSmall ? 11 : 13)),
          const Spacer(),
          SizedBox(
            height: isSmall ? 34 : 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _qtyBtn(icon: Icons.remove, onTap: onMinus, enabled: qty > 0),
                SizedBox(
                  width: isSmall ? 35 : 45,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    onSubmitted: (v) {
                      final newQty = int.tryParse(v) ?? qty;
                      onUpdate(newQty);
                    },
                  ),
                ),
                _qtyBtn(icon: Icons.add, onTap: onPlus),
              ],
            ),
          )
        ],
      ),
    );
  }}

Widget _qtyBtn({required IconData icon, required VoidCallback onTap, bool enabled = true}) {
  return SizedBox(
    width: 32,
    height: 32,
    child: ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Icon(icon, size: 16),
    ),
  );
}

/* ----------------- Cart Entry ----------------- */
class _CartEntry {
  final Product product;
  final int qty;
  _CartEntry({required this.product, required this.qty});
  _CartEntry copyWith({Product? product, int? qty}) =>
      _CartEntry(product: product ?? this.product, qty: qty ?? this.qty);
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/offline_cache.dart';
import 'representant_home_page.dart';

// -------- THEME COLOR (navbar blue) --------
const kPrimaryBlue = Color(0xFF0D47A1);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _qCtrl = TextEditingController();
  final Map<String, String> _searchIndex = {};
  final Map<String, _CartEntry> _cart = {};
  final TextEditingController _cartNoteCtrl = TextEditingController();

  static const _kCartNoteKey = 'cart_note_text';

  List<Product> allProducts = [];
  List<Product> filtered = [];
  int cartCount = 0;

  // ✅ Nouvelle variable : date de livraison
  DateTime _deliveryDate = DateTime.now();

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

  // -------------------- PRODUITS OFFLINE --------------------
  Future<void> _loadProducts() async {
    try {
      final online = await ApiService.ping();
      if (online) {
        final products = await ApiService.getProducts();
        if (!mounted) return;

        await OfflineCache.saveProducts(
            products.map((p) => p.toJson()).toList());

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Mode hors ligne: produits chargés du cache.")),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Mode hors ligne: produits chargés du cache.")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur chargement produits: $e")),
        );
      }
    }
  }

  // ---------------------- SEARCH ----------------------
  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  void _rebuildSearchIndex() {
    _searchIndex.clear();
    for (final p in allProducts) {
      final buf = StringBuffer()
        ..write(' ${p.itmdes1}')
        ..write(' ${p.itmref}')
        ..write(' ${p.id}')
        ..write(' ${p.DESIGNATIONCategorie}')
        ..write(' ${p.DesignationFamille}')
        ..write(' ${p.DesignationSousFamille}')
        ..write(' ${p.DesignationGamme}')
        ..write(' ${p.DesignationSKU}')
        ..write(' ${p.Quantity}')
        ..write(' ${p.tclcod}')
        ..write(' ${p.id_famillearticle}')
        ..write(' ${p.id_souscategorie}')
        ..write(' ${p.prix.toStringAsFixed(3)}');
      _searchIndex[p.id] = _norm(buf.toString());
    }
  }

  void _applyGlobalFilter(String query) {
    final q = _norm(query);
    if (q.isEmpty) {
      setState(() => filtered = List<Product>.from(allProducts));
      return;
    }
    final tokens = q.split(' ').where((t) => t.isNotEmpty).toList();
    setState(() {
      filtered = allProducts.where((p) {
        final hay = _searchIndex[p.id] ?? '';
        for (final t in tokens) {
          if (!hay.contains(t)) return false;
        }
        return true;
      }).toList();
    });
  }

  void _clearSearch() {
    _qCtrl.clear();
    _applyGlobalFilter('');
  }

  // ---------------------------- CART -----------------------------
  int _qtyOf(String productId) => _cart[productId]?.qty ?? 0;

  void _inc(Product product) {
    final key = product.id;
    final entry = _cart[key];
    setState(() {
      if (entry == null) {
        _cart[key] = _CartEntry(product: product, qty: 1);
      } else {
        _cart[key] = entry.copyWith(qty: entry.qty + 1);
      }
      cartCount = _cart.length;
    });
  }

  void _dec(String productId) {
    final entry = _cart[productId];
    if (entry == null) return;
    setState(() {
      final newQty = entry.qty - 1;
      if (newQty <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = entry.copyWith(qty: newQty);
      }
      cartCount = _cart.length;
    });
  }

  void _updateCartQty(Product product, int newQty) {
    final key = product.id;
    setState(() {
      if (newQty <= 0) {
        _cart.remove(key);
      } else {
        _cart[key] = _CartEntry(product: product, qty: newQty);
      }
      cartCount = _cart.length;
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      cartCount = 0;
    });
  }

  double get _cartTotal =>
      _cart.values.fold<double>(0.0, (s, e) => s + e.qty * e.product.prix);
  int get _cartLines => _cart.length;

  // -------------------- CHECKOUT --------------------
  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Panier vide")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('clientId') ?? '';
    final nomClient = prefs.getString('NomClient') ?? '';
    final adresseClient = prefs.getString('AdresseClient') ?? '';
    final nomRep = prefs.getString('NomRep') ?? '';
    final codeRep = prefs.getString('CodeRep') ?? '';

    final items = _cart.values.map((e) {
      final unit = e.product.prix;
      return {
        'itmref': e.product.itmref,
        'quantity': e.qty,
        'unitPrice': unit,
        'totalPrice': unit * e.qty,
      };
    }).toList();

    final orderPayload = {
      "clientId": clientId,
      "nomClient": nomClient,
      "adresseClient": adresseClient,
      "codeRep": codeRep,
      "nomRep": nomRep,
      "reference": "REF-${DateTime.now().millisecondsSinceEpoch}",
      "items": items,
      "isSynced": false,
      "createdAt": DateTime.now().toIso8601String(),
      "note": _cartNoteCtrl.text.trim(),
      "deliveryDate": _deliveryDate.toIso8601String(), // ✅ ajout
    };

    try {
      await ApiService.createOrder(
        clientId: clientId,
        nomClient: nomClient,
        adresseClient: adresseClient,
        codeRep: codeRep,
        nomRep: nomRep,
        note: _cartNoteCtrl.text.trim(),
        reference: orderPayload['reference']?.toString() ?? '',
        items: items,
        dateLivraison: _deliveryDate, // ✅ ajout
      );

      if (!mounted) return;
      _clearCart();
      await _saveCartNote();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Commande créée avec succès.")),
      );
    } catch (e) {
      await OfflineCache.saveOrder(orderPayload);

      if (!mounted) return;
      _clearCart();
      await _saveCartNote();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Commande enregistrée en offline (sync plus tard).")),
      );
    }
  }

  // -------------------- UI --------------------
  void _openCartSheet() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Panier vide")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void inc(Product p) {
              _inc(p);
              setModalState(() {});
            }

            void dec(String id) {
              _dec(id);
              setModalState(() {});
            }

            void clearCart() {
              _clearCart();
              setModalState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Mon Panier",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: _cart.values.map((e) {
                          return Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text(e.product.itmdes1),
                                  subtitle: Text("code: ${e.product.itmref}"),
                                ),
                              ),
                              _qtyBtn(
                                  icon: Icons.remove,
                                  onTap: () => dec(e.product.id)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text("${e.qty}",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                              _qtyBtn(
                                  icon: Icons.add,
                                  onTap: () => inc(e.product)),
                              const SizedBox(width: 12),
                              Text(
                                  "${e.qty} x ${e.product.prix.toStringAsFixed(3)}"),
                            ],
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

                    // ✅ Nouveau champ Date Livraison
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date de livraison: ${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: kPrimaryBlue),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _deliveryDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _deliveryDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total: ${_cartTotal.toStringAsFixed(3)} TND",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: clearCart,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white),
                              child: const Text("Vider"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _checkout();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryBlue,
                                  foregroundColor: Colors.white),
                              child: const Text("Commander"),
                            ),
                          ],
                        )
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cols = size.width >= 900 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              nav.pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const RepresentantHomePage()),
              );
            }
          },
          tooltip: 'Retour',
        ),
        title: Row(
          children: const [
            SizedBox(width: 8),
            _Logo(),
            SizedBox(width: 12),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.black87),
                onPressed: _openCartSheet,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cartCount',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10),
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
            child: TextField(
              controller: _qCtrl,
              onChanged: _applyGlobalFilter,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_qCtrl.text.isEmpty)
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                hintText: "Rechercher...",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 0.66,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _ShopTile(
                  product: product,
                  qty: _qtyOf(product.id),
                  onMinus: () => _dec(product.id),
                  onPlus: () => _inc(product),
                  onUpdate: (newQty) => _updateCartQty(product, newQty),
                );
              },
            ),
          ),
          if (_cart.isNotEmpty) _buildCartSummary(),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Vider'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Commander',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RepresentantHomePage()),
      (route) => false,
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
      color: kPrimaryBlue,
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
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

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
    final hasQty = qty > 0;
    final controller = TextEditingController(text: qty.toString());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.fullImageUrl,
                key: ValueKey(product.fullImageUrl),
                fit: BoxFit.cover,
                headers: const {"Cache-Control": "no-cache"},
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 36,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.itmdes1,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "code: ${product.itmref}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            "${product.prix.toStringAsFixed(3)} TND",
            textAlign: TextAlign.center,
            style: const TextStyle(color: kPrimaryBlue, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            "${product.DESIGNATIONCategorie} • ${product.DesignationFamille}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                _qtyBtn(icon: Icons.remove, onTap: onMinus, enabled: hasQty),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 45,
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        onSubmitted: (value) {
                          final newQty = int.tryParse(value) ?? qty;
                          onUpdate(newQty);
                        },
                      ),
                    ),
                  ),
                ),
                _qtyBtn(icon: Icons.add, onTap: onPlus, enabled: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _qtyBtn({
  required IconData icon,
  required VoidCallback onTap,
  bool enabled = true,
}) {
  return SizedBox(
    width: 44,
    height: 40,
    child: ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Icon(icon, size: 18),
    ),
  );
}

/* ----------------- Local cart entry ----------------- */
class _CartEntry {
  final Product product;
  final int qty;

  _CartEntry({required this.product, required this.qty});

  _CartEntry copyWith({Product? product, int? qty}) =>
      _CartEntry(product: product ?? this.product, qty: qty ?? this.qty);
}

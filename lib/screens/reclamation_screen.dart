import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_cache.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart';
import '../data/api_config.dart'; // <-- import for apiRoot

class ReclamationScreen extends StatefulWidget {
  final String representant;
  final String client;
  final String telephone;

  const ReclamationScreen({
    super.key,
    required this.representant,
    required this.client,
    required this.telephone,
  });

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  static const _brandBlue = Color(0xFF0F57A3);
  static const _bg = Color(0xFFF5F6FA);
  static const _radius = 14.0;

  final TextEditingController _reclamNo = TextEditingController();
  final TextEditingController _dateReclam = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _telephone = TextEditingController();

  int? _userId;
  bool _submitting = false;

  List<Product> _allProducts = [];
  bool _loadingProducts = true;

  final Map<String, bool> retourLivraison = {
    'Erreur CMD': false,
    'Dommage Transport': false,
    'Paiement Non Dispo': false,
    'Erreur Fabrication': false,
    'Autre Raison': false,
  };

  final Map<String, bool> echange = {
    'Défaut de fabrication': false,
    'Casse': false,
    'Décoloration': false,
    'Date de péremption': false,
    'Autre Raison': false,
  };

  final List<_ArticleRow> _articles = [];

  @override
  void initState() {
    super.initState();
    _dateReclam.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    _telephone.text = widget.telephone;
    _loadUserId();
    _fetchProducts();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
  }

  Future<void> _fetchProducts() async {
  try {
    // 🔹 Try online first
    final products = await ApiService.getProducts();

    // Save them offline
    await OfflineCache.saveProducts(products.map((p) => p.toJson()).toList());

    if (!mounted) return;
    setState(() {
      _allProducts = products;
      _loadingProducts = false;
    });
  } catch (e) {
    // 🔹 Offline fallback
    final cached = OfflineCache.getProducts();
    if (cached.isNotEmpty) {
      final products = cached.map((e) => Product.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _loadingProducts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📴 Mode hors ligne : produits du cache.")),
      );
    } else {
      setState(() => _loadingProducts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur chargement produits: $e")),
      );
    }
  }
}

  String _joinSelected(Map<String, bool> m) =>
      m.entries.where((e) => e.value).map((e) => e.key).join(', ');

  Future<void> _pickDate(TextEditingController c) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      c.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _submit() async {
  if (_userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Utilisateur non identifié.")),
    );
    return;
  }

  if (_note.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Veuillez saisir une note.")),
    );
    return;
  }
  if (_joinSelected(retourLivraison).isEmpty &&
      _joinSelected(echange).isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sélectionnez au moins une raison.")),
    );
    return;
  }

  setState(() => _submitting = true);

  final payload = {
    "dateReclamation": _dateReclam.text,
    "representant": widget.representant,
    "client": widget.client,
    "telephone": _telephone.text,
    "note": _note.text.trim(),
    "retourLivraison": _joinSelected(retourLivraison),
    "echange": _joinSelected(echange),
    "articles": _articles.map((a) => a.toJson()).toList(),
    "userId": _userId,
    "isSynced": false,
  };

  final hasNet = await Connectivity().checkConnectivity() != ConnectivityResult.none;

  if (hasNet) {
    try {
      final url = Uri.parse("$apiRoot/reclamation");
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Réclamation envoyée !")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur : ${res.body}")),
        );
      }
    } catch (e) {
      await OfflineCache.queueReclamation(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📴 Hors ligne : réclamation sauvegardée.")),
      );
    }
  } else {
    await OfflineCache.queueReclamation(payload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📴 Hors ligne : réclamation mise en attente.")),
    );
  }

  if (mounted) setState(() => _submitting = false);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: TrikiAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Retour',
        ),
        blueNavItems: const [
          BlueNavItem(label: "RECLAMATION", selected: true),
        ],
        blueNavVariant: BlueNavbarVariant.textOnly,
      ),
      body: _loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _SectionCard(
                  child: LayoutBuilder(builder: (context, c) {
                    final oneCol = c.maxWidth < 640;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _input("Reclamation N°", _reclamNo, readOnly: true,
                            width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                        _input("Date Réclamation", _dateReclam, readOnly: true,
                            suffix: IconButton(
                              icon: const Icon(Icons.event),
                              onPressed: () => _pickDate(_dateReclam),
                            ),
                            width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                        _input("Représentant",
                            TextEditingController(text: widget.representant),
                            readOnly: true,
                            width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                        _input("Client", TextEditingController(text: widget.client),
                            readOnly: true,
                            width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                        _input("Téléphone", _telephone,
                            keyboard: TextInputType.phone,
                            width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                        _input("Note", _note,
                            width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                _SectionCard(title: "Retour Livraison", child: _checkboxWrap(retourLivraison)),
                const SizedBox(height: 12),
                _SectionCard(title: "Échange", child: _checkboxWrap(echange)),
                const SizedBox(height: 12),
                _SectionCard(
                  title: "Articles",
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      ..._articles.map((a) => _articleRow(a)).toList(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _articles.add(_ArticleRow())),
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("ENVOYER"),
                  ),
                ),
              ],
            ),
    );
  }

  // ----------------- helpers -----------------

  Widget _checkboxWrap(Map<String, bool> map) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: map.keys.map((k) {
        final v = map[k] ?? false;
        return FilterChip(
          label: Text(k),
          selected: v,
          onSelected: (sel) => setState(() => map[k] = sel),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: v ? Colors.white : Colors.black87,
          ),
          selectedColor: _brandBlue,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboard,
    Widget? suffix,
    double? width,
  }) {
    final field = TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(_radius)),
        suffixIcon: suffix,
      ),
    );
    if (width == null) return field;
    return SizedBox(width: width, child: field);
  }

  Widget _articleRow(_ArticleRow a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<Product>(
              value: a.selectedProduct,
              isExpanded: true,
              items: _allProducts.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.itmref));
              }).toList(),
              onChanged: (val) => setState(() => a.selectedProduct = val),
              decoration: const InputDecoration(labelText: "Code Article"),
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<Product>(
              value: a.selectedProduct,
              isExpanded: true,
              items: _allProducts.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.itmdes1));
              }).toList(),
              onChanged: (val) => setState(() => a.selectedProduct = val),
              decoration: const InputDecoration(labelText: "Nom Article"),
            ),
          ),
          _smallField(a.qtyCtrl, hint: "Qté", keyboard: TextInputType.number),
          _smallField(a.dateFabCtrl,
              hint: "Date Fab", readOnly: true, onTap: () => _pickDate(a.dateFabCtrl)),
          _smallField(a.factureNoCtrl, hint: "N° Facture"),
          _smallField(a.dateFactureCtrl,
              hint: "Date Fac", readOnly: true, onTap: () => _pickDate(a.dateFactureCtrl)),
          _smallField(a.montantCtrl, hint: "Montant", keyboard: TextInputType.number),
          _smallField(a.obsCtrl, hint: "Observation"),
          IconButton(
            onPressed: () => setState(() => _articles.remove(a)),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// ----------------- support classes -----------------

class _ArticleRow {
  Product? selectedProduct;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController dateFabCtrl = TextEditingController();
  final TextEditingController factureNoCtrl = TextEditingController();
  final TextEditingController dateFactureCtrl = TextEditingController();
  final TextEditingController montantCtrl = TextEditingController();
  final TextEditingController obsCtrl = TextEditingController();

  Map<String, dynamic> toJson() => {
        "codeArticle": selectedProduct?.itmref ?? "",
        "nomArticle": selectedProduct?.itmdes1 ?? "",
        "quantite": qtyCtrl.text,
        "dateFabrication": dateFabCtrl.text,
        "factureNo": factureNoCtrl.text,
        "dateFacture": dateFactureCtrl.text,
        "montant": montantCtrl.text,
        "observation": obsCtrl.text,
      };
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_ReclamationScreenState._radius)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(title!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _smallField(
  TextEditingController c, {
  required String hint,
  TextInputType? keyboard,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return SizedBox(
    width: 120,
    child: TextField(
      controller: c,
      onTap: onTap,
      readOnly: readOnly,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(_ReclamationScreenState._radius),
        ),
      ),
    ),
  );
}

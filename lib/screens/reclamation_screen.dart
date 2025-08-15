import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reclamation_list_screen.dart';

class ReclamationScreen extends StatefulWidget {
  final String representant;
  final String client;
  final String telephone;
  final int userId;

  const ReclamationScreen({
    super.key,
    required this.representant,
    required this.client,
    required this.telephone,
    required this.userId,
  });

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  // Theme
  static const _brandBlue = Color(0xFF0F57A3);
  static const _bg = Color(0xFFF5F6FA);
  static const _radius = 14.0;

  // Controllers
  final TextEditingController _reclamNo = TextEditingController();
  final TextEditingController _dateReclam = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _telephone = TextEditingController();

  bool _submitting = false;

  // Reasons
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

  // Articles rows
  final List<_ArticleRow> _articles = [];

  @override
  void initState() {
    super.initState();
    _reclamNo.text = _todayCode();
    _dateReclam.text = _now();
    _telephone.text = widget.telephone;
  }

  String _todayCode() {
    final d = DateTime.now();
    return "${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}";
  }

  String _now() => DateTime.now().toString().split('.').first;

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
      c.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _submit() async {
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

    final url = Uri.parse("http://192.168.0.103:5274/api/reclamation");
    final body = jsonEncode({
      "reclamationNo": _reclamNo.text,
      "dateReclamation": _dateReclam.text,
      "representant": widget.representant,
      "client": widget.client,
      "telephone": _telephone.text,
      "note": _note.text.trim(),
      "retourLivraison": _joinSelected(retourLivraison),
      "echange": _joinSelected(echange),
      "articles": _articles.map((a) => a.toJson()).toList(),
      "userId": widget.userId,
    });

    try {
      final res =
          await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Réclamation envoyée !")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ReclamationListScreen(userId: widget.userId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${res.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau : $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ===== Two-tier header: white top (logo) + blue bar with title =====
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White strip with back + logo
            Container(
              color: Colors.white,
              height: 48,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Image.asset('assets/logo.png', height: 24),
                  ],
                ),
              ),
            ),
            // Blue navbar with centered text ONLY
            Container(
              height: 38,
              width: double.infinity,
              color: _brandBlue,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                "RECLAMATION",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),

      // ===== Content =====
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "Formulaire d’autorisation de retour des produits ou d’étude de l’échange.",
              style: TextStyle(color: Colors.black54, fontSize: 12.5),
            ),
          ),

          // Top grid
          _SectionCard(
            child: LayoutBuilder(builder: (context, c) {
              final oneCol = c.maxWidth < 640;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _input("Reclamation N°", _reclamNo,
                      readOnly: true,
                      width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                  _input("Date Réclamation", _dateReclam,
                      readOnly: true,
                      suffix: IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () => _pickDate(_dateReclam),
                      ),
                      width: oneCol ? double.infinity : c.maxWidth / 2 - 6),
                  _input(
                      "Représentant",
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

          // Retour Livraison
          _SectionCard(
            title: "Retour Livraison",
            child: _checkboxWrap(retourLivraison),
          ),

          const SizedBox(height: 12),

          // Échange
          _SectionCard(
            title: "Échange",
            child: _checkboxWrap(echange),
          ),

          const SizedBox(height: 12),

          // Articles
          _SectionCard(
            title: "Article",
            child: Column(
              children: [
                _articleHeader(),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Submit
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: Colors.white,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

  // ===== helpers =====
  Widget _checkboxWrap(Map<String, bool> map) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: map.keys.map((k) {
        final v = map[k] ?? false;
        return SizedBox(
          height: 36,
          child: FilterChip(
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
            side: BorderSide(color: Colors.black12.withOpacity(.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
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
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius)),
        suffixIcon: suffix,
      ),
    );
    if (width == null) return field;
    return SizedBox(width: width, child: field);
  }

  Widget _articleHeader() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isPhone = w < 620;
      final labels = [
        "Article",
        "Quantité",
        "N° Lot",
        "Date fab.",
        "N° Facture",
        "Date Facture",
        "Montant",
        "Observation",
        "Action"
      ];
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: labels.map((t) {
            return SizedBox(
              width: isPhone ? (w / 2) - 12 : _colWidthFor(t, w),
              child: Text(
                t,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _articleRow(_ArticleRow a) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isPhone = w < 620;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _smallField(a.articleCtrl, hint: "Article",
                width: isPhone ? (w / 2) - 12 : _colWidthFor("Article", w)),
            _smallField(a.qtyCtrl, hint: "Qté", keyboard: TextInputType.number,
                width: isPhone ? (w / 2) - 12 : _colWidthFor("Quantité", w)),
            _smallField(a.lotCtrl, hint: "N°Lot",
                width: isPhone ? (w / 2) - 12 : _colWidthFor("N° Lot", w)),
            _smallField(a.dateFabCtrl, hint: "YYYY-MM-DD", readOnly: true,
                onTap: () => _pickDate(a.dateFabCtrl),
                width: isPhone ? (w / 2) - 12 : _colWidthFor("Date fab.", w)),
            _smallField(a.factureNoCtrl, hint: "N° Facture",
                width: isPhone ? (w / 2) - 12 : _colWidthFor("N° Facture", w)),
            _smallField(a.dateFactureCtrl, hint: "YYYY-MM-DD", readOnly: true,
                onTap: () => _pickDate(a.dateFactureCtrl),
                width: isPhone ? (w / 2) - 12 : _colWidthFor("Date Facture", w)),
            _smallField(a.montantCtrl, hint: "Montant", keyboard: TextInputType.number,
                width: isPhone ? (w / 2) - 12 : _colWidthFor("Montant", w)),
            _smallField(a.obsCtrl, hint: "Observation",
                width: isPhone ? (w / 2) - 12 : _colWidthFor("Observation", w)),
            SizedBox(
              width: isPhone ? (w / 2) - 12 : _colWidthFor("Action", w),
              child: IconButton(
                onPressed: () => setState(() => _articles.remove(a)),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Supprimer",
              ),
            ),
          ],
        ),
      );
    });
  }

  double _colWidthFor(String label, double total) {
    const map = {
      "Article": 0.16,
      "Quantité": 0.10,
      "N° Lot": 0.12,
      "Date fab.": 0.12,
      "N° Facture": 0.12,
      "Date Facture": 0.12,
      "Montant": 0.10,
      "Observation": 0.12,
      "Action": 0.04,
    };
    return total * (map[label] ?? 0.1);
  }
}

class _ArticleRow {
  final TextEditingController articleCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController lotCtrl = TextEditingController();
  final TextEditingController dateFabCtrl = TextEditingController();
  final TextEditingController factureNoCtrl = TextEditingController();
  final TextEditingController dateFactureCtrl = TextEditingController();
  final TextEditingController montantCtrl = TextEditingController();
  final TextEditingController obsCtrl = TextEditingController();

  Map<String, dynamic> toJson() => {
        "article": articleCtrl.text,
        "quantite": qtyCtrl.text,
        "lot": lotCtrl.text,
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  title!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
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
  double? width,
}) {
  final field = TextField(
    controller: c,
    onTap: onTap,
    readOnly: readOnly,
    keyboardType: keyboard,
    decoration: InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_ReclamationScreenState._radius),
      ),
    ),
  );
  if (width == null) return field;
  return SizedBox(width: width, child: field);
}

// lib/screens/admin_order_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  final _fmt = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();

  int _selectedTab = 0; // ✅ "AUJOURD'HUI" par défaut

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromBackend() async {
    setState(() => _loading = true);
    try {
      final rawList = await ApiService.getAllAdminOrders();

      // 🔄 Normalisation des clés venant du backend
      final list = rawList.map<Map<String, dynamic>>((m) {
        return {
          "clientName": m["clientName"] ?? m["nom_Client"] ?? "Client inconnu",
          "clientCode": m["clientCode"] ?? m["code_Client"] ?? "",
          "repName": m["repName"] ?? m["nom_Rep"] ?? "Rep inconnu",
          "orderReference": m["orderReference"] ?? m["reference"] ?? "",
          "total": m["total"] ?? 0,
          "orderDate": m["orderDate"] ?? m["date_commande"],
          "statutCommande": m["statutCommande"] ?? m["StatutCommande"] ?? "",
          "items": m["items"] ?? [],
          "note": m["note"] ?? m["Note"] ?? "", // ✅ ajout note
        };
      }).toList();

      setState(() {
        _items = list;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur récupération commandes: $e')),
      );
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    List<Map<String, dynamic>> base = List.from(_items);

    // Filtre par onglet
    if (_selectedTab == 0) {
      final today = DateTime.now();
      base = base.where((o) {
        final raw = o['orderDate'];
        if (raw == null) return false;
        final dt = DateTime.tryParse(raw.toString());
        if (dt == null) return false;
        return dt.year == today.year &&
            dt.month == today.month &&
            dt.day == today.day;
      }).toList();
    }

    // Filtre recherche
    if (q.isNotEmpty) {
      base = base.where((o) {
        return (o['clientName'] ?? '').toString().toLowerCase().contains(q) ||
            (o['clientCode'] ?? '').toString().toLowerCase().contains(q) ||
            (o['repName'] ?? '').toString().toLowerCase().contains(q) ||
            (o['orderReference'] ?? '').toString().toLowerCase().contains(q) ||
            (o['total'] ?? '').toString().toLowerCase().contains(q) ||
            (o['orderDate'] ?? '').toString().toLowerCase().contains(q) ||
            (o['statutCommande'] ?? '').toString().toLowerCase().contains(q) ||
            (o['note'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      _filtered = base;
      _loading = false;
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.tryParse(raw.toString());
      return dt != null ? _fmt.format(dt) : raw.toString();
    } catch (_) {
      return raw.toString();
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔎 Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
          ),

          // 🟦 Mini Navbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: MiniNavbar(
              selectedIndex: _selectedTab,
              onTabSelected: _onTabSelected,
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadFromBackend,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              _EmptyState(),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final o = _filtered[i];

                              final client = (o['clientName'] ?? '') as String;
                              final code = (o['clientCode'] ?? '') as String;
                              final rep = (o['repName'] ?? '') as String;
                              final ref =
                                  (o['orderReference'] ?? '') as String;
                              final total = (o['total'] ?? 0).toString();
                              final date = _formatDate(o['orderDate']);
                              final statut =
                                  (o['statutCommande'] ?? '').toString();
                              final items = (o['items'] as List?) ?? [];
                              final note =
                                  (o['note'] ?? '').toString(); // ✅ note récupérée

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  title: Text(
                                    "Client : $client",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle:
                                      Text("Date : $date\nReprésentant : $rep"),
                                  children: [
                                    if (code.isNotEmpty)
                                      _infoLine("Code client", code),
                                    if (ref.isNotEmpty)
                                      _infoLine("Référence", ref),
                                    _infoLine("Montant total", "$total TND"),
                                    if (statut.isNotEmpty)
                                      _infoLine("Statut", statut),
                                    if (note.isNotEmpty)
                                      _infoLine("Note", note), // ✅ affichage note
                                    if (items.isNotEmpty) ...[
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Articles :",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            ...items.map((e) {
                                              final it =
                                                  Map<String, dynamic>.from(
                                                      e as Map);
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 2),
                                                child: Text(
                                                  "- ${it['itmref'] ?? ''} | Qté: ${it['quantity'] ?? 0} | PU: ${it['unitPrice'] ?? 0} | Total: ${it['totalPrice'] ?? 0}",
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: "$key: ",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const MiniNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ["AUJOURD'HUI", "TOUTES"];
    final icons = [Icons.calendar_today, Icons.list_alt];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 18,
                      color: selected ? Colors.white : Colors.blue,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : Colors.blue,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.list_alt, size: 48, color: Colors.grey.shade500),
        const SizedBox(height: 10),
        Text('Aucune commande',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Text(
          'Les commandes apparaîtront ici dès qu’elles seront disponibles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

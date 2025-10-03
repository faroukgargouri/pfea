// lib/screens/admin_reclamation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';

class AdminReclamationScreen extends StatefulWidget {
  const AdminReclamationScreen({super.key});

  @override
  State<AdminReclamationScreen> createState() => _AdminReclamationScreenState();
}

class _AdminReclamationScreenState extends State<AdminReclamationScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  final _fmtDateOnly = DateFormat('dd/MM/yyyy');
  final _searchCtrl = TextEditingController();
  int _selectedTab = 0; // ✅ "AUJOURD'HUI" par défaut

  Future<bool> _isOnline() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final box = await Hive.openBox('reclamations_cache');

    try {
      if (await _isOnline()) {
        final data = await ApiService.getAllAdminReclamations();
        await box.put('all', data);
        if (!mounted) return;
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
        });
      } else {
        final cached = (box.get('all') as List?) ?? [];
        final list = cached
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() {
          _items = list;
        });
        if (list.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hors ligne: aucune réclamation en cache.')),
          );
        }
      }
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement réclamations: $e')),
      );
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    List<Map<String, dynamic>> base = List.from(_items);

    // ✅ Filtre par onglet
    if (_selectedTab == 0) {
      final today = DateTime.now();
      base = base.where((r) {
        final raw = r['dateReclamation'];
        if (raw == null) return false;
        final dt = DateTime.tryParse(raw.toString());
        if (dt == null) return false;
        return dt.year == today.year &&
            dt.month == today.month &&
            dt.day == today.day;
      }).toList();
    }

    // ✅ Filtre recherche
    if (q.isNotEmpty) {
      base = base.where((r) {
        final rep = (r['representant'] ?? '').toString().toLowerCase();
        final client = (r['client'] ?? '').toString().toLowerCase();
        final phone = (r['telephone'] ?? '').toString().toLowerCase();
        final note = (r['note'] ?? '').toString().toLowerCase();
        final retour = (r['retourLivraison'] ?? '').toString().toLowerCase();
        final echange = (r['echange'] ?? '').toString().toLowerCase();
        final date = _formatDate(r['dateReclamation']).toLowerCase();

        final articles = (r['articles'] as List?) ?? [];
        final articlesText = articles.map((a) {
          return [
            a['nomArticle'],
            a['codeArticle'],
            a['factureNo'],
            a['dateFabrication'],
            a['dateFacture'],
            a['montant'],
            a['observation']
          ].where((x) => x != null).join(" ");
        }).join(" ").toLowerCase();

        return rep.contains(q) ||
            client.contains(q) ||
            phone.contains(q) ||
            note.contains(q) ||
            retour.contains(q) ||
            echange.contains(q) ||
            date.contains(q) ||
            articlesText.contains(q);
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
      return dt != null ? _fmtDateOnly.format(dt) : raw.toString();
    } catch (_) {
      return raw.toString();
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔎 Barre de recherche
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

                // 🟦 Mini Navbar (AUJOURD'HUI / TOUTES)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: MiniNavbar(
                    selectedIndex: _selectedTab,
                    onTabSelected: _onTabSelected,
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              _EmptyState(),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final r = _filtered[i];
                              final rep = r['representant'] ?? 'Représentant inconnu';
                              final client = r['client'] ?? 'Client';
                              final phone = r['telephone'] ?? '';
                              final note = r['note'] ?? '';
                              final retour = r['retourLivraison'] ?? '';
                              final echange = r['echange'] ?? '';
                              final date = _formatDate(r['dateReclamation']);
                              final articles = (r['articles'] as List?) ?? [];

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  title: Text(
                                    'Client : $client',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text("Date : $date\nReprésentant : $rep"),
                                  children: [
                                    if (phone.isNotEmpty) _infoLine("Téléphone", phone),
                                    if (note.isNotEmpty) _infoLine("Note", note),
                                    if (retour.isNotEmpty) _infoLine("Retour", retour),
                                    if (echange.isNotEmpty) _infoLine("Échange", echange),
                                    if (articles.isNotEmpty) ...[
                                      const Divider(),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Articles :",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      for (var i = 0; i < articles.length; i++) ...[
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${articles[i]['nomArticle'] ?? ''} (x${articles[i]['quantite'] ?? ''})",
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500, height: 1.2),
                                            ),
                                            if ((articles[i]['codeArticle'] ?? '').toString().isNotEmpty)
                                              _articleField("Code", articles[i]['codeArticle']),
                                            if ((articles[i]['factureNo'] ?? '').toString().isNotEmpty)
                                              _articleField("Facture", articles[i]['factureNo']),
                                            if ((articles[i]['dateFabrication'] ?? '').toString().isNotEmpty)
                                              _articleField("Date fabrication",
                                                  _formatDate(articles[i]['dateFabrication'])),
                                            if ((articles[i]['dateFacture'] ?? '').toString().isNotEmpty)
                                              _articleField("Date facture",
                                                  _formatDate(articles[i]['dateFacture'])),
                                            if ((articles[i]['montant'] ?? '').toString().isNotEmpty)
                                              _articleField("Montant", articles[i]['montant'].toString()),
                                            if ((articles[i]['observation'] ?? '').toString().isNotEmpty)
                                              _articleField("Observation", articles[i]['observation']),
                                          ],
                                        ),
                                        if (i < articles.length - 1)
                                          const Divider(height: 8, thickness: 0.5),
                                      ],
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "$key: ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: value),
            ],
          ),
          style: const TextStyle(height: 1.2),
        ),
      ),
    );
  }

  Widget _articleField(String key, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$key: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
        textAlign: TextAlign.left,
        style: const TextStyle(height: 1.2),
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
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text('Aucune réclamation',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Text(
          'Les réclamations apparaîtront ici dès qu’elles seront disponibles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

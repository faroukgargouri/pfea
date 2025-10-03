import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';

class AdminVisiteScreen extends StatefulWidget {
  const AdminVisiteScreen({super.key});

  @override
  State<AdminVisiteScreen> createState() => _AdminVisiteScreenState();
}

class _AdminVisiteScreenState extends State<AdminVisiteScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final _fmt = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTab = 0; // ✅ onglet par défaut = "AUJOURD'HUI"

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

  Future<void> _load() async {
    setState(() => _loading = true);
    final box = await Hive.openBox('visites_cache');

    try {
      if (await _isOnline()) {
        final data = await ApiService.getAllAdminVisites();
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
            const SnackBar(content: Text('Hors ligne: aucune visite en cache.')),
          );
        }
      }
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement visites: $e')),
      );
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    List<Map<String, dynamic>> base = List.from(_items);

    // ✅ Filtre par onglet
    if (_selectedTab == 0) {
      final today = DateTime.now();
      base = base.where((v) {
        final raw = v['dateVisite'];
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
      base = base.where((v) {
        final date = _formatDate(v['dateVisite']).toLowerCase();
        final client = (v['raisonSociale'] ?? '').toString().toLowerCase();
        final codeClient = (v['codeClient'] ?? '').toString().toLowerCase();
        final compteRendu = (v['compteRendu'] ?? '').toString().toLowerCase();
        final rep = v['user']?['firstName'] != null
            ? "${v['user']['firstName']} ${v['user']['lastName'] ?? ''}".toLowerCase()
            : '';

        return client.contains(q) ||
            codeClient.contains(q) ||
            compteRendu.contains(q) ||
            rep.contains(q) ||
            date.contains(q);
      }).toList();
    }

    setState(() {
      _filteredItems = base;
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
    _applyFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔎 Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Rechercher...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    onRefresh: _load,
                    child: _filteredItems.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              _EmptyState(),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final v = _filteredItems[i];
                              final date = _formatDate(v['dateVisite']);
                              final client =
                                  v['raisonSociale'] ?? 'Client inconnu';
                              final codeClient = v['codeClient'] ?? '';
                              final compteRendu = v['compteRendu'] ?? '';
                              final rep = v['user']?['firstName'] != null
                                  ? "${v['user']['firstName']} ${v['user']['lastName'] ?? ''}"
                                  : 'Représentant inconnu';

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  title: Text("Client : $client",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle:
                                      Text("Date : $date\nReprésentant : $rep"),
                                  children: [
                                    if (codeClient.isNotEmpty)
                                      _infoLine("Code Client", codeClient),
                                    if (compteRendu.isNotEmpty)
                                      _infoLine("Compte rendu", compteRendu),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          style: const TextStyle(height: 1.3),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
        Icon(Icons.event_note_outlined,
            size: 56, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text('Aucune visite',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Text(
          'Les visites apparaîtront ici dès qu’elles seront disponibles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

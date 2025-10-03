import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reliquat.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⬇️ Your shared AppBar + BlueNavbar
import '../widgets/custom_navbar.dart';

class ReliquatsScreen extends StatefulWidget {
  final String codeClient; // ✅ obligatoire
  final String site; // ✅ obligatoire

  const ReliquatsScreen({
    super.key,
    required this.codeClient,
    required this.site,
  });

  @override
  State<ReliquatsScreen> createState() => _ReliquatsScreenState();
}

class _ReliquatsScreenState extends State<ReliquatsScreen> {
  // --- Header (TrikiAppBar) user info ---
  String? _fullName;
  String? _codeSage;

  // --- Search state ---
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  // --- Data state ---
  bool _loading = true;
  String? _error;
  List<Reliquat> _items = [];
  List<Reliquat> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadHeaderUser();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  Future<void> _loadHeaderUser() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _fullName = sp.getString('fullName');
      _codeSage = sp.getString('codeSage');
    });
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_applyFilter)
      ..dispose();
    super.dispose();
  }

  // --- Actions ---
  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchReliquats(
        codeClient: widget.codeClient,
        site: widget.site,
      );
      setState(() {
        _items = data;
        _filtered = data;
        _loading = false;
      });
      if (_searchCtrl.text.trim().isNotEmpty) {
        _applyFilter();
      }
    } catch (e, stack) {
      print('Error: $e\nStack: $stack');
      setState(() {
        _loading = false;
        _error = 'Erreur chargement reliquats: $e';
        _items = [];
        _filtered = [];
      });
    }
  }

  // --- Helpers format ---
  String _fmtNbr(num? v) =>
      v == null ? '0' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 3);

  String _fmtDate(String? raw) => raw ?? 'N/A';

  // --- Global search over ALL fields ---
  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _items);
      return;
    }

    bool contains(String? s) => (s ?? '').toLowerCase().contains(q);
    bool containsNum(num? n) =>
        (n == null ? '' : _fmtNbr(n)).toLowerCase().contains(q);

    setState(() {
      _filtered = _items.where((r) {
        final c1 = contains(r.numeroCommande);
        final c2 = contains(r.refart);
        final c3 = contains(r.desArt);
        final c4 = contains(r.codeClient);
        final c5 = contains(r.dateCommande);
        final c6 = containsNum(r.qtecommande);
        final c7 = containsNum(r.qtelivree);
        final c8 = containsNum(r.solde);
        final c9 = containsNum(r.valLigne);
        final c10 = containsNum(r.val_total);
        return c1 || c2 || c3 || c4 || c5 || c6 || c7 || c8 || c9 || c10;
      }).toList();
    });
  }

  // --- Group by numeroCommande ---
  Map<String, List<Reliquat>> _groupByCommande(List<Reliquat> list) {
    final Map<String, List<Reliquat>> grouped = {};
    for (final r in list) {
      final key = r.numeroCommande ?? 'N/A';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(r);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final title = 'ÉTAT DES RELIQUATS'
        '${widget.codeClient.isEmpty ? '' : ' - ${widget.codeClient}'}';

    return Scaffold(
      appBar: TrikiAppBar(
        fullName: _fullName,
        codeSage: _codeSage,
        actionsBeforeLogout: [
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'Recherche',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        blueNavItems: [
          BlueNavItem(label: title, selected: true),
        ],
        blueNavVariant: BlueNavbarVariant.textOnly,
      ),

      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(28),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: (_searchCtrl.text.isEmpty)
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),

          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filtered.isEmpty)
            const Expanded(
              child: Center(child: Text('Aucun reliquat trouvé.')),
            )
          else
            Expanded(
              child: Builder(
                builder: (context) {
                  final grouped = _groupByCommande(_filtered);
                  final keys = grouped.keys.toList();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final cmd = keys[i];
                      final lignes = grouped[cmd]!;

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          title: Text(
                            'Commande N°: $cmd',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Articles: ${lignes.length}'),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: lignes.map((r) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                Text(
                                  'Article: ${r.desArt ?? 'N/A'} (${r.refart ?? ''})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _kvRow('Qté Cmd', _fmtNbr(r.qtecommande)),
                                _kvRow('Qté Livrée', _fmtNbr(r.qtelivree)),
                                _kvRow('Solde', _fmtNbr(r.solde)),
                                _kvRow('Prix unitaire', _fmtNbr(r.valLigne)),
                                _kvRow('Prix total', _fmtNbr(r.val_total)),
                                _kvRow('Date CMD', _fmtDate(r.dateCommande)),
                                const SizedBox(height: 6),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(v, softWrap: true)),
      ],
    );
  }
}

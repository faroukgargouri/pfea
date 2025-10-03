// lib/screens/chiffre_affaires_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_navbar.dart';
import '../data/api_config.dart';

class ChiffreAffairesScreen extends StatefulWidget {
  final String? subCodeClient;
  final String? raisonSocial;
  const ChiffreAffairesScreen({super.key, this.subCodeClient, this.raisonSocial});

  @override
  State<ChiffreAffairesScreen> createState() => _ChiffreAffairesScreenState();
}

class _ChiffreAffairesScreenState extends State<ChiffreAffairesScreen> {
  bool _hasText(String? s) => (s ?? '').trim().isNotEmpty;

  String get _subCodeClient => (widget.subCodeClient ?? '').trim();
  String get _raisonSocial => (widget.raisonSocial ?? '').trim();

  // ---- Header info ----
  String? _fullName;
  String? _codeSage;

  // ---- Search ----
  final _queryCtrl = TextEditingController();
  bool _isSearching = false;

  // ---- Data ----
  Future<dynamic>? _future;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  // ---- Grouping / Tabs ----
  int? _currentYear;
  Map<String, List<Map<String, dynamic>>> _byYear = {};
  List<String> _yearTabs = <String>[];

  // ---- Parsing helpers ----
  static const Set<String> _hiddenKeysLower = {
    'codeclient',
    'subcodeclient',
    'raisonsocial',
    'raison_social',
    'raison social',
  };

  static final RegExp _yearRegex = RegExp(r'\b(19|20)\d{2}\b');
  static final RegExp _currAnneeKey =
      RegExp(r'current\s*annee(?:_(\d+))?', caseSensitive: false);

  final NumberFormat _money = NumberFormat('#,##0.000', 'fr_FR');

  // ---------- Display mapping (rename + order) ----------
  static const List<String> _orderedLabels = [
    'CA Q1',
    'CA Q2',
    'CA Q3',
    'CA Q4',
    'TOTAL',
    'EN COURS'
  ];
  static final Map<String, int> _orderIndex = {
    for (int i = 0; i < _orderedLabels.length; i++) _orderedLabels[i]: i
  };

  String _displayLabelFor(String raw) {
    final s = raw.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    bool hasAny(Iterable<String> parts) => parts.any(s.contains);

    if (hasAny(['caq1', 'q1', 't1', 'trimestre1'])) return 'CA Q1';
    if (hasAny(['caq2', 'q2', 't2', 'trimestre2'])) return 'CA Q2';
    if (hasAny(['caq3', 'q3', 't3', 'trimestre3'])) return 'CA Q3';
    if (hasAny(['caq4', 'q4', 't4', 'trimestre4'])) return 'CA Q4';
    if (hasAny(['total', 'catotal'])) return 'TOTAL';
    if (hasAny(['encours', 'encour', 'en cours', 'inprogress', 'pending'])) {
      return 'EN COURS';
    }

    return raw; // fallback
  }

  int _compareRows(Map<String, dynamic> a, Map<String, dynamic> b) {
    final la = _displayLabelFor((a['Clé'] ?? '').toString());
    final lb = _displayLabelFor((b['Clé'] ?? '').toString());
    final ia = _orderIndex[la] ?? 999;
    final ib = _orderIndex[lb] ?? 999;
    if (ia != ib) return ia.compareTo(ib);
    return la.compareTo(lb);
  }

  @override
  void initState() {
    super.initState();
    _loadHeaderUser();
    if (_hasText(_subCodeClient) || _hasText(_raisonSocial)) {
      _search(force: true);
    } else {
      _rebuildGroups();
    }
  }

  Future<void> _loadHeaderUser() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullName = sp.getString('fullName');
      _codeSage = sp.getString('codeSage');
    });
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  // ---- UI actions ----
  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _search(force: true);

  // ---- API ----
  void _search({bool force = false}) {
    if (!_hasText(_subCodeClient) && !_hasText(_raisonSocial)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Aucun paramètre fourni (SubCodeClient / Raison sociale).')),
      );
      return;
    }
    if (!force && _future != null) return;

    final fut = _fetchChiffreAffaire(_subCodeClient, _raisonSocial).then((decoded) {
      final list = <Map<String, dynamic>>[];

      void pushKV(String key, dynamic value) {
        if (_hiddenKeysLower.contains(key.toLowerCase())) return;

        if (key.trim().toLowerCase() == 'currentannee') {
          final yr = int.tryParse(
              (value ?? '').toString().replaceAll(RegExp(r'[^\d]'), ''));
          if (yr != null) _currentYear = yr;
        }
        list.add({'Clé': key, 'Valeur': value});
      }

      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded as Map);
        for (final e in m.entries) {
          pushKV((e.key).toString(), e.value);
        }
      }

      _all = list;
      _applyQuery(_queryCtrl.text);
      return decoded;
    });

    setState(() {
      _future = fut;
    });
  }

  Future<dynamic> _fetchChiffreAffaire(
      String subCodeClient, String raisonSocial) async {
    final base = Uri.parse(apiRoot);
    final uri = base.replace(
      pathSegments: [...base.pathSegments, 'Client', 'ChiffreAffaire'],
      queryParameters: {
        if (_hasText(subCodeClient)) 'SubCodeClient': subCodeClient,
        if (_hasText(raisonSocial)) 'raisonSocial': raisonSocial,
      },
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode >= 400) {
        throw Exception('API error: ${res.statusCode} | ${res.body}');
      }
      return json.decode(res.body);
    } on TimeoutException {
      throw Exception("Délai dépassé en appelant l'API.");
    } catch (e) {
      throw Exception("Erreur réseau: $e");
    }
  }

  // ---- Filtering & Grouping ----
  void _applyQuery(String q) {
    final needle = q.trim().toLowerCase();
    List<Map<String, dynamic>> base = _all;

    if (needle.isNotEmpty) {
      base = _all.where((row) {
        final key = (row['Clé'] ?? '').toString().toLowerCase();
        final val = _valAsString(row['Valeur']).toLowerCase();
        return key.contains(needle) || val.contains(needle);
      }).toList();
    }

    _filtered = base;
    _rebuildGroups();
    setState(() {});
  }

  String? _bucketForRow(Map<String, dynamic> row) {
    final key = (row['Clé'] ?? '').toString();
    final val = (row['Valeur'] ?? '').toString();

    try {
      final m = _currAnneeKey.firstMatch(key);
      if (m != null && _currentYear != null) {
        final idx = int.tryParse(m.group(1) ?? '0') ?? 0;
        return '${_currentYear! - idx}';
      }
    } catch (_) {}

    if (key.trim().toLowerCase() == 'currentannee') {
      final yr = int.tryParse(val.replaceAll(RegExp(r'[^\d]'), ''));
      if (yr != null) return '$yr';
    }

    try {
      final mk = _yearRegex.firstMatch(key);
      if (mk != null) return mk.group(0)!;
      final mv = _yearRegex.firstMatch(val);
      if (mv != null) return mv.group(0)!;
    } catch (_) {}

    return _currentYear != null ? '${_currentYear!}' : null;
  }

  void _rebuildGroups() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final row in _filtered) {
      final bucket = _bucketForRow(row);
      if (bucket == null) continue;
      (map[bucket] ??= <Map<String, dynamic>>[]).add(row);
    }
    for (final y in map.keys) {
      map[y]!.sort(_compareRows);
    }
    final years =
        map.keys.toList()..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    _byYear = map;
    _yearTabs = years;
  }

  String _valAsString(dynamic v) {
    if (v == null) return '—';
    if (v is num) return _money.format(v);
    if (v is bool) return v ? 'Oui' : 'Non';
    return v.toString();
  }

  // ---- BUILD ----
  @override
  Widget build(BuildContext context) {
    final suffix = [
      if (_hasText(_subCodeClient)) _subCodeClient,
      if (_hasText(_raisonSocial)) _raisonSocial
    ].join(' · ');

    final blueLabel =
        suffix.isEmpty ? "CHIFFRE D'AFFAIRES" : "CHIFFRE D'AFFAIRES — $suffix";

    final tabs = _yearTabs;
    final tabCount = tabs.length;

    return Scaffold(
      appBar: TrikiAppBar(
        fullName: _fullName,
        codeSage: _codeSage,
        actionsBeforeLogout: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recharger',
              onPressed: _refresh),
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: 'Recherche',
              onPressed: _toggleSearch),
        ],
        blueNavItems: [BlueNavItem(label: blueLabel, selected: true)],
        blueNavVariant: BlueNavbarVariant.textOnly,
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: Column(
        children: [
          if (_isSearching) _buildSingleSearchBar(context),
          Expanded(
            child: FutureBuilder<dynamic>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorState(
                      message: 'Impossible de charger les données.\n${snap.error}',
                      onRetry: _refresh);
                }
                if (_filtered.isEmpty || tabCount == 0) {
                  return const _EmptyState(
                      title: 'Aucun résultat',
                      subtitle: 'Aucune année détectée dans les données.',
                      icon: Icons.insert_chart_outlined);
                }

                final initialIndex = (tabCount > 0) ? tabCount - 1 : 0;

                return DefaultTabController(
                  length: tabCount,
                  initialIndex: initialIndex,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Colors.blue,
                        labelColor: Colors.blue.shade700,
                        unselectedLabelColor: Colors.black54,
                        tabs: tabs.map((t) => Tab(text: t)).toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: tabs.map((tabKey) {
                            final rows =
                                _byYear[tabKey] ?? const <Map<String, dynamic>>[];
                            return _YearListView(
                              rows: rows,
                              labelFor: _displayLabelFor,
                              valueAsString: _valAsString,
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSingleSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _queryCtrl,
        onChanged: _applyQuery,
        decoration: InputDecoration(
          hintText: 'Rechercher…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _queryCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _queryCtrl.clear();
                    _applyQuery('');
                  }),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/* ======================= YEAR TAB LIST VIEW ======================= */

class _YearListView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String Function(String raw) labelFor;
  final String Function(dynamic v) valueAsString;

  const _YearListView({
    required this.rows,
    required this.labelFor,
    required this.valueAsString,
  });

  bool _hideThisKey(String key) {
    final s = key.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    return s == 'currentannee' ||
        s == 'currentannee1' ||
        s == 'currentannee2';
  }

  @override
  Widget build(BuildContext context) {
    final visibleRows =
        rows.where((r) => !_hideThisKey((r['Clé'] ?? '').toString())).toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: visibleRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final row = visibleRows[i];
        final label = labelFor((row['Clé'] ?? '').toString());
        final value = valueAsString(row['Valeur']);
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ExpansionTile(
            title: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
           
          ),
        );
      },
    );
  }
}

/* ======================= Empty / Error ======================= */

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _EmptyState(
      {required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center)
      ],
    ));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text('Erreur', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("Réessayer"))
    ]));
  }
}

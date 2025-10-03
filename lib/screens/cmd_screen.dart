import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_config.dart';
import '../models/cmd.dart';
import '../widgets/custom_navbar.dart'; // TrikiAppBar, BlueNavItem, BlueNavbarVariant, trikiBlue

class CmdScreen extends StatefulWidget {
  final String rep; // required for API
  const CmdScreen({super.key, required this.rep});

  @override
  State<CmdScreen> createState() => _CmdScreenState();
}

class _CmdScreenState extends State<CmdScreen> {
  // ---- intl gating (screen-level) ----
  Future<void>? _intlReady;

  // ---- API param (locked) ----
  late final String _rep;

  // ---- Single search box (filters all visible fields) ----
  final _queryCtrl = TextEditingController();

  // ---- Data ----
  Future<List<Cmd>>? _future;
  List<Cmd> _all = [];
  List<Cmd> _filtered = [];

  // ---- UI state ----
  bool _isSearching = false;
  String _soldFilter = 'all'; // 'all', 'Soldée', 'Non Soldée'

  // ---- Triki header info ----
  String? _fullName;
  String? _codeSage;

  // formatters (initialized after intl ready)
  NumberFormat? _nfMoney;
  NumberFormat? _nfInt;

  @override
  void initState() {
    super.initState();
    _rep = widget.rep.trim();
    _intlReady = _setupIntl();
    _loadHeaderUser();
    if (_rep.isNotEmpty) {
      _search();
    }
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
    _queryCtrl.dispose();
    super.dispose();
  }

  // ----------------------- intl setup -----------------------
  Future<void> _setupIntl() async {
    Intl.defaultLocale = 'fr_FR';
    await initializeDateFormatting('fr_FR', null);
    _nfMoney = NumberFormat('#,##0.000', 'fr_FR'); // TND style
    _nfInt = NumberFormat('#,##0', 'fr_FR');
  }

  // ----------------------- AppBar actions -----------------------
  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _search();

  // ----------------------- API search (sync trigger) -----------------------
  void _search() {
    if (_rep.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètre rep manquant pour charger les commandes.')),
      );
      return;
    }
    setState(() {
      _future = _fetch(_rep).then((rows) {
        _all = rows;
        _applyQuery(_queryCtrl.text);
        return rows;
      });
    });
  }

  Future<List<Cmd>> _fetch(String rep) async {
    final uri = Uri.parse('$apiBaseUrl/api/Client/Cmd?rep=$rep');
    final res = await http.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Erreur API: ${res.statusCode} | ${res.reasonPhrase}\n${res.body}');
    }
    final raw = json.decode(res.body);
    final List data = (raw is List) ? raw : (raw['data'] as List? ?? const []);
    return data.map((e) => Cmd.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ----------------------- Single query over ALL fields + Sold filter -----------------------
  void _applyQuery(String q) {
    final qq = q.trim().toLowerCase();
    var out = _all;

    // Apply sold filter
    if (_soldFilter != 'all') {
      out = out.where((c) {
        final soldee = _s(c.soldee).toLowerCase().trim();
        return soldee == _soldFilter.toLowerCase().trim();
      }).toList();
    }

    // Apply text query if present
    if (qq.isNotEmpty) {
      out = out.where((c) {
        final dyn = c as dynamic;
        final date = _dateOf(c);
        final dateStr = date != null
            ? DateFormat('yyyy-MM-dd').format(date)
            : _s(dyn.dateCmd ?? dyn.datecmd ?? dyn.dateCMD);

        final haystack = [
          _s(dyn.nCommand ?? dyn.ncommand ?? dyn.nCommande),
          dateStr,
          _s(dyn.codeClient ?? dyn.codeclient),
          _s(dyn.raison ?? dyn.raison),
          _s(dyn.rep),
          _s(dyn.ville),
          _s(dyn.etat),
          _s(dyn.soldee),
          _s(dyn.facturee),
          _fmtMoney(_n(dyn.mtht)),
          _fmtMoney(_n(dyn.mtttc)),
          _fmtMoney(_n(dyn.remise)),
          _fmtInt(_n(dyn.poids)),
        ].join(' · ').toLowerCase();

        return haystack.contains(qq);
      }).toList();
    }

    setState(() => _filtered = out);
  }

  // ----------------------- Helpers (safe) -----------------------
  String _s(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return (s == 'null') ? '' : s;
  }

  num _n(dynamic v) {
    if (v is num) return v;
    final s = _s(v).replaceAll(',', '.');
    return num.tryParse(s) ?? 0;
  }

  DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = _s(v).trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  DateTime? _dateOf(Cmd x) {
    try {
      final dyn = x as dynamic;
      return _tryParseDate(dyn.dateCmd ?? dyn.datecmd ?? dyn.dateCMD);
    } catch (_) {
      return null;
    }
  }

  String _fmtMoney(num v) => _nfMoney!.format(v);
  String _fmtInt(num v) => _nfInt!.format(v);

  String _fmtDateStr(dynamic raw) {
    final d = _tryParseDate(raw);
    if (d == null) return _s(raw);
    final dd = DateTime(d.year, d.month, d.day);
    return DateFormat('d/M/yyyy', 'fr_FR').format(dd);
  }

  num get _totalTtc => _filtered.fold<num>(0, (t, c) => t + _n((c as dynamic).mtttc));
  num get _totalHt => _filtered.fold<num>(0, (t, c) => t + _n((c as dynamic).mtht));
  num get _totalRemise => _filtered.fold<num>(0, (t, c) => t + _n((c as dynamic).remise));
  num get _totalPoids => _filtered.fold<num>(0, (t, c) => t + _n((c as dynamic).poids));

  // ----------------------- BUILD -----------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _intlReady ?? Future.value(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          // ✅ Single unified AppBar with blue text-only navbar (no second bar)
          appBar: TrikiAppBar(
            fullName: _fullName,
            codeSage: _codeSage,
            actionsBeforeLogout: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Recharger',
                onPressed: _refresh,
              ),
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: 'Recherche',
                onPressed: _toggleSearch,
              ),
            ],
            blueNavItems: const [
              BlueNavItem(label: 'COMMANDES', selected: true),
            ],
            blueNavVariant: BlueNavbarVariant.textOnly,
          ),

          body: Column(
            children: [
              if (_isSearching) _buildSingleSearchBar(context),
              _buildFilterChips(context),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Cmd>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        onRetry: _refresh,
                        message: 'Impossible de charger les commandes.\n${snap.error}',
                      );
                    }
                    if (_filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Aucune commande',
                        subtitle: 'Tapez un mot-clé, changez le filtre ou rechargez les données.',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    return _buildExpansionList(context);
                  },
                ),
              ),
              _buildTotalBar(context),
            ],
          ),
        );
      },
    );
  }

  // ----------------------- UI: Single Search Box -----------------------
  Widget _buildSingleSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(28),
        child: TextField(
          controller: _queryCtrl,
          onChanged: _applyQuery,
          decoration: InputDecoration(
            hintText: 'Rechercher ',
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            suffixIcon: (_queryCtrl.text.isEmpty)
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _queryCtrl.clear();
                      _applyQuery('');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ----------------------- UI: Filter Chips -----------------------
  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChoiceChip('Toutes', 'all'),
          const SizedBox(width: 8),
          _buildChoiceChip('Soldées', 'Soldée'),
          const SizedBox(width: 8),
          _buildChoiceChip('Non soldées', 'Non Soldée'),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _soldFilter == value,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _soldFilter = value;
            _applyQuery(_queryCtrl.text);
          });
        }
      },
      selectedColor: Colors.blue.shade100,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: _soldFilter == value ? Colors.blue.shade700 : Colors.black87,
        fontWeight: _soldFilter == value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ----------------------- UI: Expansion list -----------------------
  Widget _buildExpansionList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _filtered[i];
        final dyn = c as dynamic;

        final nCmd = _s(dyn.nCommand ?? dyn.ncommand ?? dyn.nCommande);
        final dateStr = _fmtDateStr(dyn.dateCmd ?? dyn.datecmd ?? dyn.dateCMD);

        final montantHt = _n(dyn.mtht);
        final montantTtc = _n(dyn.mtttc);

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text('N° Cmd : $nCmd', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'HT: ${_fmtMoney(montantHt)}    •    TTC: ${_fmtMoney(montantTtc)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              children: [
                _kv('Date commande', dateStr),
                _kv('Client', _s(dyn.codeClient ?? dyn.codeclient)),
                _kv('Raison sociale', _s(dyn.raisonSocial ?? dyn.raisonSocial)),
                _kv('Ville', _s(dyn.ville)),
                _kv('Poids', _fmtInt(_n(dyn.poids))),
                _kv('Remise', _fmtMoney(_n(dyn.remise))),
                _kv('État', _s(dyn.etat)),
                _kv('Soldée', _s(dyn.soldee)),
                _kv('Facturée', _s(dyn.facturee)),
                _kv('Date expédition', _fmtDateStr(dyn.dateExp ?? dyn.dateexp)),
              ],
            ),
          ),
        );
      },
    );
  }

  // key-value row (label in bold, value normal)
  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  // ----------------------- UI: Total Bar -----------------------
  Widget _buildTotalBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: trikiBlue, // ✅ unified navbar color
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: trikiBlue.withOpacity(0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  const Text('Total TTC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    _fmtMoney(_totalTtc),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: trikiBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: trikiBlue.withOpacity(0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_money, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  const Text('Total HT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    _fmtMoney(_totalHt),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: trikiBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: trikiBlue.withOpacity(0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.discount, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  const Text('Total Remise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    _fmtMoney(_totalRemise),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: trikiBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: trikiBlue.withOpacity(0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.scale, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  const Text('Total Poids', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    _fmtInt(_totalPoids),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------- Helper empty/error states -----------------------
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Erreur', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

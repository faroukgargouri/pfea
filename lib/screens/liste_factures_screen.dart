import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/listefactures.dart'; // class listefactures
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart'; // TrikiAppBar + BlueNavItem + trikiBlue

/// ---------- TOP-LEVEL: client grouping model ----------
class _ClientGroup {
  final String codeClient;
  final String? raison;
  final List<listefactures> items;
  final double totalTtc;
  final double totalReste;

  _ClientGroup({
    required this.codeClient,
    required this.raison,
    required this.items,
    required this.totalTtc,
    required this.totalReste,
  });
}

class ListFactureScreen extends StatefulWidget {
  final String rep; // CodeRep (requis)
  const ListFactureScreen({super.key, required this.rep});

  @override
  State<ListFactureScreen> createState() => _ListFactureScreenState();
}

class _ListFactureScreenState extends State<ListFactureScreen> {
  // ---- intl gating ----
  late final Future<void> _intlReady;

  // ---- Required API params ----
  late final String _rep;

  // ---- Search ----
  final _queryCtrl = TextEditingController();

  // ---- Data ----
  Future<List<listefactures>>? _future;
  List<listefactures> _all = [];
  List<listefactures> _filtered = [];

  // ---- UI ----
  bool _isSearching = false;

  // ---- Header info for TrikiAppBar ----
  String? _fullName;
  String? _codeSage;

  // formatters
  late NumberFormat _nf;

  @override
  void initState() {
    super.initState();
    _rep = widget.rep;

    _nf = NumberFormat('#,##0.000', 'fr_FR');
    _intlReady = () async {
      Intl.defaultLocale = 'fr_FR';
      await initializeDateFormatting('fr_FR', null);
    }();

    _loadHeaderUser();
    _search();
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

  // ----------------------- AppBar actions -----------------------
  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _search();

  // ----------------------- API search -----------------------
  void _search() {
    setState(() {
      _future = ApiService.fetchListeFactures(_rep).then((rows) {
        _all = rows;
        _applyQuery(_queryCtrl.text);
        return rows;
      });
    });
  }

  // ----------------------- Search across all fields -----------------------
  void _applyQuery(String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    String amt(num? v) => v == null ? '' : _fmtAmount(v)!;

    final out = _all.where((f) {
      final dateStr = _fmtDateCsharp(f.dateFac) ?? '';
      final fields = <Object?>[
        f.codeClient,
        f.raison,
        f.ville,
        f.numFac,
        f.numCmd,
        dateStr,
        amt(f.mtttc),
        amt(f.soldeFacture),
        f.diffDate,
        f.rep,
        f.rep1,
        f.tel,
        f.mdReg,
        f.autorisation,
      ];
      final haystack = fields
          .map((e) => e == null ? '' : e.toString())
          .where((s) => s.isNotEmpty)
          .join(' · ')
          .toLowerCase();

      return haystack.contains(qq);
    }).toList();

    setState(() => _filtered = out);
  }

  // ----------------------- Helpers -----------------------
  String? _fmtAmount(num? v) => v == null ? null : _nf.format(v);

  String? _fmtDateCsharp(dynamic val) {
    if (val == null) return null;
    DateTime? dt;
    if (val is DateTime) {
      dt = val;
    } else if (val is String) {
      dt = DateTime.tryParse(val);
    }
    if (dt == null) return null;
    final d = DateTime(dt.year, dt.month, dt.day);
    return DateFormat('d/M/yyyy', 'fr_FR').format(d);
  }

  String? _strOrNull(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  double get _totalResteFiltres =>
      _filtered.fold(0.0, (t, f) => t + f.soldeFacture);

  double get _totalHtFiltres =>
      _filtered.fold(0.0, (t, f) => t + f.mtHt);
  double get _totalTtcFiltres =>
      _filtered.fold(0.0, (t, f) => t + f.mtttc);
  double get _totalRegleFiltres =>
      _filtered.fold(0.0, (t, f) => t + f.mtRegle);
  int get _nbFacturesFiltres => _filtered.length;

  List<_ClientGroup> _makeGroups(List<listefactures> rows) {
    final map = <String, List<listefactures>>{};
    for (final f in rows) {
      map.putIfAbsent(f.codeClient, () => []).add(f);
    }

    final groups = <_ClientGroup>[];
    for (final entry in map.entries) {
      final items = entry.value
        ..sort((a, b) {
          final ad = _toDate(a.dateFac);
          final bd = _toDate(b.dateFac);
          final cmp = bd.compareTo(ad);
          return (cmp != 0) ? cmp : (b.numFac).compareTo(a.numFac);
        });

      final totalTtc = items.fold<double>(0.0, (t, x) => t + x.mtttc);
      final totalReste = items.fold<double>(0.0, (t, x) => t + x.soldeFacture);

      groups.add(_ClientGroup(
        codeClient: entry.key,
        raison: _strOrNull(items.first.raison),
        items: items,
        totalTtc: totalTtc,
        totalReste: totalReste,
      ));
    }

    groups.sort((a, b) => a.codeClient.compareTo(b.codeClient));
    return groups;
  }

  DateTime _toDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _pill(String text, {required Color bg, required Color fg, Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: (border == null) ? null : Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  // ----------------------- UI -----------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _intlReady,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final pageTitle = 'LISTE FACTURES PAR CLIENT — Rep: $_rep';

        return Scaffold(
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
            blueNavItems: [
              BlueNavItem(label: pageTitle, selected: true),
            ],
            blueNavVariant: BlueNavbarVariant.textOnly,
          ),

          body: Column(
            children: [
              if (_isSearching) _buildSingleSearchBar(context),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<listefactures>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        onRetry: _refresh,
                        message: 'Impossible de charger les factures.\nErreur : ${snap.error}',
                      );
                    }
                    if (_filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Aucun résultat',
                        subtitle: 'Aucun client/facture ne correspond à votre recherche.',
                        icon: Icons.people_outline,
                      );
                    }

                    final groups = _makeGroups(_filtered);
                    return _buildGroupedList(context, groups);
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
            hintText: 'Rechercher ...',
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

  Widget _buildGroupedList(BuildContext context, List<_ClientGroup> groups) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = groups[i];
        final header = ((g.raison ?? '').isEmpty)
            ? g.codeClient
            : '${g.raison} (${g.codeClient})';

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(
                header,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'NbFac: ${g.items.length}    •    TTC: ${_fmtAmount(g.totalTtc) ?? '-'}    •    Reste: ${_fmtAmount(g.totalReste) ?? '-'}',
                style: TextStyle(
                  color: g.totalReste > 0 ? const Color.fromARGB(255, 58, 84, 212) : Colors.green.shade700,
                ),
              ),
              children: g.items.map((f) => _buildFactureCard(context, f)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFactureCard(BuildContext context, listefactures f) {
    final hasReste = f.soldeFacture > 0;
    final dateStr = _fmtDateCsharp(f.dateFac) ?? '-';

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(
            _strOrNull(f.numFac) ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'TTC: ${_fmtAmount(f.mtttc) ?? '-'}    •    MtRéglé: ${_fmtAmount(f.mtRegle) ?? '-'}',
            style: TextStyle(
              color: hasReste ? const Color.fromARGB(255, 88, 115, 254) : Colors.green.shade700,
            ),
          ),
          trailing: hasReste
              ? _pill('Reste: ${_fmtAmount(f.soldeFacture) ?? '-'}',
                  bg: Colors.red.shade100, fg: Colors.red.shade700)
              : _pill('Soldée', bg: Colors.green.shade100, fg: Colors.green.shade700),
          children: [
            _kv('Date Facture', dateStr),
            _kv('Montant HT', _fmtAmount(f.mtHt)),
            _kv('N° Commande', _strOrNull(f.numCmd)),
            _kv('Différence Date', f.diffDate.toString()),
            _kv('Ville', _strOrNull(f.ville)),
            _kv('Téléphone', _strOrNull(f.tel)),
            _kv('Mode Règlement', _strOrNull(f.mdReg)),
            _kv('Autorisation', _strOrNull(f.autorisation)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return const SizedBox.shrink();

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
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  // ----------------------- Total Bar (compact + trikiBlue) -----------------------
  Widget _buildTotalBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniStat(Icons.monetization_on, 'Total TTC', _fmtAmount(_totalTtcFiltres))),
              const SizedBox(width: 4),
              Expanded(child: _miniStat(Icons.attach_money, 'Total HT', _fmtAmount(_totalHtFiltres))),
              const SizedBox(width: 4),
              Expanded(child: _miniStat(Icons.savings, 'Total Réglé', _fmtAmount(_totalRegleFiltres))),
              const SizedBox(width: 4),
              Expanded(child: _miniStat(Icons.receipt_long, 'NB Factures', '$_nbFacturesFiltres')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _miniStat(Icons.account_balance_wallet, 'Total Reste', _fmtAmount(_totalResteFiltres) ?? '0,000')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: trikiBlue,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: trikiBlue.withOpacity(0.25),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Text(
            value ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
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

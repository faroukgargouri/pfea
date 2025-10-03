import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/preavis.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart'; // TrikiAppBar + trikiBlue

/// ---------- Regroupement par client ----------
class _ClientGroup {
  final String codeClient;
  final String? raison; // affiche nomClient si dispo
  final List<Preavis> items;
  final double totalMontant;

  _ClientGroup({
    required this.codeClient,
    required this.raison,
    required this.items,
    required this.totalMontant,
  });
}

class PreavisclientScreen extends StatefulWidget {
  final String rep;
  final String codeClient;

  const PreavisclientScreen({
    super.key,
    required this.rep,
    required this.codeClient,
  });

  @override
  State<PreavisclientScreen> createState() => _PreavisclientScreenState();
}

class _PreavisclientScreenState extends State<PreavisclientScreen> {
  // ---- intl gating ----
  late final Future<void> _intlReady;

  // ---- Required API params ----
  late final String _rep;

  // ---- Search ----
  final _queryCtrl = TextEditingController();

  // ---- Data ----
  Future<List<Preavis>>? _future;
  List<Preavis> _all = [];
  List<Preavis> _filtered = [];

  // ---- UI ----
  bool _isSearching = false;

  // ---- Header info for TrikiAppBar ----
  String? _fullName;
  String? _codeSage;

  // formatters
  late NumberFormat _nf; // 1 234,567

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
      _future = ApiService.fetchPreavis(rep: _rep).then((rows) {
        // ✅ garder seulement ce client
        final mine = rows.where((r) => r.codeClient == widget.codeClient).toList();
        _all = mine;
        _applyQuery(_queryCtrl.text);
        return mine;
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
    String amt(num v) => _fmtAmount(v)!;

    final out = _all.where((p) {
      final fields = <Object?>[
        p.codeClient,
        p.nomClient,
        p.agence,
        p.typePaiement,
        p.numCheque,
        p.numReg,
        p.societe,
        p.site,
        p.status,
        p.rep1,
        p.rep2,
        amt(p.montant),
        p.dateImpaye,
        p.datePreavis,
        p.dateAnnulationPreavis,
        p.dateRecuperationImpaye,
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
  String? _fmtAmount(num v) => _nf.format(v);

  String? _strOrNull(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  // Considère "date set" si non vide et différente de la valeur .NET par défaut
  bool _isDateSet(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == '01/01/0001') return false;          // .NET ToString("dd/MM/yyyy")
    if (v.startsWith('0001-01-01')) return false; // ISO variant
    return true;
  }

  /// Préavis considéré "impayé" si status == '11' ou contient 'impay'
  bool _isImpaye(Preavis p) {
    final s = (p.status ?? '').toLowerCase();
    return p.status == '11' || s.contains('impay');
  }

  // Totaux globaux (sur filtrés)
  double get _totalMontantFiltres =>
      _filtered.fold(0.0, (t, p) => t + p.montant);
  int get _nbPreavisFiltres => _filtered.length;
  int get _nbImpayeFiltres => _filtered.where(_isImpaye).length;

  List<_ClientGroup> _makeGroups(List<Preavis> rows) {
    final map = <String, List<Preavis>>{};
    for (final p in rows) {
      map.putIfAbsent(p.codeClient, () => []).add(p);
    }

    final groups = <_ClientGroup>[];
    for (final entry in map.entries) {
      final items = entry.value
        ..sort((a, b) {
          // tri par dateImpaye (string) — fallback lexicographique + null-safe
          final ad = a.dateImpaye ?? '';
          final bd = b.dateImpaye ?? '';
          final cmp = bd.compareTo(ad);
          // second clé: numReg lexicographique pour stabilité (null-safe)
          return (cmp != 0) ? cmp : (b.numReg ?? '').compareTo(a.numReg ?? '');
        });

      final total = items.fold<double>(0.0, (t, x) => t + x.montant);

      groups.add(_ClientGroup(
        codeClient: entry.key,
        raison: _strOrNull(items.first.nomClient),
        items: items,
        totalMontant: total,
      ));
    }

    groups.sort((a, b) => a.codeClient.compareTo(b.codeClient));
    return groups;
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

        final pageTitle = 'PRÉAVIS — ${widget.codeClient}';

        return Scaffold(
          // ✅ Single AppBar: white bar + blue strip (text-only) with actions
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
                child: FutureBuilder<List<Preavis>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        onRetry: _refresh,
                        message: 'Impossible de charger les préavis.\nErreur : ${snap.error}',
                      );
                    }
                    if (_filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Aucun résultat',
                        subtitle: 'Aucun préavis ne correspond à votre recherche.',
                        icon: Icons.receipt_long_outlined,
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
                'NbPréavis: ${g.items.length}    •    Montant: ${_fmtAmount(g.totalMontant) ?? '-'}',
                style: const TextStyle(color: Colors.black),
              ),
              children: g.items.map((p) => _buildPreavisCard(context, p)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreavisCard(BuildContext context, Preavis p) {
    final isImpaye = _isImpaye(p);

    // Déterminer la couleur une seule fois
    final Color statusColor = _isDateSet(p.dateAnnulationPreavis)
        ? Colors.green.shade700
        : (_isDateSet(p.dateRecuperationImpaye)
            ? Colors.blue.shade700
            : isImpaye
                ? Colors.red.shade700
                : Colors.blueGrey.shade700);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor, width: 2), // Bordure colorée
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(Icons.receipt_long_outlined, color: statusColor), // Icône assortie
          title: Text(
            'N° Reg: ${_strOrNull(p.numReg) ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Montant: ${_fmtAmount(p.montant) ?? '-'}',
            style: TextStyle(color: statusColor), // Même couleur
          ),
          children: [
            _kv('Agence', _strOrNull(p.agence)),
            _kv('Type Paiement', _strOrNull(p.typePaiement)),
            _kv('N° Chèque', _strOrNull(p.numCheque)),
            _kv('Société', _strOrNull(p.societe)),
            _kv('Site', _strOrNull(p.site)),
            _kv('Date Impayé', _strOrNull(p.dateImpaye)),
            _kv('Date Préavis', _strOrNull(p.datePreavis)),
            _kv('Annulation Préavis', _strOrNull(p.dateAnnulationPreavis)),
            _kv('Récupération Impayé', _strOrNull(p.dateRecuperationImpaye)),
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

  Widget _buildTotalBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: _totalCard(
              icon: Icons.monetization_on,
              title: 'Total Montant',
              value: _fmtAmount(_totalMontantFiltres) ?? '-',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _totalCard(
              icon: Icons.receipt_long,
              title: 'Nb Préavis',
              value: '$_nbPreavisFiltres',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _totalCard(
              icon: Icons.report,
              title: 'Nb Impayés',
              value: '$_nbImpayeFiltres',
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: trikiBlue, // ✅ same as the blue navbar from custom_navbar.dart
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: trikiBlue.withOpacity(0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            value,
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

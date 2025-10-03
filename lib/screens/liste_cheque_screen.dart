import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cheque.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart'; // TrikiAppBar + trikiBlue

class ListeChequeScreen extends StatefulWidget {
  final String rep; // CodeRep (requis)

  const ListeChequeScreen({super.key, required this.rep});

  @override
  State<ListeChequeScreen> createState() => _ListeChequeScreenState();
}

class _ListeChequeScreenState extends State<ListeChequeScreen> {
  // ---- intl gating ----
  late final Future<void> _intlReady;

  // ---- Required API params ----
  late final String _rep;

  // ---- Search ----
  final _queryCtrl = TextEditingController();

  // ---- Data ----
  Future<List<Cheque>>? _future;
  List<Cheque> _all = [];
  List<Cheque> _filtered = [];

  // ---- UI ----
  bool _isSearching = false;

  // ---- Triki header info ----
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
      _future = ApiService.fetchListeCheques(_rep).then((rows) {
        _all = rows;
        _applyQuery(_queryCtrl.text);
        return rows;
      });
    });
  }

  // ----------------------- Single query over ALL fields -----------------------
  void _applyQuery(String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    String amt(num? v) => v == null ? '' : _fmtAmount(v)!;
    final out = _all.where((c) {
      final haystack = [
        (c.numCheq ?? ''),
        (c.codeClient ?? ''),
        (c.raisonSocial ?? ''),
        (c.numReg ?? ''),
        (c.date ?? ''),
        (c.dateEcheance ?? ''),
        (c.agence ?? ''),
        (c.reference ?? ''),
        (c.libelle ?? ''),
        amt(c.portefeuille1),
        amt(c.portefeuille2),
        amt(c.impayee),
      ].join(' · ').toLowerCase();
      return haystack.contains(qq);
    }).toList();
    setState(() => _filtered = out);
  }

  // ----------------------- Helpers -----------------------
  String? _fmtAmount(num? v) => v == null ? null : _nf.format(v);

  String? _fmtDateStrOpt(String? s) {
    final v = (s ?? '').trim();
    if (v.isEmpty) return null;

    final iso = DateTime.tryParse(v);
    if (iso != null) {
      final d = DateTime(iso.year, iso.month, iso.day);
      return DateFormat('d/M/yyyy', 'fr_FR').format(d);
    }

    final parts = v.split(RegExp(r'[\/\\-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        final d = (p0 > 1900) ? DateTime(p0, p1, p2) : DateTime(p2, p1, p0);
        return DateFormat('d/M/yyyy', 'fr_FR').format(d);
      }
    }
    return null;
  }

  double get _totalImpayee => _filtered.fold(0.0, (t, c) => t + (c.impayee ?? 0.0));

  String? _strOrNull(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _intlReady,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final pageTitle = 'ÉTAT CHÈQUES — Rep: $_rep';

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
                child: FutureBuilder<List<Cheque>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        onRetry: _refresh,
                        message: 'Impossible de charger les chèques.\n${snap.error}',
                      );
                    }
                    if (_filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Aucun chèque',
                        subtitle: 'Tapez un mot-clé ou rechargez les données.',
                        icon: Icons.payments_outlined,
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
            hintText: 'Rechercher (toutes colonnes)…',
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

  // ----------------------- UI: Expansion list -----------------------
  Widget _buildExpansionList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _filtered[i];
        final hasDebt = (c.impayee ?? 0) > 0;

        String? portfolioLabel() {
          if ((c.portefeuille1 ?? 0) != 0) return 'Traite: ${_fmtAmount(c.portefeuille1)}';
          if ((c.portefeuille2 ?? 0) != 0) return 'Chèque: ${_fmtAmount(c.portefeuille2)}';
          final r1 = _strOrNull(c.reP1);
          return r1;
        }

        final impStr = _fmtAmount(c.impayee) ?? '0';
        final echStr = _fmtDateStrOpt(c.dateEcheance) ?? '-';

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: const Icon(Icons.description_outlined),
              title: Text(
                _strOrNull(c.numCheq) ?? '-', // fallback visible
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Impayé: $impStr    •    Échéance: $echStr',
                style: TextStyle(
                  color: hasDebt ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              trailing: hasDebt
                  ? Chip(
                      label: const Text('Impayé'),
                      backgroundColor: Colors.red.shade100,
                      labelStyle: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : (portfolioLabel() == null
                      ? null
                      : Chip(
                          label: Text(portfolioLabel()!),
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: const TextStyle(color: Colors.black87),
                        )),
              children: [
                _kv('Code client', _strOrNull(c.codeClient)),
                _kv('Raison sociale', _strOrNull(c.raisonSocial)),
                _kv('N° règlement', _strOrNull(c.numReg)),
                _kv('Date (règlement)', _fmtDateStrOpt(c.date)),
                _kv('Date échéance', _fmtDateStrOpt(c.dateEcheance)),
                _kv('Agence', _strOrNull(c.agence)),
                _kv('Référence', _strOrNull(c.reference)),
                _kv('Libellé', _strOrNull(c.libelle)),
                _kv('traite', _fmtAmount(c.portefeuille1)),
                _kv('chèque', _fmtAmount(c.portefeuille2)),
              ],
            ),
          ),
        );
      },
    );
  }

  // key-value row — N'AFFICHE RIEN si value == null/empty
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

  // ----------------------- UI: Total Bar -----------------------
  Widget _buildTotalBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: trikiBlue, // ✅ same as navbar
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: trikiBlue.withOpacity(0.40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.summarize, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total Impayé',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            _fmtAmount(_totalImpayee) ?? '0,000',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cheque.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_config.dart';
import '../widgets/custom_navbar.dart';

class ChequesScreen extends StatefulWidget {
  final String? codeClient;
  final String? rep; // CodeRep

  const ChequesScreen({super.key, this.codeClient, this.rep});

  @override
  State<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends State<ChequesScreen> {
  // ---- intl gating ----
  late final Future<void> _intlReady;

  // ---- Required API params (locked) ----
  late final String _codeClient;
  late final String _rep;

  // ---- Single search box (filters all visible fields) ----
  final _queryCtrl = TextEditingController();

  // ---- Data ----
  Future<List<Cheque>>? _future;
  List<Cheque> _all = [];
  List<Cheque> _filtered = [];

  // ---- UI state ----
  bool _isSearching = false;

  // ---- Triki header info ----
  String? _fullName;
  String? _codeSage;

  // formatters
  late NumberFormat _nf;

  @override
  void initState() {
    super.initState();

    _codeClient = (widget.codeClient ?? '').trim();
    _rep = (widget.rep ?? '').trim();

    _intlReady = () async {
      Intl.defaultLocale = 'fr_FR';
      await initializeDateFormatting('fr_FR', null);
      _nf = NumberFormat('#,##0.000', 'fr_FR');
    }();

    _loadHeaderUser();
    if (_codeClient.isNotEmpty && _rep.isNotEmpty) {
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

  // ----------------------- AppBar actions -----------------------
  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _search();

  // ----------------------- API search -----------------------
  void _search() {
    if (_codeClient.isEmpty || _rep.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code client et CodeRep requis pour charger les chèques.')),
      );
    } else {
      setState(() {
        _future = _fetch(_codeClient, _rep).then((rows) {
          _all = rows;
          _applyQuery(_queryCtrl.text);
          return rows;
        });
      });
    }
  }

  Future<List<Cheque>> _fetch(String codeClient, String rep) async {
    // Backend route: /api/Client/cheques?codeClient=...&rep=...
    final uri = Uri.parse('$apiRoot/Client/cheques')
        .replace(queryParameters: {'codeClient': codeClient, 'rep': rep});

    final res = await http.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('API error: ${res.statusCode} | ${res.body}');
    }
    final raw = json.decode(res.body);
    final List data = (raw is List) ? raw : (raw['data'] as List? ?? const []);
    return data.map((e) => Cheque.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ----------------------- Single query over ALL fields -----------------------
  void _applyQuery(String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    String amt(double? v) => v == null ? '' : _fmtAmount(v);
    final out = _all.where((c) {
      final haystack = [
        c.numCheq,
        c.codeClient,
        c.raisonSocial,
        c.numReg,
        c.date,
        c.dateEcheance,
        c.agence,
        c.reference,
        c.libelle,
        c.reP1,
        c.reP2,
        amt(c.portefeuille1),
        amt(c.portefeuille2),
        amt(c.portefeuille3),
        amt(c.impayee),
      ].join(' · ').toLowerCase();
      return haystack.contains(qq);
    }).toList();
    setState(() => _filtered = out);
  }

  // ----------------------- Helpers -----------------------
  String _fmtAmount(num? v) => v == null ? '-' : _nf.format(v);

  String _fmtDateStr(String s) {
    if (s.trim().isEmpty) return s;
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      final d = DateTime(iso.year, iso.month, iso.day);
      return DateFormat('d/M/yyyy', 'fr_FR').format(d);
    }
    final parts = s.split(RegExp(r'[\/\\-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        final d = (p0 > 1900) ? DateTime(p0, p1, p2) : DateTime(p2, p1, p0);
        return DateFormat('d/M/yyyy', 'fr_FR').format(d);
      }
    }
    return s;
  }

  double get _totalImpayee =>
      _filtered.fold(0.0, (t, c) => t + (c.impayee ?? 0.0));

  String _dash(String v) => v.trim().isEmpty ? '-' : v.trim();

  @override
  Widget build(BuildContext context) {
    // Build blue label like your other unified navbars
    final parts = <String>[];
    if (_codeClient.isNotEmpty) parts.add(_codeClient);
    if (_rep.isNotEmpty) parts.add('Rep: $_rep');
    final suffix = parts.join(' · ');
    final blueLabel = suffix.isEmpty ? 'ETAT CHEQUES' : 'ETAT CHEQUES — $suffix';

    return FutureBuilder<void>(
      future: _intlReady,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          // ✅ Single TrikiAppBar (white header + blue text-only bar)
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
              BlueNavItem(label: blueLabel, selected: true),
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
          if ((c.portefeuille1 ?? 0) != 0) return 'PF1: ${_fmtAmount(c.portefeuille1)}';
          if ((c.portefeuille2 ?? 0) != 0) return 'PF2: ${_fmtAmount(c.portefeuille2)}';
          if ((c.portefeuille3 ?? 0) != 0) return 'PF3: ${_fmtAmount(c.portefeuille3)}';
          return (c.reP1.trim().isNotEmpty) ? c.reP1 : null;
        }

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
                _dash(c.numCheq),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Impayé: ${_fmtAmount(c.impayee)}    •    Échéance: ${_fmtDateStr(c.dateEcheance)}',
                style: TextStyle(
                  color: hasDebt ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              trailing: (portfolioLabel() == null)
                  ? null
                  : Chip(
                      label: Text(portfolioLabel()!),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
              children: [
                _kv('Code client', _dash(c.codeClient)),
                _kv('Raison sociale', _dash(c.raisonSocial)),
                _kv('N° règlement', _dash(c.numReg)),
                _kv('Date (règlement)', _fmtDateStr(c.date)),
                _kv('Date échéance', _fmtDateStr(c.dateEcheance)),
                _kv('Agence', _dash(c.agence)),
                _kv('Référence', _dash(c.reference)),
                _kv('Libellé', _dash(c.libelle)),
                _kv('Portefeuille 1', _fmtAmount(c.portefeuille1)),
                _kv('Portefeuille 2', _fmtAmount(c.portefeuille2)),
                _kv('Portefeuille 3', _fmtAmount(c.portefeuille3)),
                _kv('Rep 1', _dash(c.reP1)),
                _kv('Rep 2', _dash(c.reP2)),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade700, // same blue as navbar
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.4),
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
            _fmtAmount(_totalImpayee),
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

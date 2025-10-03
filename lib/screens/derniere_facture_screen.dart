// lib/screens/derniere_facture_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/derniere_facture.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart'; // TrikiAppBar, BlueNavItem, BlueNavbarVariant, trikiBlue

class DerniereFactureScreen extends StatefulWidget {
  final String? codeClient;
  const DerniereFactureScreen({super.key, this.codeClient});

  @override
  State<DerniereFactureScreen> createState() => _DerniereFactureScreenState();
}

class _DerniereFactureScreenState extends State<DerniereFactureScreen> {
  late final Future<void> _intlReady;
  late final String _codeClient;

  final _queryCtrl = TextEditingController();
  bool _isSearching = false;

  Future<List<DerniereFacture>>? _future;
  List<DerniereFacture> _all = [];
  List<DerniereFacture> _filtered = [];
  bool _isCachedData = false;

  String? _fullName;
  String? _codeSage;

  late NumberFormat _money;
  late NumberFormat _qty;

  @override
  void initState() {
    super.initState();

    _codeClient = (widget.codeClient ?? '').trim();

    _intlReady = () async {
      Intl.defaultLocale = 'fr_FR';
      await initializeDateFormatting('fr_FR', null);
      _money = NumberFormat('#,##0.000', 'fr_FR');
      _qty   = NumberFormat('#,##0.###', 'fr_FR');
    }();

    _loadHeaderUser();
    if (_codeClient.isNotEmpty) _search(force: true);
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

  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _search(force: true);

  void _search({bool force = false}) {
    if (_codeClient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code client requis.')),
      );
      return;
    }
    if (!force && _future != null) return;

    setState(() {
      _future = ApiService.fetchDerniereFacture(_codeClient).then((rows) {
        _isCachedData = false;
        _all = rows;
        _applyQuery(_queryCtrl.text);
        return rows;
      }).catchError((e) {
        _isCachedData = true;
        throw e;
      });
    });
  }

  void _applyQuery(String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    final out = _all.where((l) {
      final haystack = [
        l.desArticle,
        l.codeArticle,
        l.codeClient,
        l.secteurClient,
        l.dateArticle,
        _fmtQty(l.qteArticle),
        _fmtMoney(l.prixU),
        _fmtMoney(l.prixHT),
        _fmtMoney(l.prixTTC),
      ].join(' · ').toLowerCase();
      return haystack.contains(qq);
    }).toList();
    setState(() => _filtered = out);
  }

  String _fmtMoney(num? v) => (v == null) ? '-' : _money.format(v);
  String _fmtQty(num? v)   => (v == null) ? '-' : _qty.format(v);

  String _fmtDateStr(String s) {
    if (s.trim().isEmpty) return s;
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      final d = DateTime(iso.year, iso.month, iso.day);
      return DateFormat('d/M/yyyy', 'fr_FR').format(d);
    }
    final parts = s.split(RegExp(r'[\/\\-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]), p1 = int.tryParse(parts[1]), p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        final d = (p0 > 1900) ? DateTime(p0, p1, p2) : DateTime(p2, p1, p0);
        return DateFormat('d/M/yyyy', 'fr_FR').format(d);
      }
    }
    return s;
  }

  double get _totalTTC => _filtered.fold(0.0, (t, e) => t + e.prixTTC);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _intlReady,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

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
            blueNavItems: const [
              BlueNavItem(label: 'DERNIÈRE FACTURE', selected: true),
            ],
            blueNavVariant: BlueNavbarVariant.textOnly,
          ),

          body: Column(
            children: [
              if (_isSearching) _buildSingleSearchBar(context),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<DerniereFacture>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        message: 'Impossible de charger les lignes.\n${snap.error}',
                        onRetry: _refresh,
                      );
                    }
                    if (_filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Aucune ligne',
                        subtitle: 'Tapez un mot-clé ou rechargez.',
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
            hintText: 'Rechercher …',
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

  Widget _buildExpansionList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Secteur + Date en-tête
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Center(
            child: Text(
              'Secteur Client: ${_filtered.first.secteurClient}\n'
              'Date: ${_fmtDateStr(_filtered.first.dateArticle ?? '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final l = _filtered[i];
              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${l.codeArticle}:  ${l.desArticle}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _chip('QTE', _fmtQty(l.qteArticle))),
                            const SizedBox(width: 8),
                            Expanded(child: _chip('Prix U', _fmtMoney(l.prixU))),
                            const SizedBox(width: 8),
                            Expanded(child: _chip('Prix HT', _fmtMoney(l.prixHT))),
                            const SizedBox(width: 8),
                            Expanded(child: _chip('Prix TTC', _fmtMoney(l.prixTTC))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTotalBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: trikiBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: trikiBlue.withOpacity(0.4),
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
              'Total TTC',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            _fmtMoney(_totalTTC),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _EmptyState({required this.title, required this.subtitle, required this.icon});

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
            Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

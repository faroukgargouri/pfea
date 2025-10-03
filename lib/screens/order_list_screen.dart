// lib/screens/order_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  Future<void>? _intlReady;
  late NumberFormat _nf;

  Future<List<Order>>? _future;
  List<Order> _all = [];
  List<Order> _today = [];

  List<Order> _filteredAll = [];
  List<Order> _filteredToday = [];

  bool _isSearching = false;
  final _queryCtrl = TextEditingController();
  Timer? _deb;

  String? _fullName;
  String? _codeSage;

  @override
  void initState() {
    super.initState();
    _intlReady = _initIntl();
    _queryCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadHeaderUser().then((_) => _search());
  }

  Future<void> _initIntl() async {
    Intl.defaultLocale = 'fr_FR';
    await initializeDateFormatting('fr_FR', null);
    _nf = NumberFormat('#,##0.000', 'fr_FR');
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
    _deb?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() => setState(() => _isSearching = !_isSearching);
  void _refresh() => _search();

  void _search() {
    final fut = _fetchOrders().then((rows) {
      if (!mounted) return rows;
      _all = rows;
      _today = _onlyToday(rows);
      _applyQuery(_queryCtrl.text);
      return rows;
    });
    setState(() {
      _future = fut;
    });
  }

  Future<List<Order>> _fetchOrders() async {
  try {
    final list = await ApiService.getAllOrders(codeRep: _codeSage ?? '');
    if (!mounted) return list;

    // ✅ Afficher un message seulement si offline ET cache
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ℹ️ Aucune commande trouvée.")),
      );
    }

    return list;
  } catch (e) {
    if (!mounted) return [];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📴 Mode hors ligne : commandes en cache.")),
    );
    return [];
  }
}

  void _applyQuery(String q) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 160), () {
      final qq = q.trim().toLowerCase();

      bool match(Order o) {
        final items = o.items ?? const <OrderItem>[];
        final haystack = [
          o.id?.toString() ?? '-',
          o.displayRef,
          o.clientId,
          _fmtDate(o.createdAt),
          _fmtAmount(_toNum(o.total)),
          items.length.toString(),
          if (o.statutString != null) o.statutString!,
        ].join(' · ').toLowerCase();
        return haystack.contains(qq);
      }

      if (!mounted) return;
      setState(() {
        if (qq.isEmpty) {
          _filteredAll = List.of(_all);
          _filteredToday = List.of(_today);
        } else {
          _filteredAll = _all.where(match).toList();
          _filteredToday = _today.where(match).toList();
        }
      });
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Order> _onlyToday(List<Order> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      final d = o.createdAt.isUtc ? o.createdAt.toLocal() : o.createdAt;
      return _isSameDay(d, now);
    }).toList();
  }

  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse('$v'.replaceAll(',', '.')) ?? 0;
  }

  String _fmtAmount(num? v) => v == null ? '-' : _nf.format(v);

  String _fmtDate(DateTime d) {
    final local = d.isUtc ? d.toLocal() : d;
    final onlyDay = DateTime(local.year, local.month, local.day);
    return DateFormat('d/M/yyyy', 'fr_FR').format(onlyDay);
  }

  double _sumTotal(List<Order> list) =>
      list.fold(0.0, (t, o) => t + _toNum(o.total).toDouble());

  String _fmtClient(Order o) => o.clientId.isEmpty ? '—' : o.clientId;

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  Map<String, List<Order>> _groupByClient(List<Order> src) {
    final map = <String, List<Order>>{};
    for (final o in src) {
      final key = o.clientId.isEmpty ? '—' : o.clientId;
      (map[key] ??= <Order>[]).add(o);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final ad = a.createdAt.isUtc ? a.createdAt.toLocal() : a.createdAt;
        final bd = b.createdAt.isUtc ? b.createdAt.toLocal() : b.createdAt;
        return bd.compareTo(ad);
      });
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _intlReady ?? Future.value(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: TrikiAppBar(
            fullName: _fullName,
            codeSage: _codeSage,
            actionsBeforeLogout: [
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                  tooltip: 'Recharger'),
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: _toggleSearch,
                tooltip: 'Recherche',
              ),
            ],
            blueNavItems: const [
              BlueNavItem(label: 'MES COMMANDES', selected: true)
            ],
            blueNavVariant: BlueNavbarVariant.textOnly,
          ),
          backgroundColor: const Color(0xFFF6F7FB),
          body: Column(
            children: [
              if (_isSearching) _buildSingleSearchBar(context),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          // ✅ même design que chiffre d’affaires
                          Container(
                            color: Colors.white,
                            child: TabBar(
                              indicator: const UnderlineTabIndicator(
                                borderSide: BorderSide(
                                    width: 3.0, color: Color(0xFF0D47A1)),
                                insets: EdgeInsets.symmetric(horizontal: 16.0),
                              ),
                              labelColor: Colors.blue.shade700,
                              unselectedLabelColor: Colors.black54,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              tabs: const [
                                Tab(text: 'AUJOURD’HUI'),
                                Tab(text: 'TOUTES'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _OrdersTabs(
                              future: _future,
                              filteredTodaySeed: _filteredToday,
                              filteredAllSeed: _filteredAll,
                              todaySeed: _today,
                              allSeed: _all,
                              onRetry: _refresh,
                              buildList: _buildGroupedByClient,
                              fmtAmount: _fmtAmount,
                              sumTotal: _sumTotal,
                              queryIsEmpty: _queryCtrl.text.isEmpty,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleSearchBar(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedByClient(BuildContext context, List<Order> data) {
    final grouped = _groupByClient(data);
    final clientKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '—' && b != '—') return 1;
        if (b == '—' && a != '—') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: clientKeys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final clientId = clientKeys[i];
        final orders = grouped[clientId]!;
        final clientTotal = _sumTotal(orders);

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Client: $clientId',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                      Text(_fmtAmount(clientTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                ...orders.map((o) {
                  final items = o.items ?? const <OrderItem>[];
                  final statut = (o.statutString ?? 'En attente').trim();
                  Color chipColor() {
                    switch (statut.toLowerCase()) {
                      case 'validée':
                        return Colors.green.shade600;
                      case 'livrée':
                        return Colors.teal.shade700;
                      case 'annulée':
                        return Colors.red.shade600;
                      case 'retournée':
                        return Colors.orange.shade700;
                      default:
                        return Colors.blueGrey.shade600;
                    }
                  }
                  final createdLocal =
                      o.createdAt.isUtc ? o.createdAt.toLocal() : o.createdAt;

                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(
                        'Commande ${o.displayRef}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${_fmtDate(createdLocal)}  •  Total: ${_fmtAmount(_toNum(o.total))}',
                              style: TextStyle(
                                  color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Chip(
                            label: Text(statut,
                                style:
                                    const TextStyle(color: Colors.white)),
                            backgroundColor: chipColor(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      children: [
                        _kv('Articles (nb)', items.length.toString()),
                        _OrderLines(items: items, fmt: _fmtAmount),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ========= Tabs content + Total bar ========= */

class _OrdersTabs extends StatefulWidget {
  final Future<List<Order>>? future;
  final List<Order> filteredTodaySeed;
  final List<Order> filteredAllSeed;
  final List<Order> todaySeed;
  final List<Order> allSeed;
  final VoidCallback onRetry;
  final Widget Function(BuildContext, List<Order>) buildList;
  final String Function(num?) fmtAmount;
  final double Function(List<Order>) sumTotal;
  final bool queryIsEmpty;

  const _OrdersTabs({
    required this.future,
    required this.filteredTodaySeed,
    required this.filteredAllSeed,
    required this.todaySeed,
    required this.allSeed,
    required this.onRetry,
    required this.buildList,
    required this.fmtAmount,
    required this.sumTotal,
    required this.queryIsEmpty,
  });

  @override
  State<_OrdersTabs> createState() => _OrdersTabsState();
}

class _OrdersTabsState extends State<_OrdersTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DefaultTabController.of(context)!;
    _controller.addListener(_onTab);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget _wrapRefresh(Widget child) => RefreshIndicator(
          onRefresh: () async => widget.onRetry(),
          child: child,
        );

    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Order>>(
            future: widget.future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorState(
                  onRetry: widget.onRetry,
                  message:
                      'Impossible de charger les commandes.\n${snap.error}',
                );
              }

              final listToday =
                  widget.filteredTodaySeed.isEmpty && widget.queryIsEmpty
                      ? widget.todaySeed
                      : widget.filteredTodaySeed;
              final listAll =
                  widget.filteredAllSeed.isEmpty && widget.queryIsEmpty
                      ? widget.allSeed
                      : widget.filteredAllSeed;

              return TabBarView(
                children: [
                  listToday.isEmpty
                      ? _wrapRefresh(const _EmptyState(
                          title: 'Aucune commande aujourd’hui',
                          subtitle:
                              'Tapez un mot-clé ou rechargez les données.',
                          icon: Icons.event_busy,
                        ))
                      : _wrapRefresh(widget.buildList(context, listToday)),
                  listAll.isEmpty
                      ? _wrapRefresh(const _EmptyState(
                          title: 'Aucune commande',
                          subtitle:
                              'Tapez un mot-clé ou rechargez les données.',
                          icon: Icons.receipt_long_outlined,
                        ))
                      : _wrapRefresh(widget.buildList(context, listAll)),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 4, 0, bottomInset),
          child: _TabAwareTotalBar(
            controller: _controller,
            fmt: widget.fmtAmount,
            todayTotal: widget.sumTotal(
              widget.filteredTodaySeed.isEmpty && widget.queryIsEmpty
                  ? widget.todaySeed
                  : widget.filteredTodaySeed,
            ),
            allTotal: widget.sumTotal(
              widget.filteredAllSeed.isEmpty && widget.queryIsEmpty
                  ? widget.allSeed
                  : widget.filteredAllSeed,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabAwareTotalBar extends StatelessWidget {
  final TabController controller;
  final String Function(num?) fmt;
  final double todayTotal;
  final double allTotal;

  const _TabAwareTotalBar({
    required this.controller,
    required this.fmt,
    required this.todayTotal,
    required this.allTotal,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = controller.index == 0;
    final label = isToday
        ? 'Total des commandes (aujourd’hui)'
        : 'Total des commandes';
    final value = isToday ? todayTotal : allTotal;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F57A3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.shade200.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.summarize, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Text(fmt(value),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

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

class _OrderLines extends StatelessWidget {
  final List<OrderItem> items;
  final String Function(num?) fmt;

  const _OrderLines({required this.items, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('Aucune ligne.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            border: Border.all(color: const Color(0xFFE7E9F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('Article')),
                DataColumn(label: Text('Qté')),
                DataColumn(label: Text('P.U.')),
                DataColumn(label: Text('Total')),
              ],
              rows: items.map((it) {
                return DataRow(
                  cells: [
                    DataCell(Text(it.itmref)),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(it.quantity.toString()),
                    )),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(fmt(it.unitPrice)),
                    )),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        fmt(it.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

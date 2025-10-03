import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/referencement_client.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_navbar.dart'; // TrikiAppBar + BlueNavbar

class ReferencementClientPage extends StatefulWidget {
  final String codeClient;

  const ReferencementClientPage({
    Key? key,
    required this.codeClient,
  }) : super(key: key);

  @override
  _ReferencementClientPageState createState() => _ReferencementClientPageState();
}

class _ReferencementClientPageState extends State<ReferencementClientPage> {
  final _logger = Logger('ReferencementClientPage');

  // --- User (for top TrikiAppBar) ---
  String? _fullName;
  String? _codeSage;

  // --- Data ---
  late Future<List<ReferencementClient>> _salesItemsFuture;
  List<ReferencementClient> _allSalesItems = [];
  List<ReferencementClient> _filteredSalesItems = [];
  List<String> gammes = [];

  // --- UI / Search ---
  String? _selectedGamme;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserHeader();
    _fetchSalesItems();
  }

  Future<void> _loadUserHeader() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _fullName = sp.getString('fullName');
      _codeSage = sp.getString('codeSage');
    });
  }

  void _fetchSalesItems() {
    setState(() {
      _salesItemsFuture = ApiService.fetchSalesItems(widget.codeClient).then((items) {
        _allSalesItems = items;
        gammes = items.map((x) => x.gamme ?? 'Unknown Category').toSet().toList();
        _filteredSalesItems = List.from(_allSalesItems);
        final uniqueGammes = <String>{for (var it in items) it.gamme ?? 'Unknown Category'};
        _selectedGamme = _selectedGamme ?? (uniqueGammes.isNotEmpty ? uniqueGammes.first : null);
        return _filteredSalesItems;
      });
    });
  }

  void _filterSalesItems(String query, String? gamme) {
    setState(() {
      _filteredSalesItems = _allSalesItems.where((item) {
        final desArticle = (item.desArticle ?? '').toLowerCase();
        final codeArticle = (item.codeArticle ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        final matchesGamme = gamme == null || (item.gamme ?? 'Unknown Category') == gamme;
        final matchesSearch = desArticle.contains(searchLower) || codeArticle.contains(searchLower);
        return matchesGamme && matchesSearch;
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _selectedGamme = null;
        _filterSalesItems('', null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final blueTitle = 'REFERENCEMENT CLIENT par CMD - ${widget.codeClient}';

    return Scaffold(
      appBar: TrikiAppBar(
        fullName: _fullName,
        codeSage: _codeSage,
        actionsBeforeLogout: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSalesItems,
          ),
          IconButton(
            tooltip: 'Search Items',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        blueNavItems: [BlueNavItem(label: blueTitle, selected: true)],
        blueNavVariant: BlueNavbarVariant.textOnly,
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;

            return Center(
              // Center + max width keeps nice margins on large screens and prevents side overflow
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  children: [
                    if (_isSearching)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _GammeDropdown(
                                    value: _selectedGamme,
                                    gammes: gammes,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGamme = value;
                                        _filterSalesItems(_searchQuery, value);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _SearchField(
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                        _filterSalesItems(value, _selectedGamme);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _toggleSearch,
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                      ),
                                      child: const Text('Fermer Recherche'),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _GammeDropdown(
                                      value: _selectedGamme,
                                      gammes: gammes,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGamme = value;
                                          _filterSalesItems(_searchQuery, value);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: _SearchField(
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                          _filterSalesItems(value, _selectedGamme);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton(
                                    onPressed: _toggleSearch,
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                    ),
                                    child: const Text('Fermer Recherche'),
                                  ),
                                ],
                              ),
                      )
                    else
                      const SizedBox(height: 8),

                    Expanded(
                      child: FutureBuilder<List<ReferencementClient>>(
                        future: _salesItemsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            _logger.warning('Error fetching sales items: ${snapshot.error}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Failed to load sales items',
                                      style: TextStyle(color: Colors.red, fontSize: 16)),
                                  const SizedBox(height: 10),
                                  ElevatedButton(onPressed: _fetchSalesItems, child: const Text('Retry')),
                                ],
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No sales items found'));
                          }

                          final data = snapshot.data!;
                          if (_filteredSalesItems.isEmpty && data.isNotEmpty) {
                            _filteredSalesItems = List.of(data);
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            itemCount: _filteredSalesItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredSalesItems[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Gamme (title)
                                      Text(
                                        item.gamme ?? 'Unknown Category',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Article
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          children: [
                                            const TextSpan(
                                              text: 'Article: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: item.desArticle ?? 'N/A',
                                            ),
                                          ],
                                        ),
                                        softWrap: true,
                                      ),

                                      // Code
                                      const SizedBox(height: 2),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          children: [
                                            const TextSpan(
                                              text: 'Code: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: item.codeArticle ?? 'N/A',
                                            ),
                                          ],
                                        ),
                                        softWrap: true,
                                      ),

                                      const SizedBox(height: 10),

                                      // Quantities as responsive chips
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          _QtyPill(label: 'Qté cmd', value: item.qteCmd?.toString() ?? '0'),
                                          _QtyPill(label: 'Qté vendue (A-1)', value: item.qteVenduP?.toString() ?? '0'),
                                          _QtyPill(label: 'Qté vendue (A)', value: item.qteVenduA?.toString() ?? '0'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Dropdown wrapped for consistent styling and expansion
class _GammeDropdown extends StatelessWidget {
  final String? value;
  final List<String> gammes;
  final ValueChanged<String?> onChanged;

  const _GammeDropdown({
    Key? key,
    required this.value,
    required this.gammes,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: const Text('Choisir Gamme', style: TextStyle(color: Colors.grey)),
        items: gammes.map((g) {
          return DropdownMenuItem<String>(
            value: g,
            child: Text(g, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}

/// Search field with safe defaults
class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({Key? key, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Chercher article ou code',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.blue),
      ),
    );
  }
}

/// Small pill used in the card footer; wraps on narrow screens
class _QtyPill extends StatelessWidget {
  final String label;
  final String value;
  const _QtyPill({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(.25)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
        softWrap: true,
      ),
    );
  }
}

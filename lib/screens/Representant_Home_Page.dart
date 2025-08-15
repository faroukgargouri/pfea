import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/client.dart';
import '../services/api_service.dart';
import 'client_detail_screen.dart';

class RepresentantHomePage extends StatefulWidget {
  const RepresentantHomePage({super.key});

  @override
  State<RepresentantHomePage> createState() => _RepresentantHomePageState();
}

class _RepresentantHomePageState extends State<RepresentantHomePage> {
  String fullName = '';
  String codeSage = '';
  List<Client> _allClients = [];
  List<Client> _filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<bool> _isOnline() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    final userId = p.getInt('userId') ?? 0;

    setState(() {
      fullName = p.getString('fullName') ?? '';
      codeSage = p.getString('codeSage') ?? '';
    });

    final box = await Hive.openBox('clients_cache');
    final cacheKey = 'user_$userId';

    try {
      if (await _isOnline()) {
        // ONLINE: fetch → cache → show
        final data = await ApiService.getClientsByUser(userId);
        await box.put(
          cacheKey,
          data.map((c) => c.toJson()).toList(),
        );
        if (!mounted) return;
        setState(() {
          _allClients = data;
          _filtered = data;
          loading = false;
        });
      } else {
        // OFFLINE: load from cache
        final cached = (box.get(cacheKey) as List?) ?? [];
        final clients =
            cached.map<Client>((e) => Client.fromJson(Map<String, dynamic>.from(e))).toList();
        setState(() {
          _allClients = clients;
          _filtered = clients;
          loading = false;
        });
        if (clients.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mode hors ligne: aucun client en cache.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _filter(String q) {
    final x = q.trim().toLowerCase();
    setState(() {
      _filtered = _allClients.where((c) {
        return c.codeClient.toLowerCase().contains(x) ||
            c.raisonSociale.toLowerCase().contains(x);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    const trikiBlue = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // HEADER — logo at left, user info at right (no cart icon)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/logo.png', height: 34),
            const Spacer(),
            if (!isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'CODE: $codeSage',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(width: 12),
          ],
        ),
        actions: const <Widget>[],
      ),

      body: Column(
        children: [
          // BLUE NAVBAR
          Container(
            color: trikiBlue,
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: const [
                _Tab('CHOIX CLIENT', null),
              ],
            ),
          ),

          // SEARCH
          Container(
            color: const Color(0xFFF6F7FB),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: TextField(
              onChanged: _filter,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un client…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('Aucun client trouvé.'))
                    : isMobile
                        ? ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final c = _filtered[i];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClientDetailScreen(client: c),
                                    ),
                                  );
                                },
                                child: _ClientCard(c: c, accent: trikiBlue),
                              );
                            },
                          )
                        : _DesktopTable(
                            clients: _filtered,
                            onOpenVisit: (c) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClientDetailScreen(client: c),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/* Small widgets */

class _Tab extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _Tab(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client c;
  final Color accent;
  const _ClientCard({required this.c, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              c.codeClient,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.raisonSociale,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniInfo(Icons.phone_outlined, c.telephone),
                    const SizedBox(width: 12),
                    _miniInfo(Icons.location_on_outlined, c.ville),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: accent),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<Client> clients;
  final void Function(Client) onOpenVisit;
  const _DesktopTable({required this.clients, required this.onOpenVisit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              MaterialStateProperty.all(const Color(0xFF0D47A1)),
          headingTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          columns: const [
            DataColumn(label: Text('Code Client')),
            DataColumn(label: Text('Raison Sociale')),
            DataColumn(label: Text('Téléphone')),
            DataColumn(label: Text('Ville')),
          ],
          rows: clients
              .map(
                (c) => DataRow(
                  cells: [
                    DataCell(Text(c.codeClient)),
                    DataCell(
                      InkWell(
                        onTap: () => onOpenVisit(c),
                        child: Text(
                          c.raisonSociale,
                          style: const TextStyle(
                            color: Color(0xFF0D47A1),
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(c.telephone)),
                    DataCell(Text(c.ville)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

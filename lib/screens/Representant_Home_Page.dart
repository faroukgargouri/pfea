import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/reclamation_list_screen.dart';
import 'package:flutter_application_1/screens/visit_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/client.dart';
import '../services/api_service.dart';
import 'client_detail_screen.dart';

// ✅ autres écrans accessibles
import 'Preavis_screen.dart';
import 'liste_cheque_screen.dart';
import 'liste_factures_screen.dart';
import 'order_list_screen.dart';
import 'product_list_screen.dart';

import '../widgets/custom_navbar.dart'; // TrikiAppBar avec showMenu

const trikiBlue = Color(0xFF0D47A1);

class RepresentantHomePage extends StatefulWidget {
  const RepresentantHomePage({super.key});

  @override
  State<RepresentantHomePage> createState() => _RepresentantHomePageState();
}

class _RepresentantHomePageState extends State<RepresentantHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String fullName = '';
  String codeSage = '';
  List<Client> _allClients = [];
  List<Client> _filtered = [];
  bool loading = true;
  bool isOffline = false;

  late final Stream _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((event) {
      // event peut être soit ConnectivityResult (v5), soit List<ConnectivityResult> (v6)
      final status = event is List<ConnectivityResult>
          ? (event.isNotEmpty ? event.first : ConnectivityResult.none)
          : (event as ConnectivityResult);

      if (status != ConnectivityResult.none) {
        _init(sync: true);
      } else {
        setState(() => isOffline = true);
      }
    });
    _init();
  }

  Future<bool> _isOnline() async {
    final res = await Connectivity().checkConnectivity();
    if (res is List<ConnectivityResult>) {
      return res.any((r) => r != ConnectivityResult.none);
    } else if (res is ConnectivityResult) {
      return res != ConnectivityResult.none;
    }
    return false;
  }

 Future<void> _init({bool sync = false}) async {
  final p = await SharedPreferences.getInstance();
  final userId = p.getInt('userId') ?? 0;
  final localFullName = p.getString('fullName') ?? '';
  final localCodeSage = p.getString('codeSage') ?? '';

  setState(() {
    fullName = localFullName;
    codeSage = localCodeSage;
  });

  final box = await Hive.openBox('clients_cache');
  final cacheKey = 'user_$userId';

  final online = await _isOnline();   // ✅ test connexion d’abord

  if (online) {
    try {
      final data = await ApiService.getClientsByUser(localCodeSage);
      await box.put(cacheKey, data.map((c) => c.toJson()).toList());

      if (!mounted) return;
      setState(() {
        _allClients = data;
        _filtered = data;
        loading = false;
        isOffline = false;
      });
    } catch (e) {
      // fallback API KO → cache
      final cached = (box.get(cacheKey) as List?) ?? [];
      final clients = cached.map<Client>((e) =>
          Client.fromJson(Map<String, dynamic>.from(e))).toList();

      if (!mounted) return;
      setState(() {
        _allClients = clients;
        _filtered = clients;
        loading = false;
        isOffline = true;
      });
    }
  } else {
    // ✅ mode hors ligne → cache direct
    final cached = (box.get(cacheKey) as List?) ?? [];
    final clients = cached.map<Client>((e) =>
        Client.fromJson(Map<String, dynamic>.from(e))).toList();

    if (!mounted) return;
    setState(() {
      _allClients = clients;
      _filtered = clients;
      loading = false;
      isOffline = true;
    });

    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode hors ligne: aucun client en cache.')),
      );
    }
  }
}


  void _filter(String q) {
    final x = q.trim().toLowerCase();
    setState(() {
      _filtered = _allClients.where((c) {
        return c.bpcnum.toLowerCase().contains(x) ||
            c.bpcnam.toLowerCase().contains(x) ||
            c.gouvernerat.toLowerCase().contains(x) ||
            c.tel.toLowerCase().contains(x);
      }).toList();
    });
  }

  // ---------- Logout helpers ----------
  Future<void> _performLogout() async {
    final p = await SharedPreferences.getInstance();
    await p.clear(); // supprime toutes les infos persistées

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter')),
        ],
      ),
    );
    if (ok == true) {
      await _performLogout();
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    const navBlue = trikiBlue;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7FB),

      drawer: Drawer(
        width: 320,
        child: SafeArea(
          child: _BlueMenuHome(
            parentContext: context,
            repCode: codeSage,
            repName: fullName,
            onLogout: _confirmLogout,
          ),
        ),
      ),

      appBar: TrikiAppBar(
        fullName: fullName,
        codeSage: codeSage,
        showMenu: true,
        onLogout: (_) async => _confirmLogout(),
      ),

      body: Column(
        children: [
          Container(
            color: navBlue,
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: const [
                _Tab('CHOIX CLIENT', null),
              ],
            ),
          ),

          // Recherche
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Liste clients
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('Aucun client trouvé.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c = _filtered[i];
                          return InkWell(
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();

                              await prefs.setString('clientId', c.bpcnum);
                              await prefs.setString('NomClient', c.bpcnam);
                              await prefs.setString('AdresseClient', c.gouvernerat);
                              await prefs.setString('NomRep', fullName);
                              await prefs.setString('CodeRep', codeSage);

                              final userId = prefs.getInt('userId') ?? 0;
                              await prefs.setInt('userId', userId);

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClientDetailScreen(client: c),
                                ),
                              );
                            },
                            child: _ClientCard(c: c, accent: navBlue),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/* ========= MENU BLEU ========= */
class _BlueMenuHome extends StatelessWidget {
  final BuildContext parentContext;
  final String repCode;
  final String repName;
  final Future<void> Function() onLogout;

  const _BlueMenuHome({
    required this.parentContext,
    required this.repCode,
    required this.repName,
    required this.onLogout,
    super.key,
  });

  void _pushAfterClose(BuildContext drawerCtx, WidgetBuilder builder, {String name = ''}) {
    Navigator.pop(drawerCtx);
    Navigator.of(parentContext).push(
      MaterialPageRoute(
        settings: RouteSettings(name: name.isEmpty ? 'unknown' : name),
        builder: builder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = trikiBlue;

    return Container(
      color: blue,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        children: [
          // Header représentant
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.person_pin, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    repName.isEmpty ? 'Représentant' : repName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Text('CODE: ${repCode.isEmpty ? '-' : repCode}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 16),
          _menuItem(Icons.pending_actions, 'Fac NRG (tous clients)', () {
            _pushAfterClose(context, (_) => ListFactureScreen(rep: repCode), name: 'FacturesNRGAll');
          }),
          _menuItem(Icons.history, 'Liste de tous les chèques', () {
            _pushAfterClose(context, (_) => ListeChequeScreen(rep: repCode), name: 'ChequesAll');
          }),
          _menuItem(Icons.report_problem, 'Liste des Réclamations', () {
            _pushAfterClose(context, (_) => const ReclamationListScreen(), name: 'ReclamationsAll');
          }),
          _menuItem(Icons.assignment, 'Liste des Visites', () {
            _pushAfterClose(context, (_) => const VisitListScreen(), name: 'VisitsAll');
          }),
          _menuItem(Icons.rule_folder_outlined, 'États des Préavis & Impayés', () {
            _pushAfterClose(context, (_) => PreavisScreen(rep: repCode), name: 'Preavis');
          }),
          _menuItem(Icons.rule_folder_outlined, 'Mes Commandes', () {
            _pushAfterClose(context, (_) => const OrderListScreen(), name: 'commandes');
          }),

          const Divider(color: Colors.white24, height: 16),
          _menuItem(Icons.logout, 'Déconnexion', () async {
            Navigator.pop(context);
            await onLogout();
          }),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

/* ========= Petits widgets ========= */
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
          backgroundColor: Colors.transparent,
          overlayColor: Colors.white24,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              c.bpcnum,
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
                  c.bpcnam,
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
                    _miniInfo(Icons.phone_outlined, c.tel),
                    const SizedBox(width: 12),
                    _miniInfo(Icons.location_on_outlined, c.gouvernerat),
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
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

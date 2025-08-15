import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import 'visit_screen.dart';
import 'product_list_screen.dart';
import 'order_list_screen.dart';
import 'reclamation_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _userId;
  String _fullName = '';
  String _codeSage = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _userId = p.getInt('userId');
      _fullName = p.getString('fullName') ?? '';
      _codeSage = p.getString('codeSage') ?? '';
    });
  }

  void _goToReclamation() {
    if (_userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReclamationScreen(
          representant: _fullName,
          client: widget.client.raisonSociale,
          telephone: widget.client.telephone,
          userId: _userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    const trikiBlue = Color(0xFF0D47A1);
    final client = widget.client;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7FB),

      // ===== Drawer (BLUE MENU) =====
      drawer: Drawer(
        width: 320,
        child: SafeArea(
          child: _BlueMenu(onReclamation: _goToReclamation),
        ),
      ),

      // ===== Header =====
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 34),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderListScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),

      body: Column(
        children: [
          // ===== Blue navbar =====
          Container(
            height: 42,
            color: trikiBlue,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _TabBtn('CHOIX CLIENT', () => Navigator.pop(context)),
               
              ],
            ),
          ),

          // ===== Content (same as your previous stateless version) =====
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          children: [
                            _HeaderCard(client: client, accent: trikiBlue),
                            const SizedBox(height: 16),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _LeftColumn(client: client)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _RightColumn(client: client, accent: trikiBlue)),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _ActionsBar(client: client),
                                  const SizedBox(height: 12),
                                  _InfoCards(client: client),
                                  const SizedBox(height: 12),
                                  _QuickPanels(client: client, accent: trikiBlue),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Blue Drawer Menu ---------------- */

class _BlueMenu extends StatelessWidget {
  final VoidCallback onReclamation;
  const _BlueMenu({required this.onReclamation});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0D47A1);
    return Container(
      color: blue,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        children: [
          _menuItem(Icons.account_balance_wallet, 'RECOUVREMENT', () {}),
          _menuItem(Icons.report_problem, 'RÉCLAMATION', onReclamation),
          _menuItem(Icons.ssid_chart, "CHIFFRE D'AFFAIRES", () {}),
          _menuItem(Icons.link, 'RÉFÉRENCES CLIENT', () {}),
          _menuItem(Icons.receipt_long, 'FACTURES', () {}),
          _menuItem(Icons.warning, 'RELIQUATS', () {}),
          _menuItem(Icons.history, 'DERNIÈRE FACTURE', () {}),
          _menuItem(Icons.pending_actions, 'CMD EN INSTANCE', () {}),
          _menuItem(Icons.list_alt, 'CHÈQUES', () {}),
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
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

/* ---------------- rest (unchanged components) ---------------- */

class _TabBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TabBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Client client;
  final Color accent;
  const _HeaderCard({required this.client, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: accent.withOpacity(.08),
            child: Text(
              _initials(client.raisonSociale),
              style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.raisonSociale,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: [
                    _chip(Icons.qr_code_2, client.codeClient),
                    if (client.ville.isNotEmpty) _chip(Icons.location_on_outlined, client.ville),
                    if (client.telephone.isNotEmpty) _chip(Icons.phone_outlined, client.telephone),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  final Client client;
  const _LeftColumn({required this.client});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionsBar(client: client),
        const SizedBox(height: 12),
        _InfoCards(client: client),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  final Client client;
  final Color accent;
  const _RightColumn({required this.client, required this.accent});
  @override
  Widget build(BuildContext context) => _QuickPanels(client: client, accent: accent);
}

class _ActionsBar extends StatelessWidget {
  final Client client;
  const _ActionsBar({required this.client});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VisitScreen(
                    codeClient: client.codeClient,
                    raisonSociale: client.raisonSociale,
                    codeSage: null,
                    fullName: null,
                    telephone: client.telephone,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('Créer Visite'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFEFF2FC),
              foregroundColor: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen()));
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Passer commande'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF0D47A1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              foregroundColor: const Color(0xFF0D47A1),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCards extends StatelessWidget {
  final Client client;
  const _InfoCards({required this.client});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _infoTile('Code client', client.codeClient, Icons.qr_code_2),
        _infoTile('Raison sociale', client.raisonSociale, Icons.apartment_outlined),
        _infoTile('Téléphone', client.telephone.isEmpty ? '—' : client.telephone,
            Icons.phone_outlined),
        _infoTile('Ville', client.ville.isEmpty ? '—' : client.ville,
            Icons.location_city_outlined),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      decoration: _card(fill: const Color(0xFFF2F3FA)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _QuickPanels extends StatelessWidget {
  final Client client;
  final Color accent;
  const _QuickPanels({required this.client, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _miniPanel(
          title: 'Contact rapide',
          child: Row(
            children: [
              Expanded(
                child: _quickBtn(
                  icon: Icons.phone,
                  label: 'Appeler',
                  onTap: client.telephone.isEmpty ? null : () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickBtn(
                  icon: Icons.location_on,
                  label: 'Localiser',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickBtn({required IconData icon, required String label, VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFEFF2FC),
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _miniPanel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/* helpers */

BoxDecoration _card({Color? fill}) => BoxDecoration(
      color: fill ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E9F0)),
      boxShadow: const [
        BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 6)),
      ],
    );

Widget _chip(IconData icon, String text) => Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: const Color(0xFFF2F4F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

String _initials(String s) {
  final parts = s.split(RegExp(r'[-_\s]')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'C';
  final a = parts.first[0];
  final b = parts.length > 1 ? parts.last[0] : '';
  return (a + b).toUpperCase();
}

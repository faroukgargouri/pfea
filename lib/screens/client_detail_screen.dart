import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/Preavis_screen.dart';
import 'package:flutter_application_1/screens/chiffre_affaire_screen.dart';
import 'package:flutter_application_1/screens/liste_cheque_screen.dart';
import 'package:flutter_application_1/screens/liste_factures_screen.dart';
import 'package:flutter_application_1/screens/preavis_client_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/client.dart';
import 'visit_screen.dart';
import 'product_list_screen.dart';
import 'order_list_screen.dart';
import 'reclamation_screen.dart';
import 'referencement_client_screen.dart' as refs;
import 'reliquats_screen.dart';
import 'facture_screen.dart' as inv;
import 'derniere_facture_screen.dart';
import 'cmd_screen.dart';
import 'cheques_screen.dart';

const trikiBlue = Color(0xFF0D47A1);

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

  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 3);

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _userId = p.getInt('userId');
      _fullName = p.getString('fullName') ?? '';
      _codeSage = p.getString('codeSage') ?? '';
    });
  }

  // ---------- Logout ----------
  Future<void> _performLogout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('userId');
    await p.remove('fullName');
    await p.remove('codeSage');
    await p.remove('token'); // if present
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
    if (ok == true) await _performLogout();
  }
  // ---------------------------------------------------

  void _goToReclamation() {
    if (_userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'Reclamation'),
        builder: (_) => ReclamationScreen(
          representant: _fullName,
          client: widget.client.bpcnam,
          telephone: widget.client.tel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final isMobile = size.width < 700;
    final client = widget.client;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: Drawer(
        width: 320,
        child: SafeArea(
          child: _BlueMenu(
            parentContext: context,
            onReclamation: _goToReclamation,
            client: client,
            repCode: _codeSage,
            repName: _fullName,
          ),
        ),
      ),
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
          ],
        ),
        actions: [
          if (isMobile)
            IconButton(
              tooltip: 'Se déconnecter',
              icon: const Icon(Icons.logout, color: Colors.black87),
              onPressed: _confirmLogout,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Déconnexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black26),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
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
                                  Expanded(child: _LeftColumn(client: client, repCode: _codeSage)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _RightColumn(client: client, accent: trikiBlue)),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _ActionsBar(client: client, repCode: _codeSage),
                                  const SizedBox(height: 12),
                                  _CommercialTerms(client: client),
                                  const SizedBox(height: 12),
                                  _FinancialPanel(client: client),
                                  const SizedBox(height: 12),
                                  _FiscalPanel(client: client),
                                  const SizedBox(height: 12),
                                  _LastOrderPanel(client: client),
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





class _BlueMenu extends StatelessWidget {
  final VoidCallback onReclamation;
  final BuildContext parentContext;
  final Client client;
  final String repCode;
  final String repName;

  const _BlueMenu({
    required this.onReclamation,
    required this.parentContext,
    required this.client,
    required this.repCode,
    required this.repName,
    super.key,
  });

  void _nav(BuildContext drawerCtx, WidgetBuilder builder, {String name = ''}) {
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
          _menuItem(Icons.report_problem, 'RÉCLAMATION', () {
            Navigator.pop(context);
            onReclamation();
          }),
          _menuItem(Icons.link, 'RÉFÉRENCES CLIENT', () {
            _nav(
              context,
              (_) => refs.ReferencementClientPage(codeClient: client.bpcnum),
              name: 'ClientRefsScreen',
            );
          }),
          _menuItem(Icons.receipt_long, 'FACTURES (impayées)', () {
            _nav(
              context,
              (_) => inv.FactureScreen(codeClient: client.bpcnum, rep: repCode),
              name: 'Invoices',
            );
          }),
          _menuItem(Icons.warning, 'RELIQUATS', () {
            _nav(
              context,
              (_) => ReliquatsScreen(codeClient: client.bpcnum, site: client.site),
              name: 'Reliquats',
            );
          }),
          _menuItem(Icons.history, 'DERNIÈRE FACTURE', () {
            _nav(context, (_) => DerniereFactureScreen(codeClient: client.bpcnum), name: 'LastInvoice');
          }),
          _menuItem(Icons.pending_actions, 'CMD EN INSTANCE', () {
            _nav(context, (_) => CmdScreen(rep: repCode), name: 'Cmd');
          }),
          _menuItem(Icons.pending_actions, 'Chiffre Affaire', () {
            _nav(context, (_) => ChiffreAffairesScreen(subCodeClient: client.bpcnum, raisonSocial: client.bpcnam), name: 'ChiffreAffaire');
          }),
          _menuItem(Icons.pending_actions, 'Chèques', () {
            _nav(context, (_) => ChequesScreen(codeClient: client.bpcnum, rep: repCode), name: 'Cheques');
          }),
          _menuItem(Icons.pending_actions, 'preavis', () {
            _nav(context, (_) => PreavisclientScreen(codeClient: client.bpcnum, rep: repCode), name: 'preavis');
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

class _TabBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TabBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
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

class _HeaderCard extends StatelessWidget {
  final Client client;
  final Color accent;
  const _HeaderCard({required this.client, required this.accent});

  bool _has(String? s) => s != null && s.trim().isNotEmpty;

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: accent.withOpacity(.08),
            child: Text(
              _initials(client.bpcnam),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.bpcnam,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Code: ${client.bpcnum}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_has(client.gouvernerat)) _infoRow(Icons.location_on_outlined, client.gouvernerat!.trim()),
                if (_has(client.tel)) _infoRow(Icons.phone_outlined, client.tel!.trim()),
                if (_has(client.email)) _infoRow(Icons.email_outlined, client.email!.trim()),
                if (_has(client.adresseDefaut)) _infoRow(Icons.home_outlined, client.adresseDefaut!.trim()),
                if (_has(client.adresseLiv)) _infoRow(Icons.local_shipping_outlined, client.adresseLiv!.trim()),
                if (_has(client.site)) _infoRow(Icons.factory_outlined, client.site!.trim()),
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
  final String repCode;
  const _LeftColumn({required this.client, required this.repCode});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          _ActionsBar(client: client, repCode: repCode),
          const SizedBox(height: 12),
          _CommercialTerms(client: client),
          const SizedBox(height: 12),
          _FinancialPanel(client: client),
        ],
      );
}

class _RightColumn extends StatelessWidget {
  final Client client;
  final Color accent;
  const _RightColumn({required this.client, required this.accent});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          _FiscalPanel(client: client),
          const SizedBox(height: 12),
          _LastOrderPanel(client: client),
          const SizedBox(height: 12),
          _QuickPanels(client: client, accent: accent),
        ],
      );
}

class _ActionsBar extends StatelessWidget {
  final Client client;
  final String repCode;
  const _ActionsBar({required this.client, required this.repCode});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'Visit'),
                        builder: (_) => VisitScreen(
                          codeClient: client.bpcnum,
                          raisonSociale: client.bpcnam,
                          codeSage: null,
                          fullName: null,
                          telephone: client.tel,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Créer Visite'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFEFF2FC),
                    foregroundColor: trikiBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'Products'),
                        builder: (_) => const ProductListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Passer commande'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: trikiBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: trikiBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

class _CommercialTerms extends StatelessWidget {
  final Client client;
  const _CommercialTerms({required this.client});

  @override
  Widget build(BuildContext context) => _panel(
        title: 'Conditions commerciales',
        children: [
          _kv('Régime Taxe', client.regimeTaxe),
          _kv('Condition Paiement', client.conditionPayement),
          _kv('Contrôle Encours', client.controlEncours),
        ],
      );
}

class _FinancialPanel extends StatelessWidget {
  final Client client;
  const _FinancialPanel({required this.client});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 3);
    return _panel(
      title: 'Situation financière',
      children: [
        _kv('Encours autorisé', client.encoursAutorise != null ? '${money.format(client.encoursAutorise)} TND' : null),
        _kv('Total encours', client.totalEncours != null ? '${money.format(client.totalEncours)} TND' : null),
        _kv(
          'Cmd non soldée & non livrée',
          client.cmdEncorsNonSoldeeNonLivree != null ? '${money.format(client.cmdEncorsNonSoldeeNonLivree)} TND' : null,
        ),
      ],
    );
  }
}

class _FiscalPanel extends StatelessWidget {
  final Client client;
  const _FiscalPanel({required this.client});

  @override
  Widget build(BuildContext context) => _panel(
        title: 'Informations fiscales',
        children: [
          _kv('Matricule Fiscale', client.matriculeFiscale),
          _kv('Famille Client', client.familleClient),
        ],
      );
}

class _LastOrderPanel extends StatelessWidget {
  final Client client;
  const _LastOrderPanel({required this.client});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 3);
    String? dateStr;
    if (client.dateCommandeClient != null && client.dateCommandeClient.toString().isNotEmpty) {
      dateStr = client.dateCommandeClient.toString();
    }
    return _panel(
      title: 'Dernière commande',
      children: [
        _kv('Réf. commande client', client.refCommandeClient),
        _kv('N° commande', client.nCommande),
        _kv('Date', dateStr),
        _kv('Montant ligne HT', client.mtLigneHT != null ? '${money.format(client.mtLigneHT)} TND' : null),
        _kv('Montant ligne TTC', client.mtLigneTTC != null ? '${money.format(client.mtLigneTTC)} TND' : null),
      ],
    );
  }
}

class _QuickPanels extends StatelessWidget {
  final Client client;
  final Color accent;
  const _QuickPanels({required this.client, required this.accent});

  Future<void> _callPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: "tel", path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$address");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _miniPanel(
          title: 'Contact & Localisation',
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: client.tel != null && client.tel!.isNotEmpty
                    ? () => _callPhone(client.tel!)
                    : null,
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Appeler'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFEFF2FC),
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: client.adresseDefaut != null && client.adresseDefaut!.isNotEmpty
                    ? () => _openMap(client.adresseDefaut!)
                    : null,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('Localiser'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFEFF2FC),
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ]);

  Widget _miniPanel({required String title, required Widget child}) => Container(
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

BoxDecoration _card({Color? fill}) => BoxDecoration(
      color: fill ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E9F0)),
      boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 6))],
    );

Widget _panel({required String title, required List<Widget> children}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ...children.where((c) => c is! SizedBox), // cache lignes vides
        ],
      ),
    );

/// ✅ Nouveau `_kv` qui cache les champs vides
Widget _kv(String k, String? v) {
  if (v == null || v.trim().isEmpty || v == '—') {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 210,
          child: Text(
            k,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

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

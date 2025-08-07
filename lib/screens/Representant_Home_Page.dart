import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/order_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../services/api_service.dart';
import 'visit_screen.dart';
import 'product_list_screen.dart'; // 👈 Add this import

class RepresentantHomePage extends StatefulWidget {
  const RepresentantHomePage({super.key});

  @override
  State<RepresentantHomePage> createState() => _RepresentantHomePageState();
}

class _RepresentantHomePageState extends State<RepresentantHomePage> {
  String fullName = '';
  String codeSage = '';
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;
    String name = prefs.getString('fullName') ?? '';
    String code = prefs.getString('codeSage') ?? '';

    setState(() {
      fullName = name;
      codeSage = code;
    });

    try {
      final clients = await ApiService.getClientsByUser(userId);
      setState(() {
        _allClients = clients;
        _filteredClients = clients;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    }
  }

  void _filterClients(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredClients = _allClients.where((c) =>
          c.codeClient.toLowerCase().contains(lower) ||
          c.raisonSociale.toLowerCase().contains(lower)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Image.asset('assets/logo.png', height: 50),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fullName,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    Text("CODE: $codeSage",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                   IconButton(
  icon: const Icon(Icons.shopping_cart, color: Colors.black),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderListScreen()),
    );
  },
),

                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: const Text('0',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue[900],
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NavBarButton(label: 'CHOIX CLIENT', onTap: () {}),
                NavBarButton(label: 'DETAIL CLIENT', onTap: () {}),
                NavBarButton(
                    label: 'PASSATION COMMANDE',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(),
                        ),
                      );
                    }),
                NavBarButton(label: 'PROMOTIONS', onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterClients,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? const Center(child: Text("Aucun client trouvé."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor:
                                MaterialStateProperty.all(Colors.indigo),
                            headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            columns: const [
                              DataColumn(label: Text("Code Client")),
                              DataColumn(label: Text("Raison Sociale")),
                              DataColumn(label: Text("Téléphone")),
                              DataColumn(label: Text("Ville")),
                            ],
                            rows: _filteredClients.map((client) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(client.codeClient)),
                                  DataCell(
                                    InkWell(
                                      onTap: () async {
                                        SharedPreferences prefs =
                                            await SharedPreferences.getInstance();
                                        final codeSage = prefs.getString('codeSage');
                                        final fullName = prefs.getString('fullName');

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => VisitScreen(
                                              codeClient: client.codeClient,
                                              raisonSociale: client.raisonSociale,
                                              codeSage: codeSage,
                                              fullName: fullName,
                                              telephone: '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        client.raisonSociale,
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(client.telephone)),
                                  DataCell(Text(client.ville)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class NavBarButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const NavBarButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

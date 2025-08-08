import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reclamation_screen.dart';

class VisitScreen extends StatefulWidget {
  final String codeClient;
  final String raisonSociale;
  final String? codeSage;
  final String? fullName;
  final String telephone;

  const VisitScreen({
    super.key,
    required this.codeClient,
    required this.raisonSociale,
    required this.telephone,
    this.codeSage,
    this.fullName,
  });

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  late TextEditingController _dateController;
  final TextEditingController _noteController = TextEditingController();
  late String codeVisite;
  int? userId; // ✅ Ajout du userId

  @override
  void initState() {
    super.initState();
    _loadUserId();

    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );

    final code = (widget.codeSage ?? 'XXX').padRight(3, 'X').substring(0, 3).toUpperCase();
    final dateCode = DateFormat('ddMMyy').format(DateTime.now());
    codeVisite = "$code$dateCode";
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveVisit() async {
    final url = Uri.parse('http://192.168.1.18:5274/api/visite');

    final body = jsonEncode({
      "codeVisite": codeVisite,
      "dateVisite": _dateController.text.trim(),
      "codeClient": widget.codeClient,
      "raisonSociale": widget.raisonSociale,
      "compteRendu": _noteController.text.trim(),
      "userId": userId,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Visite enregistrée.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'enregistrement.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const BackButton(color: Colors.black),
                Image.asset('assets/logo.png', height: 45),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.fullName ?? '', style: const TextStyle(color: Colors.black)),
                    Text("CODE: ${widget.codeSage ?? ''}", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 12),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.black),
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          Container(
            color: const Color(0xFF0D47A1),
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                TopNavItem(label: "CHOIX CLIENT"),
                TopNavItem(label: "DETAIL CLIENT"),
                TopNavItem(label: "PASSATION COMMANDE"),
                TopNavItem(label: "PROMOTIONS"),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                Container(
                  width: 250,
                  color: const Color(0xFF0D47A1),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      VerticalMenuItem(
                        icon: Icons.account_balance_wallet,
                        label: "RECOUVREMENT",
                        onTap: () {},
                      ),
                      VerticalMenuItem(
                        icon: Icons.report_problem,
                        label: "RECLAMATION",
                        onTap: () {
                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReclamationScreen(
                                  representant: widget.fullName ?? '',
                                  client: widget.raisonSociale,
                                  telephone: widget.telephone,
                                  userId: userId!, // ✅ Passage obligatoire
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      VerticalMenuItem(icon: Icons.bar_chart, label: "CHIFFRE D'AFFAIRE"),
                      VerticalMenuItem(icon: Icons.link, label: "REFERENCEMENT CLIENT PAR CMD"),
                      VerticalMenuItem(icon: Icons.receipt, label: "FACTURES NON REGLEES"),
                      VerticalMenuItem(icon: Icons.refresh, label: "RELIQUATS DES COMMANDES"),
                      VerticalMenuItem(icon: Icons.receipt_long, label: "DERNIÈRE FACTURE"),
                      VerticalMenuItem(icon: Icons.pending_actions, label: "COMMANDES EN INSTANCE"),
                      VerticalMenuItem(icon: Icons.list_alt, label: "LISTE DES CHÈQUES"),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Code Visite: $codeVisite",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 20),
                              _buildLabeledField("Date Visite", _dateController, readOnly: true, onTap: _selectDate),
                              _buildStaticField("Code Client", widget.codeClient),
                              _buildStaticField("Raison Sociale", widget.raisonSociale),
                              _buildLabeledField("Compte Rendu", _noteController, maxLines: 4),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _saveVisit,
                                icon: const Icon(Icons.save),
                                label: const Text("Sauvegarder"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[100],
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class VerticalMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const VerticalMenuItem({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopNavItem extends StatelessWidget {
  final String label;

  const TopNavItem({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextButton(
        onPressed: () {},
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}

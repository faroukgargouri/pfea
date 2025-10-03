import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/reclamation.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart'; // ✅ import TrikiAppBar

class ReclamationListScreen extends StatefulWidget {
  const ReclamationListScreen({super.key});

  @override
  State<ReclamationListScreen> createState() => _ReclamationListScreenState();
}

class _ReclamationListScreenState extends State<ReclamationListScreen> {
  Future<List<Reclamation>>? _reclamationsFuture;

  String? _fullName;
  String? _codeSage;

  @override
  void initState() {
    super.initState();
    _loadHeaderUser();
    _loadReclamations();
  }

  Future<void> _loadHeaderUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName');
      _codeSage = prefs.getString('codeSage');
    });
  }

  Future<void> _loadReclamations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    setState(() {
      _reclamationsFuture = ApiService.getReclamationsByUser(userId)
          .then((list) => list.map((e) => Reclamation.fromJson(e)).toList());
    });
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return "—";
      final parsed = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrikiAppBar(
        fullName: _fullName,
        codeSage: _codeSage,
        blueNavItems: const [
          BlueNavItem(
            label: 'MES RÉCLAMATIONS',
            selected: true,
          ),
        ],
        blueNavVariant: BlueNavbarVariant.textOnly,
      ),
      body: FutureBuilder<List<Reclamation>>(
        future: _reclamationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("❌ Erreur : ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune réclamation trouvée."));
          }

          final reclamations = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadReclamations,
            child: ListView.builder(
              itemCount: reclamations.length,
              itemBuilder: (context, index) {
                final r = reclamations[index];

                // ✅ filtrer les articles vides
                final validArticles = (r.articles ?? [])
                    .where((a) =>
                        (a.nomArticle.isNotEmpty) ||
                        (a.codeArticle.isNotEmpty) ||
                        (a.quantite != null && a.quantite! > 0) ||
                        (a.montant != null && a.montant! > 0))
                    .toList();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ExpansionTile(
                    title: Text(
                      "Réclamation #${r.reclamationNo}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(
                            text: "Date: ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                  text: _formatDate(r.dateReclamation),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal))
                            ])),
                        Text.rich(TextSpan(
                            text: "Client: ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                  text: r.client,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal))
                            ])),
                        Text.rich(TextSpan(
                            text: "Téléphone: ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                  text: r.telephone,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal))
                            ])),
                      ],
                    ),
                    children: [
                      if (r.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text.rich(TextSpan(
                                text: "Note: ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                      text: r.note,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                          ),
                        ),
                      if (r.retourLivraison.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text.rich(TextSpan(
                                text: "Retour: ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                      text: r.retourLivraison,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                          ),
                        ),
                      if (r.echange.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text.rich(TextSpan(
                                text: "Échange: ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                      text: r.echange,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                          ),
                        ),

                      // ✅ Section Articles affichée uniquement si au moins 1 article valide
                      if (validArticles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Articles (${validArticles.length}):",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              ...validArticles.map((a) => Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (a.nomArticle.isNotEmpty)
                                            Text(
                                              a.nomArticle,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                          if (a.codeArticle.isNotEmpty ||
                                              (a.quantite != null &&
                                                  a.quantite! > 0))
                                            Text(
                                                "Code: ${a.codeArticle} — Qté: ${a.quantite}"),
                                          if (a.montant != null &&
                                              a.montant! > 0)
                                            Text(
                                                "${a.montant!.toStringAsFixed(2)} DT",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.deepPurple)),
                                          if (a.dateFabrication != null &&
                                              a.dateFabrication!.isNotEmpty)
                                            Text(
                                                "Date Fabrication: ${a.dateFabrication}"),
                                          if (a.factureNo != null &&
                                              a.factureNo!.isNotEmpty)
                                            Text("Facture No: ${a.factureNo}"),
                                          if (a.dateFacture != null &&
                                              a.dateFacture!.isNotEmpty)
                                            Text("Date Facture: ${a.dateFacture}"),
                                          if (a.observation != null &&
                                              a.observation!.isNotEmpty)
                                            Text("Observation: ${a.observation}"),
                                        ],
                                      ),
                                    ),
                                  ))
                            ],
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

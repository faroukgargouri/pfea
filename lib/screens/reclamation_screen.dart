import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'reclamation_list_screen.dart'; // Affiche la liste après soumission

class ReclamationScreen extends StatefulWidget {
  final String representant;
  final String client;
  final String telephone;
  final int userId; // ✅ userId passé directement

  const ReclamationScreen({
    super.key,
    required this.representant,
    required this.client,
    required this.telephone,
    required this.userId,
  });

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  late TextEditingController noteController;

  Map<String, bool> retourLivraison = {
    'Erreur CMD': false,
    'Dommage Transport': false,
    'Paiement Non Dispo': false,
    'Erreur Fabrication': false,
    'Autre Raison': false,
  };

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController();
  }

  String _getRetourLivraisonString() {
    return retourLivraison.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(', ');
  }

  Future<void> _submitReclamation() async {
    if (noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    final url = Uri.parse("http://192.168.100.105:5274/api/reclamation");

    final body = jsonEncode({
      "client": widget.client,
      "telephone": widget.telephone,
      "note": noteController.text,
      "retourLivraison": _getRetourLivraisonString(),
      "userId": widget.userId,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Réclamation envoyée !")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReclamationListScreen(userId: widget.userId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Réclamation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Client : ${widget.client}"),
              Text("Téléphone : ${widget.telephone}"),
              const SizedBox(height: 10),
              const Text("Retour livraison :"),
              ...retourLivraison.keys.map(
                (key) => CheckboxListTile(
                  title: Text(key),
                  value: retourLivraison[key],
                  onChanged: (value) {
                    setState(() {
                      retourLivraison[key] = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text("Note :"),
              TextField(
                controller: noteController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Saisir une note',
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitReclamation,
                  child: const Text("Envoyer"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

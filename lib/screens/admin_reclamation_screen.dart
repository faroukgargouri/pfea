import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/reclamation.dart';

class AdminReclamationScreen extends StatefulWidget {
  const AdminReclamationScreen({super.key});

  @override
  State<AdminReclamationScreen> createState() => _AdminReclamationScreenState();
}

class _AdminReclamationScreenState extends State<AdminReclamationScreen> {
  List<Reclamation> _reclamations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchAllReclamations();
  }

  Future<void> fetchAllReclamations() async {
    final url = Uri.parse("http://192.168.1.18:5274/api/reclamation"); // 🟢 Endpoint pour TOUTES les réclamations

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _reclamations = jsonData
              .map((e) => Reclamation.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        throw Exception("Erreur lors du chargement : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réclamations - Admin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reclamations.isEmpty
              ? const Center(child: Text("Aucune réclamation trouvée."))
              : ListView.builder(
                  itemCount: _reclamations.length,
                  itemBuilder: (context, index) {
                    final rec = _reclamations[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("Client : ${rec.client}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date : ${DateFormat('dd/MM/yyyy HH:mm').format(rec.dateReclamation)}"),
                            Text("Téléphone : ${rec.telephone}"),
                            Text("Motifs : ${rec.retourLivraison}"),
                            Text("Note : ${rec.note}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

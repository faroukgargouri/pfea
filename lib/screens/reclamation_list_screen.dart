import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../models/reclamation.dart';

class ReclamationListScreen extends StatefulWidget {
  final int userId;

  const ReclamationListScreen({super.key, required this.userId});

  @override
  State<ReclamationListScreen> createState() => _ReclamationListScreenState();
}

class _ReclamationListScreenState extends State<ReclamationListScreen> {
  List<Reclamation> _reclamations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchReclamations();
  }

  Future<void> fetchReclamations() async {
    final url = Uri.parse("http://192.168.100.105:5274/api/reclamation/user/${widget.userId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _reclamations = jsonData.map((e) => Reclamation.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        throw Exception("Erreur HTTP : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liste des Réclamations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reclamations.isEmpty
              ? const Center(child: Text("Aucune réclamation trouvée."))
              : ListView.builder(
                  itemCount: _reclamations.length,
                  itemBuilder: (context, index) {
                    final rec = _reclamations[index];
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(rec.dateReclamation);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🧾 Client : ${rec.client}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("📅 Date : $formattedDate"),
                            Text("📞 Téléphone : ${rec.telephone}"),
                            Text("📌 Motifs : ${rec.retourLivraison}"),
                            Text("📝 Note : ${rec.note}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

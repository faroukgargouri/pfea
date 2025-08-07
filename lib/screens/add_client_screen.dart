import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final codeCtrl = TextEditingController();
  final raisonCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final villeCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> _saveClient() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    final url = Uri.parse('http://192.168.100.105:5274/api/client');

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "codeClient": codeCtrl.text.trim(),
          "raisonSociale": raisonCtrl.text.trim(),
          "telephone": telCtrl.text.trim(),
          "ville": villeCtrl.text.trim(),
          "userId": userId,
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Client ajouté avec succès")),
        );
        Navigator.pop(context, true); // ✅ Retour avec succès
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? "Erreur inconnue");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError("Erreur de connexion : $e");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un client")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code client")),
            const SizedBox(height: 12),
            TextField(controller: raisonCtrl, decoration: const InputDecoration(labelText: "Raison sociale")),
            const SizedBox(height: 12),
            TextField(controller: telCtrl, decoration: const InputDecoration(labelText: "Téléphone")),
            const SizedBox(height: 12),
            TextField(controller: villeCtrl, decoration: const InputDecoration(labelText: "Ville")),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _saveClient,
              icon: const Icon(Icons.add),
              label: isLoading ? const CircularProgressIndicator() : const Text("Ajouter"),
            )
          ],
        ),
      ),
    );
  }
}

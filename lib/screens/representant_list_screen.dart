import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Client {
  final int id;
  final String codeClient;
  final String raisonSociale;
  final String telephone;
  final String ville;

  Client({
    required this.id,
    required this.codeClient,
    required this.raisonSociale,
    required this.telephone,
    required this.ville,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      codeClient: json['codeClient'],
      raisonSociale: json['raisonSociale'],
      telephone: json['telephone'],
      ville: json['ville'],
    );
  }
}

class Representant {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String codeSage;
  final String role;
  final List<Client> clients;

  Representant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.codeSage,
    required this.role,
    required this.clients,
  });

  factory Representant.fromJson(Map<String, dynamic> json) {
    return Representant(
      id: json['representantId'] ?? 0,
      firstName: (json['representant'] as String).split(" ").first,
      lastName: (json['representant'] as String).split(" ").last,
      email: json['email'] ?? '',
      codeSage: json['codeSage'] ?? '',
      role: json['role'] ?? 'Représentant',
      clients: (json['clients'] as List<dynamic>? ?? [])
          .map((c) => Client.fromJson(c))
          .toList(),
    );
  }
}

class RepresentantListScreen extends StatefulWidget {
  const RepresentantListScreen({super.key});

  @override
  State<RepresentantListScreen> createState() => _RepresentantListScreenState();
}

class _RepresentantListScreenState extends State<RepresentantListScreen> {
  List<Representant> representants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRepresentants();
  }

  Future<void> fetchRepresentants() async {
    setState(() => isLoading = true);
    final response = await http.get(
      Uri.parse('http://192.168.1.18:5274/api/representant/by-representant'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        representants =
            data.map((json) => Representant.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de chargement des représentants")),
      );
    }
  }

  Future<bool> addRepresentant(String firstName, String lastName, String email,
      String password, String codeSage) async {
    final url =
        Uri.parse('http://192.168.1.18:5274/api/auth/register'); // 🔗 à adapter
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'codeSage': codeSage,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  void showAddDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final codeSageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un représentant"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: "Prénom")),
              TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(labelText: "Nom")),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email")),
              TextField(
                  controller: passwordCtrl,
                  decoration:
                      const InputDecoration(labelText: "Mot de passe"),
                  obscureText: true),
              TextField(
                  controller: codeSageCtrl,
                  decoration: const InputDecoration(labelText: "Code Sage")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await addRepresentant(
                firstNameCtrl.text,
                lastNameCtrl.text,
                emailCtrl.text,
                passwordCtrl.text,
                codeSageCtrl.text,
              );
              if (success) {
                Navigator.pop(context);
                fetchRepresentants();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Représentant ajouté avec succès")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erreur lors de l'ajout")),
                );
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Liste des représentants"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ajouter un représentant",
            onPressed: showAddDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: representants.length,
              itemBuilder: (context, index) {
                final rep = representants[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.person),
                    title: Text("${rep.firstName} ${rep.lastName}"),
                    subtitle: Text(rep.email),
                    children: rep.clients.map((client) {
                      return ListTile(
                        title: Text(client.raisonSociale),
                        subtitle:
                            Text("📞 ${client.telephone} • ${client.ville}"),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}

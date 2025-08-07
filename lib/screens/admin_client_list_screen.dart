import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminClientListScreen extends StatefulWidget {
  const AdminClientListScreen({super.key});

  @override
  State<AdminClientListScreen> createState() => _AdminClientListScreenState();
}

class _AdminClientListScreenState extends State<AdminClientListScreen> {
  List<Map<String, dynamic>> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final result = await ApiService.getClientsGroupedByRepresentant();
      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur chargement clients")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clients par Représentant"), backgroundColor: Colors.indigo),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final rep = data[index];
                final clients = List<Map<String, dynamic>>.from(rep['Clients']);
                return ExpansionTile(
                  title: Text(rep['Representant']),
                  subtitle: Text("${clients.length} client(s)"),
                  children: clients.map((client) {
                    return ListTile(
                      title: Text(client['raisonSociale']),
                      subtitle: Text("📞 ${client['telephone']} - ${client['ville']}"),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

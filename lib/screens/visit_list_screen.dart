import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visite.dart';
import '../services/api_service.dart';
import 'edit_visit_screen.dart'; // ✅ Assure-toi d’avoir cette page

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  Future<List<Visite>>? _visitesFuture;

  @override
  void initState() {
    super.initState();
    _loadVisites();
  }

  Future<void> _loadVisites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    setState(() {
      _visitesFuture = ApiService.getVisitesByUser(userId);
    });
  }

  Future<void> _deleteVisite(int id) async {
    try {
      await ApiService.deleteVisite(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visite supprimée.")),
      );
      _loadVisites(); // recharger
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur suppression : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Visites"),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<Visite>>(
        future: _visitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune visite trouvée."));
          }

          final visites = snapshot.data!;
          return ListView.builder(
            itemCount: visites.length,
            itemBuilder: (context, index) {
              final visite = visites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("${visite.raisonSociale} (${visite.codeClient})"),
                  subtitle: Text("📅 ${visite.dateVisite}\n📝 ${visite.compteRendu}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditVisitScreen(visite: visite)),
                          );
                          if (result == true) _loadVisites();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, visite.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer suppression"),
        content: const Text("Voulez-vous vraiment supprimer cette visite ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVisite(id);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

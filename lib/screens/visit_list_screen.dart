import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/visite.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart'; // ✅ TrikiAppBar

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  Future<List<Visite>>? _visitesFuture;

  String? _fullName;
  String? _codeSage;

  @override
  void initState() {
    super.initState();
    _loadHeaderUser();
    _loadVisites();
  }

  Future<void> _loadHeaderUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName');
      _codeSage = prefs.getString('codeSage');
    });
  }

  Future<void> _loadVisites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    setState(() {
      _visitesFuture = ApiService.getVisitesByUser(userId);
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
      // ✅ TrikiAppBar à la place de AppBar classique
      appBar: TrikiAppBar(
        fullName: _fullName,
        codeSage: _codeSage,
        blueNavItems: const [
          BlueNavItem(
            label: 'MES VISITES',
            selected: true,
          ),
        ],
        blueNavVariant: BlueNavbarVariant.textOnly,
      ),
      body: FutureBuilder<List<Visite>>(
        future: _visitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("❌ Erreur : ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune visite trouvée."));
          }

          final visites = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadVisites,
            child: ListView.builder(
              itemCount: visites.length,
              itemBuilder: (context, index) {
                final v = visites[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.event_note, color: Colors.indigo),
                    title: Text(v.raisonSociale,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date :  ${_formatDate(v.dateVisite)}"),
                        Text("Code Client : ${v.codeClient}"),
                        if (v.compteRendu!.isNotEmpty)
                          Text("CR : ${v.compteRendu}"),
                      ],
                    ),
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

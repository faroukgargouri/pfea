import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminClientListScreen extends StatefulWidget {
  const AdminClientListScreen({super.key});

  @override
  State<AdminClientListScreen> createState() => _AdminClientListScreenState();
}

// --- Models for the Sage-shaped response ------------------------------------
class SageClient {
  final String codeClient;
  final String raisonSociale;
  final String? telephone;
  final String? ville;

  SageClient({
    required this.codeClient,
    required this.raisonSociale,
    this.telephone,
    this.ville,
  });

  factory SageClient.fromJson(Map<String, dynamic> json) => SageClient(
        codeClient: (json['codeClient'] ?? '').toString(),
        raisonSociale: (json['raisonSociale'] ?? '').toString(),
        telephone: json['telephone']?.toString(),
        ville: json['ville']?.toString(),
      );
}

class SageRepresentant {
  final String codeSage;
  final String nomComplet;
  final String? email;
  final List<SageClient> clients;

  SageRepresentant({
    required this.codeSage,
    required this.nomComplet,
    this.email,
    required this.clients,
  });

  factory SageRepresentant.fromJson(Map<String, dynamic> json) => SageRepresentant(
        codeSage: (json['codeSage'] ?? '').toString(),
        nomComplet: (json['nomComplet'] ?? '').toString(),
        email: json['email']?.toString(),
        clients: (json['clients'] as List<dynamic>? ?? [])
            .map((c) => SageClient.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

// --- Screen ------------------------------------------------------------------
class _AdminClientListScreenState extends State<AdminClientListScreen> {
  bool _loading = true;
  List<SageRepresentant> _reps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Back-compat alias -> hits /representant/with-clients on the API
      final raw = await ApiService.getClientsGroupedByRepresentant();
      if (!mounted) return;
      setState(() {
        _reps = raw
            .map((e) => SageRepresentant.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement (Sage): $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Clients par représentant (Sage)'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reps.isEmpty
              ? const Center(child: Text('Aucun représentant.'))
              : ListView.separated(
                  itemCount: _reps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) {
                    final r = _reps[i];
                    return Card(
                      child: ExpansionTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        leading: const Icon(Icons.person_outline),
                        title: Text(r.nomComplet, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          (r.email?.isNotEmpty == true ? r.email! : '—') +
                              '  •  Code Sage: ${r.codeSage}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: r.clients.isEmpty
                            ? const [
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Aucun client.'),
                                ),
                              ]
                            : r.clients
                                .map(
                                  (c) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.business_outlined),
                                    title: Text(c.raisonSociale),
                                    subtitle: Text(
                                      'Code: ${c.codeClient}'
                                      '${(c.telephone != null && c.telephone!.isNotEmpty) ? " • 📞 ${c.telephone}" : ""}'
                                      '${(c.ville != null && c.ville!.isNotEmpty) ? " • ${c.ville}" : ""}',
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      id: (json['id'] ?? 0) as int,
      codeClient: (json['codeClient'] ?? '') as String,
      raisonSociale: (json['raisonSociale'] ?? '') as String,
      telephone: (json['telephone'] ?? '') as String,
      ville: (json['ville'] ?? '') as String,
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
    // API: representantId, representant: "First Last", email, codeSage, role, clients:[]
    final full = (json['representant'] as String? ?? '').trim();
    final parts = full.split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return Representant(
      id: (json['representantId'] ?? 0) as int,
      firstName: first,
      lastName: last,
      email: (json['email'] ?? '') as String,
      codeSage: (json['codeSage'] ?? '') as String,
      role: (json['role'] ?? 'Représentant') as String,
      clients: (json['clients'] as List<dynamic>? ?? [])
          .map((c) => Client.fromJson(c as Map<String, dynamic>))
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
  List<Representant> _representants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRepresentants();
  }

  Future<void> _fetchRepresentants() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getRepresentantsByAggregated();
      if (!mounted) return;
      setState(() {
        _representants = raw.map((e) => Representant.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement représentants: $e')),
      );
    }
  }

  void _showAddDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final codeSageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un représentant'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
              TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
              TextField(controller: codeSageCtrl, decoration: const InputDecoration(labelText: 'Code Sage')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final ok = await ApiService.registerRepresentant(
                firstNameCtrl.text.trim(),
                lastNameCtrl.text.trim(),
                emailCtrl.text.trim(),
                passwordCtrl.text.trim(),
                codeSageCtrl.text.trim(),
              );
              if (!mounted) return;
              if (ok) {
                Navigator.pop(context);
                await _fetchRepresentants();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Représentant ajouté.')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de l'ajout")));
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _editRep(Representant r) async {
    final first = TextEditingController(text: r.firstName);
    final last = TextEditingController(text: r.lastName);
    final email = TextEditingController(text: r.email);
    final codeSage = TextEditingController(text: r.codeSage);
    String role = r.role.toLowerCase().contains('admin') ? 'admin' : 'representant';

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Modifier le représentant'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: first, decoration: const InputDecoration(labelText: 'Prénom')),
                  TextField(controller: last, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: codeSage, decoration: const InputDecoration(labelText: 'Code Sage')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'representant', child: Text('Représentant')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => role = v ?? role,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer')),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final normalizedRole = (role == 'admin') ? 'Admin' : 'Représentant';

    final result = await ApiService.updateRepresentant(
      r.id,
      firstName: first.text.trim(),
      lastName: last.text.trim(),
      email: email.text.trim(),
      codeSage: codeSage.text.trim(),
      role: normalizedRole,
    );

    if (!mounted) return;

    if (result['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mis à jour.')));
      _fetchRepresentants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec mise à jour (HTTP ${result['status']}): ${result['body']}')),
      );
    }
  }

  Future<void> _deleteRep(Representant r) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer ?'),
            content: Text('Supprimer ${r.firstName} ${r.lastName} ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final ok = await ApiService.deleteRepresentant(r.id);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supprimé.')));
      _fetchRepresentants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec suppression.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Liste des représentants'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un représentant',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _representants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final r = _representants[i];
                return Card(
                  child: ExpansionTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    leading: const Icon(Icons.person),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Modifier',
                          icon: const Icon(Icons.edit),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () => _editRep(r),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () => _deleteRep(r),
                        ),
                      ],
                    ),
                    title: Text(
                      '${r.firstName} ${r.lastName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      r.email.isNotEmpty
                          ? r.email
                          : (r.codeSage.isNotEmpty ? 'Code Sage: ${r.codeSage}' : '—'),
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
                                leading: const Icon(Icons.account_circle_outlined),
                                title: Text(c.raisonSociale),
                                subtitle: Text('📞 ${c.telephone} • ${c.ville}'),
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

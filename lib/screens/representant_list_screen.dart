import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/representant.dart';
import '../services/api_service.dart';

class RepresentantListScreen extends StatefulWidget {
  const RepresentantListScreen({super.key});

  @override
  State<RepresentantListScreen> createState() => _RepresentantListScreenState();
}

class _RepresentantListScreenState extends State<RepresentantListScreen> {
  late Future<List<Representant>> _futureReps;
  List<Representant> _allReps = [];
  List<Representant> _filteredReps = [];
  final Map<String, List<Client>> _clientsCache = {};
  final Map<String, bool> _loadingCache = {};
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureReps = _loadReps();
  }

  Future<List<Representant>> _loadReps() async {
    final reps = await ApiService.getLocalRepresentants();
    setState(() {
      _allReps = reps;
      _filteredReps = reps;
    });
    return reps;
  }

  void _filter(String q) {
    final x = q.trim().toLowerCase();
    setState(() {
      _filteredReps = _allReps.where((r) {
        return r.fullName.toLowerCase().contains(x) ||
            r.codeSage.toLowerCase().contains(x);
      }).toList();
    });
  }

  Future<void> _loadClientsForRep(String codeSage) async {
    if (_clientsCache.containsKey(codeSage)) return;
    setState(() {
      _loadingCache[codeSage] = true;
    });

    try {
      final clients = await ApiService.getClientsByUser(codeSage);
      setState(() {
        _clientsCache[codeSage] = clients;
        _loadingCache[codeSage] = false;
      });
    } catch (e) {
      setState(() {
        _clientsCache[codeSage] = [];
        _loadingCache[codeSage] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur chargement clients: $e")),
        );
      }
    }
  }

  /// ✅ Vérification Email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// ➕ Ajout
 Future<void> _addRepresentant() async {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final siteCtrl = TextEditingController();
  String? selectedCodeSage;
  List<Representant> repsSage = [];

  try {
    repsSage = await ApiService.getSageRepresentants();
    final usedCodes = _allReps.map((r) => r.codeSage).toSet();
    repsSage = repsSage.where((r) => !usedCodes.contains(r.codeSage)).toList();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement codes Sage: $e")),
      );
    }
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text("Ajouter un représentant"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCodeSage,
                  hint: const Text("Sélectionner un Code Sage"),
                  isExpanded: true,
                  items: repsSage.map((rep) {
                    return DropdownMenuItem<String>(
                      value: rep.codeSage,
                      child: Text(rep.codeSage),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedCodeSage = val;
                      final rep = repsSage.firstWhere((r) => r.codeSage == val);
                      nameCtrl.text = rep.fullName;
                    });
                  },
                  validator: (val) =>
                      val == null ? "Veuillez sélectionner un Code Sage" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nom complet"),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Nom requis" : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Email requis";
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return "Email invalide";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: "Mot de passe"),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Mot de passe requis" : null,
                ),
                TextFormField(
                  controller: siteCtrl,
                  decoration: const InputDecoration(labelText: "Site"),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Site requis" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    ),
  );

  if (ok == true && selectedCodeSage != null) {
    final newRep = {
      "fullName": nameCtrl.text.trim(),
      "codeSage": selectedCodeSage!,
      "email": emailCtrl.text.trim(),
      "password": passCtrl.text.trim(),
      "site": siteCtrl.text.trim(),
      "role": "Representant"
    };

    try {
      final rep = await ApiService.addRepresentant(newRep);
      if (rep != null) {
        await _loadReps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Représentant ajouté avec succès !")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur ajout: $e")),
        );
      }
    }
  }
}

  /// ✏️ Edition
 Future<void> _editRepresentant(Representant r) async {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: r.fullName);
  final emailCtrl = TextEditingController(text: r.email);
  final passCtrl = TextEditingController(text: r.password ?? "");
  final siteCtrl = TextEditingController(text: r.site);

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Modifier représentant"),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: TextEditingController(text: r.codeSage),
                enabled: false,
                decoration: const InputDecoration(labelText: "Code Sage"),
              ),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nom complet"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Nom requis" : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email requis";
                  }
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return "Email invalide";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: "Mot de passe"),
                obscureText: true,
              ),
              TextFormField(
                controller: siteCtrl,
                decoration: const InputDecoration(labelText: "Site"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Site requis" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(ctx, true);
            }
          },
          child: const Text("Enregistrer"),
        ),
      ],
    ),
  );

  if (ok == true) {
    try {
      await ApiService.updateRepresentant(
        codeSage: r.codeSage,
        fullName: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim().isEmpty ? null : passCtrl.text.trim(),
        site: siteCtrl.text.trim(),
      );

      await _loadReps();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Représentant modifié avec succès")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur modification: $e")),
        );
      }
    }
  }
}


  /// 🗑️ Suppression
  Future<void> _deleteRepresentant(Representant r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Supprimer ${r.fullName} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteRepresentant(r.id);
        await _loadReps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Représentant supprimé")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur suppression: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: "Rechercher...",
                  border: InputBorder.none,
                ),
              )
            : const Text("Représentants"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _filteredReps = _allReps;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addRepresentant,
          ),
        ],
      ),
      body: FutureBuilder<List<Representant>>(
        future: _futureReps,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _allReps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }

          if (_filteredReps.isEmpty) {
            return const Center(child: Text("Aucun représentant trouvé."));
          }

          return ListView.builder(
            itemCount: _filteredReps.length,
            itemBuilder: (ctx, i) {
              final r = _filteredReps[i];
              final clients = _clientsCache[r.codeSage] ?? [];
              final isLoading = _loadingCache[r.codeSage] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    r.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Code Sage: ${r.codeSage}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editRepresentant(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRepresentant(r),
                      ),
                    ],
                  ),
                  onExpansionChanged: (expanded) {
                    if (expanded && !_clientsCache.containsKey(r.codeSage)) {
                      _loadClientsForRep(r.codeSage);
                    }
                  },
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (clients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Aucun client trouvé."),
                      )
                    else
                      ...clients.map(
                        (c) => ListTile(
                          leading: const Icon(Icons.business,
                              color: Colors.grey),
                          title: Text(c.bpcnam),
                          subtitle: Text(
                            "Code: ${c.bpcnum} "
                            "${c.tel.isNotEmpty ? '• 📞 ${c.tel}' : ''} "
                            "${c.gouvernerat.isNotEmpty ? '• ${c.gouvernerat}' : ''}",
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/visite.dart';
import '../services/api_service.dart';

class EditVisitScreen extends StatefulWidget {
  final Visite visite;
  const EditVisitScreen({super.key, required this.visite});

  @override
  State<EditVisitScreen> createState() => _EditVisitScreenState();
}

class _EditVisitScreenState extends State<EditVisitScreen> {
  late TextEditingController _dateCtrl;
  late TextEditingController _codeClientCtrl;
  late TextEditingController _raisonCtrl;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(text: widget.visite.dateVisite);
    _codeClientCtrl = TextEditingController(text: widget.visite.codeClient);
    _raisonCtrl = TextEditingController(text: widget.visite.raisonSociale);
    _noteCtrl = TextEditingController(text: widget.visite.compteRendu);
  }

  Future<void> _updateVisite() async {
    final updated = widget.visite.copyWith(
      dateVisite: _dateCtrl.text.trim(),
      codeClient: _codeClientCtrl.text.trim(),
      raisonSociale: _raisonCtrl.text.trim(),
      compteRendu: _noteCtrl.text.trim(),
    );

    try {
      await ApiService.updateVisite(widget.visite.id!, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visite modifiée avec succès.")),
      );
      Navigator.pop(context, true); // retourne au précédent avec succès
    } catch (e) {
      _showError("Erreur : $e");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier Visite"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _dateCtrl, decoration: const InputDecoration(labelText: "Date")),
              const SizedBox(height: 12),
              TextField(controller: _codeClientCtrl, decoration: const InputDecoration(labelText: "Code client")),
              const SizedBox(height: 12),
              TextField(controller: _raisonCtrl, decoration: const InputDecoration(labelText: "Raison sociale")),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Compte rendu"),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _updateVisite,
                icon: const Icon(Icons.save),
                label: const Text("Enregistrer les modifications"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

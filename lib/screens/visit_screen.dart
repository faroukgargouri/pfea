import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'representant_home_page.dart';
import '../widgets/custom_navbar.dart';
import '../data/api_config.dart'; // ✅ utilise apiRoot

class VisitScreen extends StatefulWidget {
  final String codeClient;
  final String raisonSociale;
  final String? codeSage;
  final String? fullName;
  final String telephone;

  const VisitScreen({
    super.key,
    required this.codeClient,
    required this.raisonSociale,
    required this.telephone,
    this.codeSage,
    this.fullName,
  });

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  static const _brandBlue = Color(0xFF0D47A1);
  static const _bg = Color(0xFFF6F7FB);

  final TextEditingController _noteController = TextEditingController();
  String? _noteError; 
  int? userId;

  // header infos
  String? _fullName;
  String? _codeSage;

  // infos visite après POST
  String? codeVisite;
  String? dateVisite;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadHeaderFromPrefs();
  }

  Future<void> _loadHeaderFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _fullName = widget.fullName ?? sp.getString('fullName');
      _codeSage = widget.codeSage ?? sp.getString('codeSage');
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<bool> _isOnline() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getInt('userId'));
    debugPrint("👤 UserId chargé: $userId");
  }

  Future<void> _saveVisit() async {
    debugPrint("🟢 Bouton Sauvegarder cliqué");

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : utilisateur non identifié.")),
      );
      return;
    }

    // ✅ Vérification obligatoire
    if (_noteController.text.trim().isEmpty) {
      setState(() {
        _noteError = "Le compte rendu est obligatoire.";
      });
      return;
    } else {
      setState(() {
        _noteError = null;
      });
    }

    final bodyMap = {
      "codeClient": widget.codeClient,
      "raisonSociale": widget.raisonSociale,
      "compteRendu": _noteController.text.trim(),
      "userId": userId,
    };

    debugPrint("➡️ Envoi visite: $bodyMap");

    if (await _isOnline()) {
      final url = Uri.parse('$apiRoot/visite'); 
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );

      debugPrint("⬅️ Réponse: ${response.statusCode} - ${response.body}");

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);

        setState(() {
          codeVisite = json['codeVisite'];
          dateVisite = json['dateVisite'] != null
              ? DateFormat('dd/MM/yyyy HH:mm')
                  .format(DateTime.parse(json['dateVisite']))
              : null;
        });

        // ✅ cache visite
        final cache = await Hive.openBox('visits_cache');
        final list = (cache.get('saved') as List?) ?? [];
        list.add(bodyMap);
        await cache.put('saved', list);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Visite enregistrée (${json['codeVisite']}).")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur serveur : ${response.statusCode}")),
        );
      }
    } else {
      // hors ligne → mettre en attente
      final pending = await Hive.openBox('visits_pending');
      final list = (pending.get('queue') as List?) ?? [];
      list.add(bodyMap);
      await pending.put('queue', list);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📴 Hors ligne : visite mise en attente.")),
      );
    }
  }

  void _onTopNavTap(String label) {
    switch (label) {
      case 'CHOIX CLIENT':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RepresentantHomePage()),
          (r) => false,
        );
        break;
    }
  }

  Widget _secondToolbar() {
    return Material(
      color: _brandBlue,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _Tab('CHOIX CLIENT', () => _onTopNavTap('CHOIX CLIENT')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrikiAppBar(fullName: _fullName, codeSage: _codeSage),
            _secondToolbar(),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _visitForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitForm() {
    InputDecoration _dec(String label, {int lines = 1, String? errorText}) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: lines > 1 ? 12 : 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        errorText: errorText,
      );
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (codeVisite != null)
              Text("Code visite : $codeVisite",
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800)),
            if (dateVisite != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("Date : $dateVisite",
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 10),

            // ✅ Infos client (affichage en lecture seule)
            Text("Code client : ${widget.codeClient}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text("Raison sociale : ${widget.raisonSociale}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            // ✅ Compte rendu
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: _dec('Compte rendu', lines: 3, errorText: _noteError),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _saveVisit,
                icon: const Icon(Icons.save, size: 18),
                label: const Text("Sauvegarder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandBlue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Tab(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

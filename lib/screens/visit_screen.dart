import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'representant_home_page.dart';

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

  late TextEditingController _dateController;
  final TextEditingController _noteController = TextEditingController();
  late String codeVisite;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _dateController =
        TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final code =
        (widget.codeSage ?? 'XXX').padRight(3, 'X').substring(0, 3).toUpperCase();
    final dateCode = DateFormat('ddMMyy').format(DateTime.now());
    codeVisite = "$code$dateCode";
  }

  @override
  void dispose() {
    _dateController.dispose();
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
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> _saveVisit() async {
    final bodyMap = {
      "codeVisite": codeVisite,
      "dateVisite": _dateController.text.trim(),
      "codeClient": widget.codeClient,
      "raisonSociale": widget.raisonSociale,
      "compteRendu": _noteController.text.trim(),
      "userId": userId,
    };

    if (await _isOnline()) {
      // ONLINE: post + cache
      final url = Uri.parse('http://192.168.0.103:5274/api/visite');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save a copy locally (history)
        final cache = await Hive.openBox('visits_cache');
        final list = (cache.get('saved') as List?) ?? [];
        list.add(bodyMap);
        await cache.put('saved', list);

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Visite enregistrée.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur (${response.statusCode}).")),
        );
      }
    } else {
      // OFFLINE: queue to send later
      final pending = await Hive.openBox('visits_pending');
      final list = (pending.get('queue') as List?) ?? [];
      list.add(bodyMap);
      await pending.put('queue', list);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hors ligne : visite mise en attente.")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // Header like Client Detail, no back arrow
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/logo.png', height: 34),
            const Spacer(),
            if ((widget.fullName ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  widget.fullName!,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'CODE: ${widget.codeSage ?? ''}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),

      body: Column(
        children: [
          // Blue strip
          Container(
            color: _brandBlue,
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _Tab('CHOIX CLIENT', () => _onTopNavTap('CHOIX CLIENT')),
              ],
            ),
          ),

          // Content (form only)
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
    InputDecoration _dec(String label, {Widget? suffix, int lines = 1}) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: lines > 1 ? 12 : 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: suffix,
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
            Text(
              "Code visite : $codeVisite",
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: _dec('Date visite', suffix: const Icon(Icons.event)),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: widget.codeClient),
              readOnly: true,
              decoration: _dec('Code client'),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: widget.raisonSociale),
              readOnly: true,
              decoration: _dec('Raison sociale'),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: _dec('Compte rendu', lines: 3),
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
                  textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* small helpers */

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
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

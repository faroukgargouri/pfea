import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';

class AdminReclamationScreen extends StatefulWidget {
  const AdminReclamationScreen({super.key});

  @override
  State<AdminReclamationScreen> createState() => _AdminReclamationScreenState();
}

class _AdminReclamationScreenState extends State<AdminReclamationScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  Future<bool> _isOnline() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final box = await Hive.openBox('reclamations_cache');

    try {
      if (await _isOnline()) {
        final data = await ApiService.getAllReclamations(); // List<Map>
        await box.put('all', data);
        if (!mounted) return;
        setState(() {
          _items = data;
          _loading = false;
        });
      } else {
        final cached = (box.get('all') as List?) ?? [];
        final list = cached
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() {
          _items = list;
          _loading = false;
        });
        if (list.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hors ligne: aucune réclamation en cache.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement réclamations: $e')),
      );
    }
  }

  String _formatDate(Map<String, dynamic> m) {
    final raw = m['dateReclamation'] ?? m['DateReclamation'] ?? m['createdAt'] ?? m['date'];
    if (raw == null) return '';
    try {
      if (raw is String) {
        final dt = DateTime.tryParse(raw);
        return dt != null ? _fmt.format(dt) : raw;
      }
      if (raw is int) {
        return _fmt.format(DateTime.fromMillisecondsSinceEpoch(raw));
      }
      return raw.toString();
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Réclamations - Admin'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        _EmptyState(),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = _items[i];
                        final client = (r['clientName'] ?? r['client'] ?? 'Client').toString();
                        final phone = (r['telephone'] ?? r['phone'] ?? '').toString();
                        final motifs = (r['motifs'] ?? '').toString();
                        final note = (r['note'] ?? '').toString();

                        return Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client : $client',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('Date : ${_formatDate(r)}'),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Téléphone : $phone'),
                                ],
                                if (motifs.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Motifs : $motifs'),
                                ],
                                if (note.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Note : $note'),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text('Aucune réclamation',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Text(
          'Les réclamations apparaîtront ici dès qu’elles seront disponibles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

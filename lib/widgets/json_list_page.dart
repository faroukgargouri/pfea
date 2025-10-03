import 'package:flutter/material.dart';

typedef JsonListLoader = Future<List<Map<String, dynamic>>> Function();

class JsonListPage extends StatefulWidget {
  final String title;
  final JsonListLoader loader;
  final String Function(Map<String, dynamic>) titleBuilder;
  final String Function(Map<String, dynamic>)? subtitleBuilder;
  final String Function(Map<String, dynamic>)? trailingBuilder;
  final void Function(Map<String, dynamic>)? onTap;

  const JsonListPage({
    super.key,
    required this.title,
    required this.loader,
    required this.titleBuilder,
    this.subtitleBuilder,
    this.trailingBuilder,
    this.onTap,
  });

  @override
  State<JsonListPage> createState() => _JsonListPageState();
}

class _JsonListPageState extends State<JsonListPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() { super.initState(); _future = widget.loader(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Erreur : ${snap.error}'));
          final list = snap.data ?? const [];
          if (list.isEmpty) return const Center(child: Text('Aucune donnée'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = list[i];
              return ListTile(
                title: Text(widget.titleBuilder(m)),
                subtitle: widget.subtitleBuilder != null ? Text(widget.subtitleBuilder!(m)) : null,
                trailing: widget.trailingBuilder != null
                    ? Text(widget.trailingBuilder!(m),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold))
                    : null,
                onTap: widget.onTap != null ? () => widget.onTap!(m) : null,
              );
            },
          );
        },
      ),
    );
  }
}

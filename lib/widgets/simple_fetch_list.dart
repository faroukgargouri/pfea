import 'package:flutter/material.dart';

typedef Fetcher = Future<List<dynamic>> Function();

class SimpleFetchListPage extends StatefulWidget {
  final String title;
  final List<FormFieldSpec> fields; // inputs to build header form
  final Future<List<dynamic>> Function(Map<String, String>) fetch;
  final List<String> showKeys; // keys to render in list per row
  final String? emptyText;
  const SimpleFetchListPage({
    super.key,
    required this.title,
    required this.fields,
    required this.fetch,
    required this.showKeys,
    this.emptyText,
  });

  @override
  State<SimpleFetchListPage> createState() => _SimpleFetchListPageState();
}

class _SimpleFetchListPageState extends State<SimpleFetchListPage> {
  late final Map<String, TextEditingController> _ctls;
  Future<List<dynamic>>? _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctls = {for (final f in widget.fields) f.name: TextEditingController(text: f.initial ?? '')};
  }

  @override
  void dispose() {
    for (final c in _ctls.values) c.dispose();
    super.dispose();
  }

  void _search() {
    final params = {for (final e in _ctls.entries) e.key: e.value.text.trim()};
    setState(() {
      _error = null;
      _future = widget.fetch(params);
    });
  }

  Future<void> _refresh() async {
    if (_future == null) return;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                for (final f in widget.fields) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        controller: _ctls[f.name],
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          labelText: f.label,
                          hintText: f.hint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Rechercher'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MaterialBanner(
                content: Text(_error!),
                actions: [TextButton(onPressed: () => setState(() => _error = null), child: const Text('OK'))],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _future == null
                ? const _Idle()
                : FutureBuilder<List<dynamic>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return _ErrorView(message: snap.error.toString(), onRetry: _search);
                      }
                      final items = snap.data ?? const <dynamic>[];
                      if (items.isEmpty) return Center(child: Text(widget.emptyText ?? 'Aucun élément.'));
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                          itemBuilder: (context, i) {
                            final row = (items[i] as Map).map((k, v) => MapEntry('$k', v));
                            final title = widget.showKeys.isNotEmpty ? '${row[widget.showKeys.first] ?? ''}' : '$row';
                            final subtitle = widget.showKeys.skip(1).map((k) => '$k: ${row[k] ?? ''}').join(' • ');
                            return ListTile(title: Text(title), subtitle: subtitle.isEmpty ? null : Text(subtitle));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FormFieldSpec {
  final String name, label;
  final String? hint, initial;
  const FormFieldSpec(this.name, this.label, {this.hint, this.initial});
}

class _Idle extends StatelessWidget {
  const _Idle();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Renseignez les champs puis touchez Rechercher.'),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Erreur', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      ]),
    ),
  );
}

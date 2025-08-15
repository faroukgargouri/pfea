// lib/services/outbox.dart
import 'dart:convert';
import 'package:hive/hive.dart';

class Outbox {
  static Future<Box> _box() => Hive.openBox('outbox');

  static Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final b = await _box();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await b.put(id, jsonEncode({'type': type, 'payload': payload}));
  }

  static Future<List<Map<String, dynamic>>> all() async {
    final b = await _box();
    return b.keys.map<Map<String, dynamic>>((k) {
      return {'id': k as String, 'data': jsonDecode(b.get(k))};
    }).toList();
  }

  static Future<void> remove(String id) async {
    final b = await _box();
    await b.delete(id);
  }
}

// lib/services/local_cache.dart
import 'dart:convert';
import 'package:hive/hive.dart';

class LocalCache {
  static Future<Box> _box(String name) => Hive.openBox(name);

  static Future<void> saveList(String box, String key, List<Map<String, dynamic>> list) async {
    final b = await _box(box);
    await b.put(key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> readList(String box, String key) async {
    final b = await _box(box);
    final raw = b.get(key);
    if (raw is String) {
      final List data = jsonDecode(raw);
      return data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return [];
  }
}

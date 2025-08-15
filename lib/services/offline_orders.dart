// lib/services/offline_orders.dart
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineOrders {
  static const _kQueueKey = 'offline_orders_queue_v1';

  // ---- storage helpers ----
  static Future<List<Map<String, dynamic>>> _read() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kQueueKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is List) {
      return list
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(growable: true);
    }
    return [];
  }

  static Future<void> _write(List<Map<String, dynamic>> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kQueueKey, jsonEncode(list));
  }

  static String _genId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(1 << 31);
    return 'oo_${ts}_$r';
  }

  // ---- API utilisée par SyncService / ApiService ----

  /// Ajoute une commande offline.
  /// `userId` est **optionnel** (on le stocke si fourni).
  static Future<String> enqueue(Map<String, dynamic> payload, {int? userId}) async {
    final list = await _read();
    final id = _genId();
    list.add({
      'offlineId': id,
      'payload': payload,
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _write(list);
    return id;
  }

  /// Renvoie toute la file:
  /// [{offlineId, payload, userId, createdAt}, ...]
  static Future<List<Map<String, dynamic>>> pending() async {
    return await _read();
  }

  /// Supprime une entrée par offlineId.
  static Future<void> remove(String offlineId) async {
    final list = await _read();
    list.removeWhere((e) => e['offlineId'] == offlineId);
    await _write(list);
  }

  static Future<int> count() async => (await _read()).length;

  static Future<void> clear() async => _write([]);
  static Future<void> clearQueue() async => clear(); // alias
}

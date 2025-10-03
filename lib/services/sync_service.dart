import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'offline_cache.dart';
import 'offline_orders.dart';
import 'api_service.dart';

class SyncService {
  static Timer? _timer;

  /// Call this once in main.dart AFTER Hive boxes are opened
  static void start() {
    if (_timer != null) return; // évite plusieurs timers

    // Tentative immédiate au démarrage
    _syncPendingVisits();
    _syncPendingOrders();
    _syncPendingReclamations();

    // Ensuite toutes les 30 secondes
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _syncPendingVisits();
      await _syncPendingOrders();
      await _syncPendingReclamations();
    });
  }

  static Future<bool> _hasNet() async {
    final r = await Connectivity().checkConnectivity();
    if (r is List<ConnectivityResult>) {
      return r.any((e) => e != ConnectivityResult.none);
    } else if (r is ConnectivityResult) {
      return r != ConnectivityResult.none;
    }
    return false;
  }

  // -------------------- VISITS --------------------
  static Future<void> _syncPendingVisits() async {
    if (!await _hasNet()) return;

    final pending = OfflineCache.getPendingVisits(); // List<Map<String,dynamic>>
    if (pending.isEmpty) return;

    final List<Map<String, dynamic>> stillPending = [];
    for (final payload in pending) {
      final ok = await ApiService.tryPostVisit(payload);
      if (!ok) stillPending.add(payload);
    }

    if (stillPending.isEmpty) {
      await OfflineCache.clearPendingVisits();
    } else {
      final box = Hive.box('visits_pending');
      await box.put('pending', stillPending);
    }
  }

  // -------------------- ORDERS --------------------
  static Future<void> _syncPendingOrders() async {
    if (!await _hasNet()) return;

    final list = await OfflineOrders.pending(); // [{offlineId, payload, ...}]
    if (list.isEmpty) return;

    for (final entry in List<Map<String, dynamic>>.from(list)) {
      final String offlineId = entry['offlineId'] as String;
      final Map<String, dynamic> payload =
          Map<String, dynamic>.from(entry['payload'] as Map);

      final ok = await ApiService.tryPostOrder(payload);
      if (ok) {
        await OfflineOrders.remove(offlineId);
      }
      // sinon → on garde pour la prochaine tentative
    }
  }

  // -------------------- RECLAMATIONS --------------------
  static Future<void> _syncPendingReclamations() async {
    if (!await _hasNet()) return;

    final pending = OfflineCache.getPendingReclamations(); // List<Map<String,dynamic>>
    if (pending.isEmpty) return;

    final List<Map<String, dynamic>> stillPending = [];
    for (final payload in pending) {
      final ok = await ApiService.tryPostReclamation(payload);
      if (!ok) stillPending.add(payload);
    }

    if (stillPending.isEmpty) {
      await OfflineCache.clearPendingReclamations();
    } else {
      final box = Hive.box('reclamations_pending');
      await box.put('pending', stillPending);
    }
  }
}

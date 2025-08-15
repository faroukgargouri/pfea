import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'offline_cache.dart';
import 'api_service.dart';

class SyncService {
  static Timer? _timer;

  /// Call this once in main.dart AFTER Hive boxes are opened
  static void start() {
    if (_timer != null) return; // avoid duplicate timers
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _syncPendingVisits());
  }

  static Future<void> _syncPendingVisits() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return; // offline, skip

    final pending = OfflineCache.getPendingVisits(); // List<Map<String,dynamic>>
    if (pending.isEmpty) return;

    final List<Map<String, dynamic>> stillPending = [];

    for (final payload in pending) {
      final ok = await ApiService.tryPostVisit(payload);
      if (!ok) {
        stillPending.add(payload); // keep if failed
      }
    }

    if (stillPending.isEmpty) {
      await OfflineCache.clearPendingVisits();
    } else {
      final box = Hive.box('visits_pending');
      await box.put('pending', stillPending);
    }
  }
}

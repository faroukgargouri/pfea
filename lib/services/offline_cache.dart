import 'package:hive/hive.dart';

class OfflineCache {
  // ---------- Reclamations ----------
  static Future<void> saveReclamations(List<Map<String, dynamic>> list) async {
    final box = Hive.box('reclamations_cache');
    await box.put('data', list);
  }

  static List<Map<String, dynamic>> getReclamations() {
    final box = Hive.box('reclamations_cache');
    final raw = box.get('data', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Clients (per user) ----------
  static Future<void> saveClients(int userId, List<Map<String, dynamic>> list) async {
    final box = Hive.box('clients_cache');
    await box.put('clients_$userId', list);
  }

  static List<Map<String, dynamic>> getClients(int userId) {
    final box = Hive.box('clients_cache');
    final raw = box.get('clients_$userId', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Products (ADD THESE) ----------
  static Future<void> saveProducts(List<Map<String, dynamic>> list) async {
    final box = Hive.box('products_cache');
    await box.put('data', list);
  }

  static List<Map<String, dynamic>> getProducts() {
    final box = Hive.box('products_cache');
    final raw = box.get('data', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Visits (history) ----------
  static Future<void> saveVisits(List<Map<String, dynamic>> visits) async {
    final box = Hive.box('visits_cache');
    await box.put('data', visits);
  }

  static List<Map<String, dynamic>> getVisits() {
    final box = Hive.box('visits_cache');
    final raw = box.get('data', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Pending visits queue ----------
  static Future<void> queueVisit(Map<String, dynamic> visit) async {
    final box = Hive.box('visits_pending');
    final current = List<Map<String, dynamic>>.from(
      (box.get('pending', defaultValue: const []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    )..add(visit);
    await box.put('pending', current);
  }

  static List<Map<String, dynamic>> getPendingVisits() {
    final box = Hive.box('visits_pending');
    final raw = box.get('pending', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<void> clearPendingVisits() async {
    final box = Hive.box('visits_pending');
    await box.put('pending', const <Map<String, dynamic>>[]);
  }
}

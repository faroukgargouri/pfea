import 'package:hive/hive.dart';

class OfflineCache {
  // ---------- Reclamations (historique) ----------
  static Future<void> saveReclamations(List<Map<String, dynamic>> list) async {
    final box = await Hive.openBox('reclamations_cache');
    await box.put('data', list);
  }

  static List<Map<String, dynamic>> getReclamations() {
    final box = Hive.box('reclamations_cache');
    final raw = box.get('data', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Pending Reclamations (offline queue) ----------
  static Future<void> queueReclamation(Map<String, dynamic> reclam) async {
    final box = await Hive.openBox('reclamations_pending');
    final current = List<Map<String, dynamic>>.from(
      (box.get('pending', defaultValue: const []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    )..add(reclam);
    await box.put('pending', current);
  }

  static List<Map<String, dynamic>> getPendingReclamations() {
    final box = Hive.box('reclamations_pending');
    final raw = box.get('pending', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<void> clearPendingReclamations() async {
    final box = await Hive.openBox('reclamations_pending');
    await box.put('pending', const <Map<String, dynamic>>[]);
  }

  // ---------- Clients (per rep/codeSage) ----------
  static Future<void> saveClients(String codeSage, List<Map<String, dynamic>> list) async {
    final box = await Hive.openBox('clients_cache');
    await box.put('clients_$codeSage', list);
  }

  static List<Map<String, dynamic>> getClients(String codeSage) {
    final box = Hive.box('clients_cache');
    final raw = box.get('clients_$codeSage', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Products (catalogue global) ----------
  static Future<void> saveProducts(List<Map<String, dynamic>> list) async {
    final box = await Hive.openBox('products_cache');
    await box.put('data', list);
  }

  static List<Map<String, dynamic>> getProducts() {
    final box = Hive.box('products_cache');
    final raw = box.get('data', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Visits ----------
  static Future<void> saveVisits(List<Map<String, dynamic>> visits) async {
    final box = await Hive.openBox('visits_cache');
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
    final box = await Hive.openBox('visits_pending');
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
    final box = await Hive.openBox('visits_pending');
    await box.put('pending', const <Map<String, dynamic>>[]);
  }

  // ---------- Chiffre Affaire ----------
  static Future<void> saveChiffreAffaire(Map<String, dynamic> data) async {
    final box = await Hive.openBox('chiffre_affaire_cache');
    await box.put('chiffre_affaire_${data['codeclient']}', data);
  }

  static Future<Map<String, dynamic>?> getChiffreAffaire(String codeClient) async {
    final box = await Hive.openBox('chiffre_affaire_cache');
    return box.get('chiffre_affaire_$codeClient') as Map<String, dynamic>?;
  }

  // ---------- Préavis ----------
  static Future<void> savePreavis(Map<String, dynamic> data) async {
    final box = await Hive.openBox('preavis_cache');
    await box.put('preavis_${data['rep']}', data);
  }

  static Future<Map<String, dynamic>?> getPreavis(String rep) async {
    final box = await Hive.openBox('preavis_cache');
    return box.get('preavis_$rep') as Map<String, dynamic>?;
  }

  // ---------- Sales Items ----------
  static Future<void> saveSalesItems(String codeClient, List<dynamic> items) async {
    final box = await Hive.openBox('sales_items_cache');
    await box.put('sales_$codeClient', items);
  }

  static Future<List<Map<String, dynamic>>> getSalesItems(String codeClient) async {
    final box = await Hive.openBox('sales_items_cache');
    final raw = box.get('sales_$codeClient', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Factures ----------
  static Future<void> saveFactures(String codeClient, List<dynamic> factures) async {
    final box = await Hive.openBox('factures_cache');
    await box.put('factures_$codeClient', factures);
  }

  static Future<List<Map<String, dynamic>>> getFactures(String codeClient) async {
    final box = await Hive.openBox('factures_cache');
    final raw = box.get('factures_$codeClient', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Dernière Facture ----------
  static Future<void> saveDerniereFacture(String codeClient, List<dynamic> factures) async {
    final box = await Hive.openBox('derniere_facture_cache');
    await box.put('derniere_facture_$codeClient', factures);
  }

  static Future<List<Map<String, dynamic>>> getDerniereFacture(String codeClient) async {
    final box = await Hive.openBox('derniere_facture_cache');
    final raw = box.get('derniere_facture_$codeClient', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Chèques ----------
  static Future<void> saveCheques(String codeClient, String rep, List<dynamic> cheques) async {
    final box = await Hive.openBox('cheques_cache');
    await box.put('cheques_${codeClient}_$rep', cheques);
  }

  static Future<List<Map<String, dynamic>>> getCheques(String codeClient, String rep) async {
    final box = await Hive.openBox('cheques_cache');
    final raw = box.get('cheques_${codeClient}_$rep', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<void> saveListecheques(String rep, [List<dynamic>? cheques]) async {
    final box = await Hive.openBox('cheques_cache');
    if (cheques == null || cheques.isEmpty) {
      await box.delete('cheques_$rep');
      return;
    }
    await box.put('cheques_$rep', cheques);
  }

  static Future<List<Map<String, dynamic>>> getListecheques(String rep) async {
    final box = await Hive.openBox('cheques_cache');
    final raw = box.get('cheques_$rep', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Reliquats ----------
  static Future<void> saveReliquats(String codeClient, List<dynamic> reliquats) async {
    final box = await Hive.openBox('reliquats_cache');
    await box.put('reliquats_$codeClient', reliquats);
  }

  static Future<List<Map<String, dynamic>>> getReliquats(String codeClient) async {
    final box = await Hive.openBox('reliquats_cache');
    final raw = box.get('reliquats_$codeClient', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Cmd ----------
  static Future<void> saveCmd(String codeClient, List<dynamic> cmd) async {
    final box = await Hive.openBox('cmd_cache');
    await box.put('cmd_$codeClient', cmd);
  }

  static Future<List<Map<String, dynamic>>> getCmd(String codeClient) async {
    final box = await Hive.openBox('cmd_cache');
    final raw = box.get('cmd_$codeClient', defaultValue: const []);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ---------- Orders ----------
  static const String _boxName = 'orders_cache';

  static Future<void> saveOrder(Map<String, dynamic> order) async {
    final box = await Hive.openBox(_boxName);
    await box.add(order);
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final box = await Hive.openBox(_boxName);
    return List<Map<String, dynamic>>.from(
      box.values.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final orders = await getOrders();
    return orders.where((o) => o['isSynced'] == false).toList();
  }

  static Future<void> clearOrders() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}

// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/representant.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/api_config.dart'; 
import 'offline_cache.dart';
import 'auth_cache.dart';
import 'offline_orders.dart';

import '../models/order.dart';
import '../models/visite.dart';
import '../models/product.dart';
import '../models/client.dart';
import 'package:flutter_application_1/models/chiffre_affaire.dart';
import 'package:flutter_application_1/models/listefactures.dart';
import 'package:flutter_application_1/models/preavis.dart';
import 'package:flutter_application_1/models/referencement_client.dart';
import 'package:flutter_application_1/models/factures.dart';
import 'package:flutter_application_1/models/derniere_facture.dart';
import 'package:flutter_application_1/models/cheque.dart';
import 'package:flutter_application_1/models/reliquat.dart';
import 'package:flutter_application_1/models/cmd.dart';

class ApiService {
  // Base URL provided by api_config.dart (e.g., 'http://host:port/api')
  static String get _baseUrl => apiRoot;

  // JSON headers for POST/PUT requests
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------- HTTP helpers ----------------
  static Future<http.Response> _get(Uri url) => http.get(url, headers: {'Accept': 'application/json'});

  static Future<http.Response> _post(Uri url, Map<String, dynamic> body) =>
      http.post(url, headers: _jsonHeaders, body: jsonEncode(body));

  static Future<http.Response> _put(Uri url, Map<String, dynamic> body) =>
      http.put(url, headers: _jsonHeaders, body: jsonEncode(body));

  static Future<http.Response> _delete(Uri url) => http.delete(url, headers: {'Accept': 'application/json'});

  // ---------------- Connectivity helper ----------------
  // Supports connectivity_plus v5/v6 return types.
  static Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  // Lightweight API reachability check (requires GET /api/ping endpoint)
  static Future<bool> ping() async {
    try {
      final res = await _get(Uri.parse('$_baseUrl/ping'));
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  // Extract "message" from API responses when available
  static String? _extractMessage(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map && m['message'] != null) return m['message'].toString();
      return null;
    } catch (_) {
      return null;
    }
  }

// ========================================================================
  // ----------------------- ADMIN SECTION ---------------------------------
  // ========================================================================

  /// 📌 Réclamations (Admin)
  static Future<List<Map<String, dynamic>>> getAllAdminReclamations() async {
    final url = Uri.parse('$_baseUrl/admin/reclamations');
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur chargement réclamations admin');
  }

  /// 📌 Visites (Admin)
  static Future<List<Map<String, dynamic>>> getAllAdminVisites() async {
    final url = Uri.parse('$_baseUrl/admin/visites');
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur chargement visites admin');
  }

  /// 📌 Commandes (Admin)
 static Future<List<Map<String, dynamic>>> getAllAdminOrders() async {
  final url = Uri.parse('$_baseUrl/Admin/orders');
  final res = await _get(url);
  if (res.statusCode >= 200 && res.statusCode < 300) {
    final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);

    // Cache local Hive
    final box = await Hive.openBox('orders_cache');
    await box.put('all', list);

    return list;
  } else {
    throw Exception("Erreur récupération commandes: ${res.body}");
  }
}




  /// 📌 Produits (Admin)
  static Future<List<Product>> getAllAdminProducts() async {
    final url = Uri.parse('$_baseUrl/admin/product'); // ✅ corrigé
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List data = jsonDecode(res.body) as List;
      return data.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Erreur chargement produits admin');
  }


 static Future<void> updateProductImage(
  String itmref, Uint8List imageBytes, String fileName) async {
  
  // 🔹 On force l’extension .png
  if (!fileName.toLowerCase().endsWith(".png")) {
    fileName = "$itmref.png";
  }

  final uri = Uri.parse("$apiRoot/product/$itmref/image");

  print("📡 Upload image -> itmref: $itmref");
  print("📡 Upload image -> URL: $uri");
  print("📡 Upload image -> filename: $fileName");
  

  var request = http.MultipartRequest('POST', uri);

  request.fields['itmref'] = itmref;
  request.files.add(http.MultipartFile.fromBytes(
    'image',
    imageBytes,
    filename: fileName,
  ));

  final res = await request.send();
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception("Erreur upload image [${res.statusCode}]");
  }
}





  /// 📌 Ajouter un produit (Admin)
  static Future<bool> addAdminProduct(Product p) async {
    final url = Uri.parse('$_baseUrl/admin/product');
    final res = await _post(url, p.toJson());
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// 📌 Supprimer un produit (Admin)
  static Future<bool> deleteAdminProduct(int id) async {
    final url = Uri.parse('$_baseUrl/admin/product/$id');
    final res = await _delete(url);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  // 📌 Représentants (JSON simple: code_Sage + fullName)
static Future<List<Representant>> getRepresentants() async {
  final res = await _get(Uri.parse('$_baseUrl/Admin/repsage'));
  if (res.statusCode >= 200 && res.statusCode < 300) {
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => Representant.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur chargement représentants: ${res.statusCode}');
}

  static Future<List<Representant>> getLocalRepresentants() async {
  final res = await _get(Uri.parse('$_baseUrl/Admin/repslocal'));
  if (res.statusCode >= 200 && res.statusCode < 300) {
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => Representant.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur chargement représentants locaux');
}


  static Future<Representant?> addRepresentant(Map<String, dynamic> rep) async {
  // 🔹 utiliser l'endpoint de ton RepresentantController (base locale)
  final url = Uri.parse("$_baseUrl/Admin/representants");

  final res = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(rep),
  );

  if (res.statusCode >= 200 && res.statusCode < 300) {
    final data = jsonDecode(res.body);
    return Representant.fromJson(data as Map<String, dynamic>);
  } else {
    throw Exception("Erreur ajout représentant: ${res.body}");
  }
}

// lib/services/api_service.dart

static Future<bool> updateRepresentant({
  required String codeSage,
  required String fullName,
  required String email,
  required String site,
  String? password,
}) async {
  final url = Uri.parse("$_baseUrl/Admin/representants/$codeSage");

  final body = {
    "fullName": fullName,
    "email": email,
    "site": site,
    "codeSage": codeSage,
  };

  if (password != null && password.isNotEmpty) {
    body["password"] = password;
  }

  final res = await http.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  return res.statusCode >= 200 && res.statusCode < 300;
}



  static Future<bool> deleteAdminRepresentant(int id) async {
    final url = Uri.parse('$_baseUrl/admin/representants/$id');
    final res = await _delete(url);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// 📌 Dashboard stats (Admin)
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final url = Uri.parse('$_baseUrl/admin/stats'); // ✅ corrigé
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    throw Exception('Erreur chargement statistiques admin');
  }


  // ===========================================================================
  // AUTH (with offline fallback)
  // ===========================================================================
  static Future<Map<String, dynamic>> login(String codeSage, String password) async {
  final url = Uri.parse('$_baseUrl/auth/login');
  try {
    final response = await _post(url, {
      'codeSage': codeSage,   // ✅ plus de email
      'password': password,
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Persist identity for offline login
      try {
        await AuthCache.saveIdentity(
          email: codeSage, // ⚠️ ici tu peux renommer AuthCache pour stocker codeSage
          password: password,
          userJson: data,
        );
      } catch (_) {/* don't block */}
      return {'success': true, 'data': data};
    }

    final msg = _extractMessage(response.body) ?? 'Code Sage ou mot de passe invalide';
    return {'success': false, 'message': msg};
  } catch (e) {
    // Network issue -> try offline login
    final cached =
        await AuthCache.tryOfflineLogin(email: codeSage, password: password);
    if (cached != null) {
      return {'success': true, 'data': cached, 'offline': true};
    }
    return {'success': false, 'message': 'API injoignable: $e'};
  }
}


 static Future<bool> registerRepresentant(
  String firstName,
  String lastName,
  String password,
  String codeSage,
  String site, ) async {
  final url = Uri.parse('$_baseUrl/auth/register');
  try {
    final response = await _post(url, {
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
      'codeSage': codeSage,
      'site': site,
    });
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (_) {
    return false;
  }
}

  // ===========================================================================
  // RECLAMATIONS (cached for offline read)
  // ===========================================================================
 static Future<bool> addReclamation(Map<String, dynamic> data) async {
  final url = Uri.parse('$_baseUrl/reclamation');

  data.remove('reclamationNo');
  data.remove('dateReclamation');

  final response = await _post(url, data);
  return response.statusCode >= 200 && response.statusCode < 300;
}


  static Future<List<Map<String, dynamic>>> getReclamationsByUser(
      int userId) async {
    final url = Uri.parse('$_baseUrl/reclamation/user/$userId');
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur chargement des réclamations');
  }

  static Future<List<Map<String, dynamic>>> getAllReclamations() async {
    final url = Uri.parse('$_baseUrl/reclamation');
    try {
      final res = await _get(url);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list =
            List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
        await OfflineCache.saveReclamations(list);
        return list;
      }
      throw Exception('HTTP ${res.statusCode}');
    } catch (_) {
      // Offline fallback
      return OfflineCache.getReclamations();
    }
    
  }
static Future<bool> tryPostReclamation(Map<String, dynamic> payload) async {
  try {
    final url = Uri.parse("$apiRoot/reclamation");
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  } catch (e) {
    print("❌ Erreur sync réclamation offline: $e");
    return false;
  }
}

  // ===========================================================================
  // CLIENTS
  // ===========================================================================
 static Future<List<Client>> getClientsByUser(String userId) async {
  try {
    // 🔹 Test connexion d’abord
    final online = await _isOnline();

    if (online) {
      // ✅ Mode ONLINE → API + maj cache
      final url = Uri.parse('$_baseUrl/client/repsage/$userId');
      final response = await _get(url);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body) as List;

        final clients = data
            .map((json) => Client.fromJson(json as Map<String, dynamic>))
            .toList();

        // 🔹 Maj cache
        await OfflineCache.saveClients(
            userId, clients.map((c) => c.toJson()).toList());

        return clients;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } else {
      // ✅ Mode OFFLINE → lecture cache uniquement
      final cached = await OfflineCache.getClients(userId);
      return cached.map((j) => Client.fromJson(j)).toList();
    }
  } catch (e) {
    // 🔹 En cas d’erreur API → fallback cache
    final cached = await OfflineCache.getClients(userId);
    if (cached.isNotEmpty) {
      return cached.map((j) => Client.fromJson(j)).toList();
    }
    throw Exception("Impossible de charger les clients: $e");
  }
}


  static Future<List<Client>> getClientsByRepresentant(String codeSage) async {
    final safe = Uri.encodeComponent(codeSage.trim());
    final res =
        await _get(Uri.parse('$_baseUrl/client/by-representant/$safe'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List data = jsonDecode(res.body) as List;
      return data
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        'Erreur chargement clients par représentant (Sage): ${res.statusCode}');
  }


  static Future<List<Map<String, dynamic>>> getSageClientsByRepresentantRaw(
      String codeSage) async {
    final safe = Uri.encodeComponent(codeSage.trim());
    final res =
        await _get(Uri.parse('$_baseUrl/client/by-representant/$safe'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception(
        'Erreur chargement clients par représentant (Sage): ${res.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> searchSageClients(
      String term) async {
    final uri = Uri.parse('$_baseUrl/client/search')
        .replace(queryParameters: {'term': term});
    final res = await _get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur recherche clients (Sage): ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> getSageClient(
      String codeClient) async {
    final res = await _get(Uri.parse('$_baseUrl/client/$codeClient'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception('Erreur chargement client (Sage): ${res.statusCode}');
  }

  // ===========================================================================
  // REPRÉSENTANTS
  // ===========================================================================
  static Future<List<Representant>> getSageRepresentants() async {
  final url = Uri.parse('$_baseUrl/admin/repsage'); // ton endpoint Sage
  final res = await _get(url);
  if (res.statusCode == 200) {
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => Representant.fromJson(e)).toList();
  } else {
    throw Exception("Erreur API repsage");
  }
}


  static Future<List<Map<String, dynamic>>> getSageRepresentantsWithClients() async {
    final res = await _get(Uri.parse('$_baseUrl/Admin/repsage'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur chargement reps+clients (Sage): ${res.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getClientsOfRep(
      String codeSage) async {
    final safe = Uri.encodeComponent(codeSage.trim());
    final res =
        await _get(Uri.parse('$_baseUrl/representant/$safe/clients'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception(
        'Erreur chargement clients du représentant (Sage): ${res.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getClientsGroupedByRepresentant() =>
      getSageRepresentantsWithClients();

 static Future<void> deleteRepresentant(int id) async {
  final url = Uri.parse("$apiRoot/Admin/representants/$id");
  final res = await http.delete(url);

  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception("Erreur suppression: ${res.statusCode} ${res.body}");
  }
}


  // ===========================================================================
  // VISITES (queue offline, auto-sync later via SyncService)
  // ===========================================================================
   static Future<List<Visite>> getVisitesByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/visite/user/$userId');
    if (await _isOnline()) {
      final response = await _get(url);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body) as List;
        await OfflineCache.saveVisits(
            List<Map<String, dynamic>>.from(data)); // sauvegarde offline
        return data
            .map((json) => Visite.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Erreur chargement des visites');
      }
    } else {
      final cached = OfflineCache.getVisits();
      return cached.map((j) => Visite.fromJson(j)).toList();
    }
  }

  /// Ajouter une visite
  static Future<bool> addVisite(Visite visite) async {
    final payload = visite.toJson(); // ✅ ISO8601 via modèle
    if (!await _isOnline()) {
      await OfflineCache.queueVisit(payload);
      return true;
    }
    try {
      final url = Uri.parse('$_baseUrl/visite');
      final response = await _post(url, payload);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      // si échec -> stocker offline
      await OfflineCache.queueVisit(payload);
      return true;
    } catch (_) {
      await OfflineCache.queueVisit(payload);
      return true;
    }
  }

  /// Modifier une visite
  static Future<void> updateVisite(int id, Visite visite) async {
    final url = Uri.parse('$_baseUrl/visite/$id');
    final payload = visite.toJson(); // ✅ ISO8601 garanti
    final response = await _put(url, payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur mise à jour visite');
    }
  }

  /// Supprimer une visite
  static Future<void> deleteVisite(int id) async {
    final url = Uri.parse('$_baseUrl/visite/$id');
    final response = await _delete(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur suppression visite');
    }
  }

  /// Essayer de poster une visite (utilisé pour la synchro offline → online)
  static Future<bool> tryPostVisit(Map<String, dynamic> payload) async {
    try {
      // 🔍 Normaliser date avant envoi (si vient du cache)
      if (payload['dateVisite'] is DateTime) {
        payload['dateVisite'] =
            (payload['dateVisite'] as DateTime).toIso8601String();
      }
      final url = Uri.parse('$_baseUrl/visite');
      final res = await _post(url, payload);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // PRODUITS
  // ===========================================================================
  static Future<List<Product>> getProducts() async {
  try {
    final online = await _isOnline(); // ✅ test local (pas d’appel HTTP)
    if (online) {
      // ✅ Mode ONLINE → API + maj cache
      final url = Uri.parse('$_baseUrl/product/sage');
      final res = await _get(url);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final List list =
            decoded is List ? decoded : (decoded['data'] as List? ?? const []);

        final products = list
            .whereType<Map<String, dynamic>>()
            .map((m) => Product.fromJson(m))
            .toList();

        // 🔹 Mets à jour le cache local
        await OfflineCache.saveProducts(
            products.map((p) => p.toJson()).toList());

        return products;
      } else {
        throw Exception("Erreur API: ${res.statusCode}");
      }
    } else {
      // ✅ Mode OFFLINE → lecture cache uniquement
      final cached = await OfflineCache.getProducts();
      return cached.map((e) => Product.fromJson(e)).toList();
    }
  } catch (e) {
    // 🔹 En cas d’erreur réseau → fallback cache
    final cached = await OfflineCache.getProducts();
    if (cached.isNotEmpty) {
      return cached.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception("Impossible de charger les produits: $e");
  }
}

  static Future<void> addProduct(Product product) async {
    final url = Uri.parse('$_baseUrl/product');
    final response = await _post(url, product.toJson());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur ajout produit");
    }
  }

  static Future<void> deleteProduct(int id) async {
    final url = Uri.parse('$_baseUrl/product/$id');
    final response = await _delete(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur suppression produit");
    }
  }

  // ===========================================================================
  // COMMANDES (OFFLINE QUEUE + SYNC) — Aligned with new backend
  //   POST   /api/orders                (CreateOrderDto)
  //   GET    /api/orders/client/{id}
  //   GET    /api/orders/full
  // ===========================================================================

  static Future<http.Response> _postOrderOnline(Map<String, dynamic> order) {
    final url = Uri.parse('$_baseUrl/orders');
    return _post(url, order);
  }

  @deprecated
  static Future<List<Order>> getOrders(int userId) async {
    throw UnimplementedError(
        'Use getAllOrders() or getOrdersByClientId() instead.');
  }

  static Future<List<Order>> getOrdersByClientId(String clientId) async {
    final url = Uri.parse('$_baseUrl/orders/client/$clientId');
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List data = jsonDecode(res.body) as List;
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur chargement commandes: ${res.statusCode}');
  }

  /// Fetch Local + Sage orders.
  /// Pass [codeRep] to filter on server (faster & smaller payload).
  static Future<List<Order>> getAllOrders({String? codeRep}) async {
    final uri = Uri.parse('$_baseUrl/orders/full').replace(
      queryParameters: (codeRep != null && codeRep.trim().isNotEmpty)
          ? {'Code_Rep': codeRep.trim()}
          : null,
    );

    final response = await _get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception("Erreur lors du chargement des commandes");
    }
  }

  // ---- FIXED: Normalize items to backend contract (camelCase + totals) ----
  static List<Map<String, dynamic>> _normalizeOrderItemsCamel(
      List<Map<String, dynamic>> items) {
    return items.map((i) {
      final sku =
          (i['itmref'] ?? i['Itmref'] ?? i['sku'] ?? i['SKU'] ?? '').toString();
      final qty =
          ((i['quantity'] ?? i['Quantity'] ?? i['qty'] ?? 0) as num).toInt();
      final up =
          ((i['unitPrice'] ?? i['UnitPrice'] ?? i['price'] ?? 0) as num)
              .toDouble();
      final totalField = i['totalPrice'] ?? i['TotalPrice'];
      final total = (totalField is num) ? totalField.toDouble() : up * qty;
      return {
        'itmref': sku,
        'quantity': qty,
        'unitPrice': up,
        'totalPrice': total,
      };
    }).toList();
  }

  /// Create order aligned with CreateOrderDto in backend (camelCase, UTC).
  static Future<void> createOrder({
  required String clientId,
  required String nomClient,
  required String adresseClient,
  required String codeRep,
  required String nomRep,
  required String reference,
   String? note, // ✅ ajouté
  required List<Map<String, dynamic>> items,
  DateTime? createdAt,
  DateTime? dateLivraison,
  int statutCommande = 4, // 4 = "En attente"
}) async {
  // Validation
  if (clientId.trim().isEmpty ||
      nomClient.trim().isEmpty ||
      adresseClient.trim().isEmpty ||
      codeRep.trim().isEmpty ||
      nomRep.trim().isEmpty) {
    throw Exception(
        'All required fields (clientId, nomClient, adresseClient, codeRep, nomRep) must be non-empty');
  }

  if (items.isEmpty) {
    throw Exception('Items list cannot be empty');
  }

  // Normalisation
  final normalized = _normalizeOrderItemsCamel(items);
  final total = normalized.fold<double>(
      0, (sum, x) => sum + (x['totalPrice'] as double));

  final payload = {
    'clientId': clientId,
    'nomClient': nomClient,
    'adresseClient': adresseClient,
    'codeRep': codeRep,
    'nomRep': nomRep,
    'reference': reference,
    'createdAt': (createdAt ?? DateTime.now().toUtc()).toIso8601String(),
    'dateLivraison': dateLivraison?.toUtc().toIso8601String(),
    'total': total,
    'statutCommande': statutCommande,
    'items': normalized,
    'note': note ?? '', // ✅ ajouté

  };

  if (kDebugMode) {
    print('👉 Sending order payload: ${jsonEncode(payload)}');
  }

  // === Cas Offline ===
  if (!await _isOnline()) {
    if (kDebugMode) print('📴 Offline: Enqueuing + saving in Hive');
    await OfflineOrders.enqueue(payload, userId: 0);

    // 🔹 Sauvegarde dans Hive immédiatement
    try {
      final box = await Hive.openBox('orders_cache');
      final cached = (box.get('all') as List?) ?? [];
      cached.add(payload);
      await box.put('all', cached);
    } catch (e) {
      if (kDebugMode) print("Erreur sauvegarde offline Hive: $e");
    }

    return;
  }

  // === Cas Online ===
  try {
    final response = await _postOrderOnline(payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        print('❌ Order creation failed: [${response.statusCode}] ${response.body}');
      }
      throw Exception(
          'Erreur création commande: ${response.statusCode} | ${response.body}');
    }

    if (kDebugMode) {
      print('✅ Order created successfully: ${response.body}');
    }

    // 🔹 Sauvegarde aussi dans Hive (cache local à jour)
    try {
      final box = await Hive.openBox('orders_cache');
      final cached = (box.get('all') as List?) ?? [];
      cached.add(payload);
      await box.put('all', cached);
    } catch (e) {
      if (kDebugMode) print("Erreur sauvegarde Hive après online: $e");
    }

  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error sending order, enqueuing for later sync: $e');
    }
    await OfflineOrders.enqueue(payload, userId: 0);

    // 🔹 Sauvegarde fallback Hive
    try {
      final box = await Hive.openBox('orders_cache');
      final cached = (box.get('all') as List?) ?? [];
      cached.add(payload);
      await box.put('all', cached);
    } catch (e) {
      if (kDebugMode) print("Erreur sauvegarde Hive fallback: $e");
    }

    rethrow;
  }
}


  // ---- FIXED: migrate legacy PascalCase payloads before sync ----
  static Future<void> syncPendingOrders() async {
    if (!await _isOnline()) return;
    final list = await OfflineOrders.pending();
    for (final entry in List<Map<String, dynamic>>.from(list)) {
      final offlineId = entry['offlineId'] as String;
      final raw = Map<String, dynamic>.from(entry['payload'] as Map);

      final payload = _migrateOrderPayloadToCamel(raw);

      try {
        final res = await _postOrderOnline(payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          await OfflineOrders.remove(offlineId);
        } else if (kDebugMode) {
          print('Sync order failed [${res.statusCode}]: ${res.body}');
        }
      } catch (_) {
        // keep in queue
      }
    }
  }

  // Convert any legacy PascalCase order payload to camelCase + UTC.
  static Map<String, dynamic> _migrateOrderPayloadToCamel(Map<String, dynamic> p) {
    String? s(String a, [String? b]) =>
        p[a]?.toString() ?? (b != null ? p[b]?.toString() : null);

    DateTime? parseDt(String a, [String? b]) {
      final raw = p[a] ?? (b != null ? p[b] : null);
      if (raw == null) return null;
      try {
        final dt = DateTime.parse(raw.toString());
        return dt.isUtc ? dt : dt.toUtc();
      } catch (_) {
        return null;
      }
    }

    List<Map<String, dynamic>> itemsCamel() {
      final raw = (p['items'] ?? p['Items'] ?? const []) as List;
      return raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final sku = (m['itmref'] ?? m['Itmref'] ?? m['sku'] ?? '').toString();
        final qty = ((m['quantity'] ?? m['Quantity'] ?? 0) as num).toInt();
        final up = ((m['unitPrice'] ?? m['UnitPrice'] ?? 0) as num).toDouble();
        final tp = m['totalPrice'] ?? m['TotalPrice'];
        final tot = tp is num ? tp.toDouble() : (up * qty);
        return {
          'itmref': sku,
          'quantity': qty,
          'unitPrice': up,
          'totalPrice': tot,
        };
      }).toList();
    }

    final totalNum = (p['total'] ?? p['Total'] ?? 0);
    final total = totalNum is num ? totalNum.toDouble() : 0.0;

    final statutNum = (p['statutCommande'] ?? p['StatutCommande'] ?? 4);
    final statut = statutNum is int ? statutNum : int.tryParse('$statutNum') ?? 4;

    return {
      'clientId': s('clientId', 'ClientId') ?? '',
      'nomClient': s('nomClient', 'NomClient') ?? '',
      'adresseClient': s('adresseClient', 'AdresseClient') ?? '',
      'codeRep': s('codeRep', 'CodeRep') ?? '',
      'nomRep': s('nomRep', 'NomRep') ?? '',
      'reference': s('reference', 'Reference') ?? '',
      'createdAt': (parseDt('createdAt', 'CreatedAt') ?? DateTime.now().toUtc()).toIso8601String(),
      'dateLivraison': parseDt('dateLivraison', 'DateLivraison')?.toIso8601String(),
      'total': total,
      'statutCommande': statut,
      'note': s('note', 'Note') ?? '', // ✅ ajouté
      'items': itemsCamel(),
    };
  }

  static Future<bool> tryPostOrder(Map<String, dynamic> payload) async {
    final url = Uri.parse('$_baseUrl/orders');
    try {
      final res = await _post(url, payload);
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (!ok && kDebugMode) {
        print('Order failed [${res.statusCode}]: ${res.body}');
      }
      return ok;
    } catch (e, st) {
      if (kDebugMode) {
        print('Order exception: $e');
        print(st);
      }
      return false;
    }
  }

  // ===========================================================================
  // REPORTS (generic helpers)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> _fetchList(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final res = await _get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('HTTP ${res.statusCode} on $path');
  }

  static Future<List<Map<String, dynamic>>> getRevenueByMonth() =>
      _fetchList('/reports/revenue-month');

  static Future<List<Map<String, dynamic>>> getClientReferences() =>
      _fetchList('/reports/client-refs');

  static Future<List<Map<String, dynamic>>> getInvoices() =>
      _fetchList('/reports/invoices');

  static Future<List<Map<String, dynamic>>> getInvoiceLines(int orderId) =>
      _fetchList('/reports/invoices/$orderId/lines');

  static Future<List<Map<String, dynamic>>> getReliquats() =>
      _fetchList('/reports/reliquats');

  static Future<List<Map<String, dynamic>>> getLastInvoiceByClient() =>
      _fetchList('/reports/last-invoice-by-client');

  static Future<List<Map<String, dynamic>>> getPendingCart() =>
      _fetchList('/reports/cart/pending');

  // ===========================================================================
  // CHIFFRE D'AFFAIRE
  // ===========================================================================
  static Future<ChiffreAffaire> fetchChiffreAffaire(
      String subCodeClient, String raisonSocial) async {
    final uri = Uri.parse('$_baseUrl/Client/ChiffreAffaire')
        .replace(queryParameters: {
      'SubCodeClient': subCodeClient,
      'raisonSocial': raisonSocial,
    });
    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        await OfflineCache.saveChiffreAffaire(data);
        return ChiffreAffaire.fromJson(data as Map<String, dynamic>);
      }
      throw Exception(
          'Erreur ChiffreAffaire: ${res.statusCode} | ${res.body}');
    } catch (e) {
      final cached = await OfflineCache.getChiffreAffaire(subCodeClient);
      if (cached != null) return ChiffreAffaire.fromJson(cached);
      throw Exception('Erreur réseau: $e');
    }
  }

  // ===========================================================================
  // SALES ITEMS (ReferencementClient)
  // ===========================================================================
  static Future<List<ReferencementClient>> fetchSalesItems(
      String codeClient) async {
    if (codeClient.trim().isEmpty) return <ReferencementClient>[];

    final uri = Uri.parse('$_baseUrl/client/referencement_client')
        .replace(queryParameters: {'CodeClient': codeClient});
    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = jsonDecode(res.body);
        final List<dynamic> data = (raw is List) ? raw : <dynamic>[];
        await OfflineCache.saveSalesItems(codeClient, data);
        return data
            .map((e) => ReferencementClient.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        throw Exception(
            'Erreur SalesItems: ${res.statusCode} | ${res.body}');
      }
    } catch (_) {
      final cached = await OfflineCache.getSalesItems(codeClient);
      if (cached.isEmpty) return <ReferencementClient>[];
      return cached
          .map((e) => ReferencementClient.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  // ===========================================================================
  // FACTURES (client/rep)
  // ===========================================================================
  Future<List<Facture>> _fetchfacture(String codeClient, String rep) async {
    if (codeClient.isEmpty || rep.isEmpty) {
      throw Exception('CodeClient et CodeRep sont requis');
    }

    final base = Uri.parse(apiRoot); // e.g., https://host/api
    final uri = base.replace(
      pathSegments: [...base.pathSegments, 'Client', 'factures'],
      queryParameters: {'CodeClient': codeClient, 'CodeRep': rep},
    );

    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode} on GET $uri\n${res.body}');
    }

    final raw = json.decode(res.body);
    final List<dynamic> data =
        (raw is List) ? raw : (raw['data'] as List<dynamic>? ?? const []);
    return data
        .map((e) => Facture.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================================================================
  // FACTURES NRG tous les clients
  // ===========================================================================
  static Future<List<listefactures>> fetchListeFactures(String rep) async {
    if (rep.isEmpty) {
      throw Exception('Rep requis');
    }

    final base = Uri.parse(apiRoot);
    final uri = base.replace(
      pathSegments: [...base.pathSegments, 'Client', 'Listefacturestousclients'],
      queryParameters: {'rep': rep},
    );

    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode} on GET $uri\n${res.body}');
    }

    final raw = json.decode(res.body);
    final List<dynamic> data =
        (raw is List) ? raw : (raw['data'] as List<dynamic>? ?? const []);
    return data
        .map((e) => listefactures.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================================================================
  // DERNIERE FACTURE
  // ===========================================================================
  static Future<List<DerniereFacture>> fetchDerniereFacture(
      String codeClient) async {
    final uri = Uri.parse('$_baseUrl/Client/DerniereFacture')
        .replace(queryParameters: {'CodeClient': codeClient});

    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);

        if (body is Map<String, dynamic> && body.containsKey('error')) {
          return [];
        }

        final List<Map<String, dynamic>> list = body is List
            ? body.cast<Map<String, dynamic>>()
            : body is Map<String, dynamic>
                ? [body]
                : <Map<String, dynamic>>[];

        if (list.isEmpty) return [];

        await OfflineCache.saveDerniereFacture(codeClient, list);
        return list.map((e) => DerniereFacture.fromJson(e)).toList();
      }

      throw Exception('Erreur API (${res.statusCode}): ${res.body}');
    } catch (e) {
      final cached = await OfflineCache.getDerniereFacture(codeClient);
      if (cached.isNotEmpty) {
        return cached.map((e) => DerniereFacture.fromJson(e)).toList();
      }
      throw Exception('No cached data available and fetch failed: $e');
    }
  }

  // ===========================================================================
  // CHEQUES
  // ===========================================================================
  static Future<List<Cheque>> fetchCheques(
    String codeClient,
    String rep,
  ) async {
    if (codeClient.isEmpty || rep.isEmpty) {
      throw Exception('CodeClient et Rep sont requis');
    }

    final uri = Uri.parse('$_baseUrl/Cheques')
        .replace(queryParameters: {'codeClient': codeClient, 'rep': rep});

    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List data = jsonDecode(res.body) as List;
        await OfflineCache.saveCheques(codeClient, rep, data);
        return data.map((e) => Cheque.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(
          'Erreur chargement Cheques: ${res.statusCode} | ${res.body}');
    } catch (e) {
      final cached = await OfflineCache.getCheques(codeClient, rep);
      return cached.map((e) => Cheque.fromJson(e)).toList();
    }
  }

  // ===========================================================================
  // RELIQUATS
  // ===========================================================================
  static Future<List<Reliquat>> fetchReliquats({
    required String codeClient,
    required String site,
  }) async {
    final uri = Uri.parse('$_baseUrl/Client/Reliquats').replace(
      queryParameters: {'CodeClient': codeClient, 'Site': site},
    );
    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          final List data = decoded;
          await OfflineCache.saveReliquats(codeClient, data);
          return data
              .map((e) => Reliquat.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Réponse inattendue: la réponse n\'est pas une liste');
      }
      throw Exception('Erreur HTTP: ${res.statusCode} | ${res.body}');
    } catch (e) {
      final cached = await OfflineCache.getReliquats(codeClient);
      if (cached.isNotEmpty) {
        return cached.map((e) => Reliquat.fromJson(e)).toList();
      }
      return [];
    }
  }

  // ===========================================================================
  // Liste cheques
  // ===========================================================================
  static Future<List<Cheque>> fetchListeCheques(String rep) async {
    if (rep.isEmpty) {
      throw Exception('Rep requis');
    }

    final uri = Uri.parse('$_baseUrl/Client/Listecheques')
        .replace(queryParameters: {'rep': rep});

    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List data = jsonDecode(res.body) as List;
        await OfflineCache.saveListecheques(rep, data);
        return data.map((e) => Cheque.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(
          'Erreur chargement Cheques: ${res.statusCode} | ${res.body}');
    } catch (e) {
      final cached = await OfflineCache.getListecheques(rep);
      return cached.map((e) => Cheque.fromJson(e)).toList();
    }
  }

  // ===========================================================================
  // Préavis
  // ===========================================================================
  static Future<List<Preavis>> fetchPreavis({required String rep}) async {
    final uri = Uri.parse('$_baseUrl/Client/PreavisImpaye')
        .replace(queryParameters: {'rep': rep});

    final res = await _get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => Preavis.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic>) {
        return [Preavis.fromJson(data)];
      } else {
        throw Exception('Format inattendu: ${res.body}');
      }
    } else {
      throw Exception('Erreur HTTP ${res.statusCode} | ${res.body}');
    }
  }

  static Future<List<Preavis>> fetchPreavisclient({
    required String rep,
    required String codeClient,
  }) async {
    final uri = Uri.parse('$_baseUrl/Client/PreavisImpayeparclient').replace(
      queryParameters: {'rep': rep, 'CodeClient': codeClient},
    );

    final res = await _get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => Preavis.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic>) {
        return [Preavis.fromJson(data)];
      } else {
        throw Exception('Format inattendu: ${res.body}');
      }
    } else {
      throw Exception('Erreur HTTP ${res.statusCode} | ${res.body}');
    }
  }

  // ===========================================================================
  // CMD
  // ===========================================================================
  static Future<List<Cmd>> fetchCmd(String codeClient, String site) async {
    final uri = Uri.parse('$_baseUrl/cmd')
        .replace(queryParameters: {'CodeClient': codeClient});
    try {
      final res = await _get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic data = jsonDecode(res.body);
        if (data is List) {
          await OfflineCache.saveCmd(codeClient, data);
          return data
              .map((e) => Cmd.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw Exception(
            'Invalid data format: Expected a list, got ${data.runtimeType}');
      }
      throw Exception('Failed to load Cmd: ${res.statusCode} - ${res.body}');
    } catch (e) {
      final cached = await OfflineCache.getCmd(codeClient);
      if (cached.isNotEmpty) {
        return cached
            .map((e) => Cmd.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('No cached data available and fetch failed: $e');
    }
  }
}
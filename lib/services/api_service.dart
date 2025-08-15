import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'offline_cache.dart';
import 'auth_cache.dart';
import 'offline_orders.dart'; // ✅ keep this single line

import '../models/order.dart';
import '../models/visite.dart';
import '../models/product.dart';
import '../models/client.dart';


class ApiService {
  // TODO: change to your server IP/host
  static const String _baseUrl = 'http://192.168.0.103:5274/api';

  // ---- connectivity helper (handles v6 returning List<ConnectivityResult>) ----
  static Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  // ===========================================================================
  // AUTH (with offline fallback)
  // ===========================================================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    // Try ONLINE first
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Persist identity for OFFLINE login later
        try {
          await AuthCache.saveIdentity(
            email: email,
            password: password,
            userJson: data,
          );
        } catch (_) {
          // don't block login if secure save fails
        }

        return {'success': true, 'data': data};
      }

      // Server reachable but refused credentials
      final msg = _extractMessage(response.body) ?? 'Erreur de connexion';
      return {'success': false, 'message': msg};
    } catch (e) {
      // Likely offline or host unreachable → try OFFLINE login
      final cachedUser =
          await AuthCache.tryOfflineLogin(email: email, password: password);
      if (cachedUser != null) {
        return {'success': true, 'data': cachedUser, 'offline': true};
      }
      return {'success': false, 'message': 'Hors-ligne et aucune session trouvée'};
    }
  }

  static String? _extractMessage(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map && m['message'] != null) return m['message'].toString();
      return null;
    } catch (_) {
    return null;
    }
  }

  // ===========================================================================
  // REPRESENTANT
  // ===========================================================================
  static Future<bool> registerRepresentant(
    String firstName,
    String lastName,
    String email,
    String password,
    String codeSage,
  ) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'codeSage': codeSage,
        }),
      );
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
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<List<Map<String, dynamic>>> getReclamationsByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/reclamation/user/$userId');
    final res = await http.get(url);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur chargement des réclamations');
  }

  /// Backend route: GET /api/reclamation
  /// Online -> cache; Offline -> return cached
  static Future<List<Map<String, dynamic>>> getAllReclamations() async {
    final url = Uri.parse('$_baseUrl/reclamation');
    try {
      final res = await http.get(url);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
        await OfflineCache.saveReclamations(list);
        return list;
      }
      throw Exception('HTTP ${res.statusCode}');
    } catch (_) {
      // offline fallback
      return OfflineCache.getReclamations();
    }
  }

  // ===========================================================================
  // CLIENTS (cached per user)
  // ===========================================================================
  static Future<List<Client>> getClientsByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/client/user/$userId');

    if (await _isOnline()) {
      try {
        final response = await http.get(url);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final List data = jsonDecode(response.body) as List;
          await OfflineCache.saveClients(
            userId,
            List<Map<String, dynamic>>.from(data),
          );
          return data
              .map((json) => Client.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (_) {
        // network error -> try cache
        final cached = OfflineCache.getClients(userId);
        return cached.map((j) => Client.fromJson(j)).toList();
      }
    } else {
      // offline -> cache
      final cached = OfflineCache.getClients(userId);
      return cached.map((j) => Client.fromJson(j)).toList();
    }
  }

  static Future<List<Map<String, dynamic>>> getClientsGroupedByRepresentant() async {
    final url = Uri.parse('$_baseUrl/representant/by-representant');
    final response = await http.get(url);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
    } else {
      throw Exception('Erreur chargement clients groupés');
    }
  }

  // ===========================================================================
  // VISITES (queue offline, auto-sync later via SyncService)
  // ===========================================================================
  static Future<List<Visite>> getVisitesByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/visite/user/$userId');

    if (await _isOnline()) {
      final response = await http.get(url);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body) as List;
        // optionally cache visits history
        await OfflineCache.saveVisits(List<Map<String, dynamic>>.from(data));
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

  /// If offline or request fails => queue the visit to sync later.
  static Future<bool> addVisite(Visite visite) async {
    final payload = visite.toJson();

    if (!await _isOnline()) {
      await OfflineCache.queueVisit(payload);
      return true;
    }

    try {
      final url = Uri.parse('$_baseUrl/visite');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      await OfflineCache.queueVisit(payload);
      return true;
    } catch (_) {
      await OfflineCache.queueVisit(payload);
      return true;
    }
  }

  static Future<void> updateVisite(int id, Visite visite) async {
    final url = Uri.parse('$_baseUrl/visite/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(visite.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur mise à jour visite');
    }
  }

  static Future<void> deleteVisite(int id) async {
    final url = Uri.parse('$_baseUrl/visite/$id');
    final response = await http.delete(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur suppression visite');
    }
  }

  /// Used by SyncService to push queued visits
  static Future<bool> tryPostVisit(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$_baseUrl/visite');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // PRODUITS  (online only here; you can add a Hive cache if you want)
  // ===========================================================================
  static Future<List<Product>> getProducts() async {
    final url = Uri.parse('$_baseUrl/product');
    final response = await http.get(url);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List data = jsonDecode(response.body) as List;
      return data
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Erreur chargement produits');
    }
  }

  static Future<void> addProduct(Product product) async {
    final url = Uri.parse('$_baseUrl/product');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur ajout produit");
    }
  }

  static Future<void> deleteProduct(int id) async {
    final url = Uri.parse('$_baseUrl/product/$id');
    final response = await http.delete(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur suppression produit");
    }
  }

  // ===========================================================================
  // COMMANDES (OFFLINE QUEUE + SYNC)
  // ===========================================================================
  // Private: online post (keeps your existing payload shape)
  static Future<http.Response> _postOrderOnline(Map<String, dynamic> order) {
    final url = Uri.parse('$_baseUrl/orders');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order),
    );
  }

  static Future<List<Order>> getOrders(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/user/$userId'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Erreur chargement commandes: ${response.statusCode}');
    }
  }

  // ⬇️ UPDATED: if offline (or network fails), we queue the order and return without throwing.
  static Future<void> createOrder(int userId, int productId, int quantity) async {
    final payload = {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'createdAt': DateTime.now().toIso8601String(), // optional for trace
    };

    // OFFLINE → queue then return
    if (!await _isOnline()) {
      await OfflineOrders.enqueue(payload, userId: userId);
      return;
    }

    // ONLINE → try; if network error, queue; if server rejects, keep your previous behavior (throw)
    try {
      final response = await _postOrderOnline(payload);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Server responded with an error → keep original behavior
        throw Exception('Erreur lors de la création de la commande');
      }
    } catch (_) {
      // Network failure → queue and return
      await OfflineOrders.enqueue(payload, userId: userId);
    }
  }

  static Future<List<Order>> getAllOrders() async {
    final url = Uri.parse('$_baseUrl/orders/full');
    final response = await http.get(url);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List;
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Erreur lors du chargement des commandes");
    }
  }

  /// Call on app start and when connectivity returns to push queued orders
  static Future<void> syncPendingOrders() async {
    if (!await _isOnline()) return;
    final list = await OfflineOrders.pending();
    for (final entry in List<Map<String, dynamic>>.from(list)) {
      final offlineId = entry['offlineId'] as String;
      final payload = Map<String, dynamic>.from(entry['payload'] as Map);
      try {
        final res = await _postOrderOnline(payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          await OfflineOrders.remove(offlineId);
        }
      } catch (_) {
        // keep in queue for next attempt
      }
    }
  }

  // ===========================================================================
  // REPRÉSENTANTS
  // ===========================================================================
  static Future<bool> deleteRepresentant(int repId) async {
    final res = await http.delete(Uri.parse('$_baseUrl/representant/$repId'));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<Map<String, dynamic>> updateRepresentant(
    int id, {
    required String firstName,
    required String lastName,
    required String email,
    required String codeSage,
    required String role, // "Admin" or "Représentant"
  }) async {
    final url = Uri.parse('$_baseUrl/representant/$id');

    final payload = {
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'CodeSage': codeSage,
      'Role': role,
    };

    try {
      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      return {'ok': ok, 'status': res.statusCode, 'body': res.body};
    } catch (e) {
      return {'ok': false, 'status': 0, 'body': 'Network error: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getRepresentantsByAggregated() async {
    final res = await http.get(Uri.parse('$_baseUrl/representant/by-representant'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    throw Exception('Erreur chargement représentants: ${res.statusCode}');
  }
  static Future<bool> tryPostOrder(Map<String, dynamic> payload) async {
  try {
    final url = Uri.parse('$_baseUrl/orders');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (_) {
    return false;
  }
}
}
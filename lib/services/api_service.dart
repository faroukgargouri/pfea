import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/visite.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/client.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.100.105:5274/api';

  // 🔐 Connexion
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Erreur de connexion'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion : $e'};
    }
  }

  // 👤 Enregistrement Représentant
  static Future<bool> registerRepresentant(String firstName, String lastName, String email, String password, String codeSage) async {
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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 🧾 RECLAMATIONS
  static Future<bool> addReclamation(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/reclamation');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getReclamationsByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/reclamation/user/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement des réclamations');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllReclamations() async {
    final url = Uri.parse('$_baseUrl/reclamation/all');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement de toutes les réclamations');
    }
  }

  // 👥 CLIENTS
  static Future<List<Client>> getClientsByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/client/user/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement des clients');
    }
  }

  static Future<List<Map<String, dynamic>>> getClientsGroupedByRepresentant() async {
    final url = Uri.parse('$_baseUrl/representant/by-representant');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement clients groupés');
    }
  }

  // 📋 VISITES
  static Future<List<Visite>> getVisitesByUser(int userId) async {
    final url = Uri.parse('$_baseUrl/visite/user/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Visite.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement des visites');
    }
  }

  static Future<bool> addVisite(Visite visite) async {
    final url = Uri.parse('$_baseUrl/visite');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(visite.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<void> updateVisite(int id, Visite visite) async {
    final url = Uri.parse('$_baseUrl/visite/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(visite.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour visite');
    }
  }

  static Future<void> deleteVisite(int id) async {
    final url = Uri.parse('$_baseUrl/visite/$id');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression visite');
    }
  }

  // 🛍️ PRODUITS
  static Future<List<Product>> getProducts() async {
    final url = Uri.parse('$_baseUrl/product');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
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
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Erreur ajout produit");
    }
  }

  static Future<void> deleteProduct(int id) async {
    final url = Uri.parse('$_baseUrl/product/$id');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception("Erreur suppression produit");
    }
  }

  // ✅ COMMANDES
  static Future<List<Order>> getOrders(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/user/$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement commandes: ${response.statusCode}');
    }
  }
  

  static Future<void> createOrder(int userId, int productId, int quantity) async {
    final url = Uri.parse('$_baseUrl/orders');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'productId': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de la création de la commande');
    }
  }
  // ✅ Récupérer toutes les commandes (admin)
static Future<List<Order>> getAllOrders() async {
  final url = Uri.parse('$_baseUrl/orders/full');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Order.fromJson(e)).toList();
  } else {
    throw Exception("Erreur lors du chargement des commandes");
  }
}


  // 🧺 PANIER
  static Future<void> addToCart(CartItem item) async {
    final url = Uri.parse('$_baseUrl/cart');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur ajout au panier');
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'order_list_screen.dart'; // 👈 Assure-toi que ce chemin est correct

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int nbProduits = 0;
  int nbClients = 0;
  double ventesTotales = 0.0;
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final url = Uri.parse('http://192.168.100.105:5274/api/dashboard/stats');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nbProduits = data['produits'];
          nbClients = data['clients'];
          ventesTotales = (data['ventes'] as num).toDouble();
        });
        await fetchOrders();
      } else {
        throw Exception("Erreur API");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement stats : $e")),
      );
    }
  }

  Future<void> fetchOrders() async {
    final url = Uri.parse('http://192.168.100.105:5274/api/orders/full');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        orders = data.map((json) => Order.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      throw Exception("Erreur chargement commandes");
    }
  }

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title),
        subtitle: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget buildOrderSection() {
    return Expanded(
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ExpansionTile(
            title: Text("Commande #${order.orderId} - ${order.client}"),
            subtitle: Text("Date: ${order.createdAt.split('T')[0]} | Total: ${order.total.toStringAsFixed(2)} TND"),
            children: order.items.map((item) {
              return ListTile(
                title: Text(item.productName),
                subtitle: Text("x${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} TND"),
                trailing: Text("${item.totalPrice.toStringAsFixed(2)} TND"),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Tableau de bord'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildStatCard("Produits", "$nbProduits produits", Icons.inventory_2, Colors.orange),
                  buildStatCard("Représentants", "$nbClients représentants", Icons.people, Colors.blue),
                  buildStatCard("Total ventes", "${ventesTotales.toStringAsFixed(3)} TND", Icons.attach_money, Colors.green),
                  const SizedBox(height: 20),

                  // ✅ BOUTON POUR AFFICHER LA PAGE COMPLÈTE DES COMMANDES
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderListScreen()),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text("Voir toutes les commandes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text("📦 Liste des commandes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  buildOrderSection(),
                ],
              ),
      ),
    );
  }
}

// 🔽 MODELES

class OrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['productName'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }
}

class Order {
  final int orderId;
  final String client;
  final String createdAt;
  final double total;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.client,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'],
      client: json['client'],
      createdAt: json['createdAt'],
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/order_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String clientId = prefs.getString('clientId') ?? '0';
    print(prefs.getString('clientId'));
    try {
      final fetchedOrders = await ApiService.getOrdersByClientId(clientId);
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement commandes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('Aucune commande trouvée.'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("Commande #${order.id}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${order.createdAt}"),
                            Text("Total: ${order.total.toStringAsFixed(2)} DT"),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                       onTap: () {
                          Navigator.push(
                          context,
                           MaterialPageRoute(
                           builder: (_) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                ),
    );
                }
    ));
   } 
  }


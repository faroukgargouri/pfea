// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // ✅ pour graphiques
import '../data/api_config.dart';

const kPrimaryBlue = Color(0xFF0D47A1);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final statsUri = Uri.parse('$apiRoot/Admin/stats'); // ✅ endpoint admin
      final res = await http.get(statsUri);
      if (res.statusCode == 200) {
        stats = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception("Erreur chargement stats");
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur: $e")),
        );
      }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// 🟢 Histogramme : Commandes vs Réclamations vs Visites
  Widget _buildBarChart() {
    final commandes = (stats['commandes'] ?? 0).toDouble();
    final reclamations = (stats['reclamations'] ?? 0).toDouble();
    final visites = (stats['visites'] ?? 0).toDouble();

    final maxY = [commandes, reclamations, visites].reduce((a, b) => a > b ? a : b) + 5;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text("Cmds");
                    case 1:
                      return const Text("Récl");
                    case 2:
                      return const Text("Visites");
                  }
                  return const Text("");
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                toY: commandes,
                color: Colors.teal,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              )
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                toY: reclamations,
                color: Colors.red,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              )
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(
                toY: visites,
                color: Colors.purple,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              )
            ]),
          ],
        ),
      ),
    );
  }

  /// 🟡 Jauge (ventes en TND)
  Widget _buildVentesGauge() {
    final ventes = (stats['ventes'] ?? 0).toDouble();
    final maxTarget = ventes > 10000 ? ventes * 1.2 : 10000; // cible arbitraire
    final percent = (ventes / maxTarget * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("Progression des ventes",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
            ),
            Text("${ventes.toStringAsFixed(2)} TND",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard("Produits",
                        "${stats['produits'] ?? 0}", Icons.inventory, Colors.orange),
                    _buildStatCard("Représentants",
                        "${stats['representants'] ?? 0}", Icons.people, Colors.blue),
                    _buildStatCard("Visites",
                        "${stats['visites'] ?? 0}", Icons.location_on, Colors.purple),
                    _buildStatCard("Réclamations",
                        "${stats['reclamations'] ?? 0}", Icons.report, Colors.red),
                    _buildStatCard("Commandes",
                        "${stats['commandes'] ?? 0}", Icons.shopping_cart, Colors.teal),
                    _buildStatCard("Total ventes",
                        "${(stats['ventes'] ?? 0).toStringAsFixed(2)} TND",
                        Icons.attach_money,
                        Colors.green),

                    const SizedBox(height: 20),
                    const Text("📉 Commandes vs Réclamations vs Visites",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildBarChart(),

                    const SizedBox(height: 20),
                    _buildVentesGauge(),
                  ],
                ),
              ),
            ),
    );
  }
}

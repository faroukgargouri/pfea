import 'package:flutter/material.dart';
import 'visit_list_screen.dart';
import 'product_list_screen.dart';
import 'representant_list_screen.dart'; // ✅ CRUD complet

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const VisitListScreen(),
      const ProductListScreen(),
      const RepresentantListScreen(), // ✅ Page des représentants
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Visites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Représentants',
          ),
        ],
      ),
    );
  }
}

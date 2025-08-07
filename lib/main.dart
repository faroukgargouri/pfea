import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/admin_product_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart'; // 👈 à vérifier selon celui que tu veux

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/login',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminProductScreen(),
        '/client': (context) => const HomeScreen(),
        '/dashboard': (context) => const DashboardScreen(), // ✅ Ajouté ici
        
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'Representant_Home_Page.dart'; // À importer si ce n’est pas déjà fait

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void _loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.login(email, password);
    setState(() => isLoading = false);

    if (result['success']) {
      final user = result['data'];
      final userId = user['id'];
      final role = user['role'];
      final fullName = "${user['firstName']} ${user['lastName']}";
      final codeSage = user['codeSage'] ?? "";

      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('userId', userId);
      prefs.setString('fullName', fullName);
      prefs.setString('codeSage', codeSage);
      prefs.setString('role', role);

      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'Représentant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RepresentantHomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rôle non reconnu")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur de connexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 24),
              const Text(
                'Bienvenue',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Connexion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

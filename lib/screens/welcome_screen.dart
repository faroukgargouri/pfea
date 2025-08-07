import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenue sur TrikiShop',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text("Se connecter"),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: const Text("Créer un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

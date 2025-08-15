import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_product_screen.dart';
import 'screens/representant_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('clients_cache');
  await Hive.openBox('reclamations_cache');
  await Hive.openBox('visits_cache');
  await Hive.openBox('visits_pending');
  await Hive.openBox('orders_pending');   // ✅ for offline orders
  await Hive.openBox('products_cache');   // ✅ if you use OfflineCache.saveProducts

  SyncService.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PFE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminProductScreen(),
        '/representant': (_) => const RepresentantHomePage(),
      },
      onUnknownRoute: (s) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Page not found')),
          body: Center(child: Text('Unknown route: ${s.name}')),
        ),
      ),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 399, name: MOBILE),
          Breakpoint(start: 400, end: 599, name: 'MOBILE_PLUS'),
          Breakpoint(start: 600, end: 899, name: TABLET),
          Breakpoint(start: 900, end: 1199, name: DESKTOP),
          Breakpoint(start: 1200, end: double.infinity, name: 'XL'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_product_screen.dart';
import 'screens/representant_Home_Page.dart';
import 'screens/cheques_screen.dart';
import 'screens/chiffre_affaire_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('reclamations_cache');
  await Hive.openBox('clients_cache');
  await Hive.openBox('products_cache');
  await Hive.openBox('visits_cache');
  await Hive.openBox('visits_pending');
  await Hive.openBox('chiffre_affaire_cache');
  await Hive.openBox('sales_items_cache');
  await Hive.openBox('factures_cache');
  await Hive.openBox('derniere_facture_cache');
  await Hive.openBox('cheques_cache');
  await Hive.openBox('reliquats_cache');
  await Hive.openBox('cmd_cache');
  
  SyncService.start();

  runApp(const MyApp());
}

class LoggingNavigatorObserver extends NavigatorObserver {
   LoggingNavigatorObserver();

  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('[NAV] push → ${route.settings.name ?? route}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('[NAV] pop → ${route.settings.name ?? route}');
    super.didPop(route, previousRoute);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PFE',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [LoggingNavigatorObserver()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),

      // Routes “statiques”
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminProductScreen(),
        '/representant': (_) => const RepresentantHomePage(),
      },

      // Routes “dynamiques” avec arguments
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/cheques':
            // attend un Map<String, String> : { codeClient, rep }
            final args = (settings.arguments ?? const {}) as Map<String, dynamic>;
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/cheques'),
              builder: (_) => ChequesScreen(
                codeClient: args['codeClient']?.toString(),
                rep: args['rep']?.toString(),
              ),
            );

          case '/ca':
            // attend un Map<String, String> : { rep }
            final args = (settings.arguments ?? const {}) as Map<String, dynamic>;
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/ca'),
              builder: (_) => ChiffreAffairesScreen(
                subCodeClient: args['client']?.toString(),
                raisonSocial: args['raison sociale']?.toString(),

              ),
            );
        }
        return null;
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

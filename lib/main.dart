import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/business_service.dart';
import 'services/product_service.dart';
import 'services/customer_service.dart';
import 'services/order_service.dart';
import 'services/invoice_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/product_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
import 'providers/invoice_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  AuthService? authService;
  BusinessService? businessService;
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
    final s = Supabase.instance.client;
    authService = AuthService(s);
    businessService = BusinessService(supabase: s);
  }

  runApp(SpiceDeskApp(authService: authService, businessService: businessService, themeProvider: themeProvider));
}

class SpiceDeskApp extends StatelessWidget {
  final AuthService? authService;
  final BusinessService? businessService;
  final ThemeProvider themeProvider;

  const SpiceDeskApp({super.key, this.authService, this.businessService, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    if (authService == null || businessService == null) {
      return MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, debugShowCheckedModeBanner: false, home: const Scaffold(body: Center(child: Text('Not configured'))));
    }

    final s = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService!)),
        ChangeNotifierProvider(create: (_) => BusinessProvider(businessService!, authService!)),
        ChangeNotifierProvider(create: (_) => ProductProvider(ProductService(supabase: s), businessService!)),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider(CustomerService(supabase: s))),
        ChangeNotifierProvider(create: (_) => OrderProvider(OrderService(supabase: s, productService: ProductService(supabase: s)))),
        ChangeNotifierProvider(create: (_) => InvoiceProvider(InvoiceService(supabase: s))),
      ],
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeProvider>();
          return MaterialApp(
            title: AppConfig.appName,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.mode,
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

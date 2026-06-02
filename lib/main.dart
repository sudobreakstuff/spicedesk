import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/app_theme.dart';
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
  AuthService? authService;
  BusinessService? businessService;
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
    final supabase = Supabase.instance.client;
    authService = AuthService(supabase);
    businessService = BusinessService(supabase: supabase);
  }
  final themeProvider = ThemeProvider();
  await themeProvider.load();
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
      return MaterialApp(title: AppConfig.appName, theme: AppTheme.build(AppThemeMode.light), debugShowCheckedModeBanner: false, home: const _MissingConfig());
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
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: AppConfig.appName,
          theme: theme.theme(),
          darkTheme: AppTheme.build(AppThemeMode.dark),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class _MissingConfig extends StatelessWidget {
  const _MissingConfig();
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Supabase not configured', style: TextStyle(color: SpiceColors.textSecondary))));
}

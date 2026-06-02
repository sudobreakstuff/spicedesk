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
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService? authService;
  BusinessService? businessService;

  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    final supabase = Supabase.instance.client;
    authService = AuthService(supabase);
    businessService = BusinessService(supabase: supabase);
  } else {
    authService = null;
    businessService = BusinessService(supabase: null);
  }

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(SpiceDeskApp(
    authService: authService,
    businessService: businessService,
    themeProvider: themeProvider,
  ));
}

class SpiceDeskApp extends StatelessWidget {
  final AuthService? authService;
  final BusinessService? businessService;
  final ThemeProvider themeProvider;

  const SpiceDeskApp({
    super.key,
    this.authService,
    this.businessService,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (authService == null || businessService == null) {
      return MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.build(AppThemeMode.light),
        debugShowCheckedModeBanner: false,
        home: _NoSupabaseScreen(),
      );
    }

    final supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService!)),
        ChangeNotifierProvider(create: (_) => BusinessProvider(businessService!, authService!)),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductService(supabase: supabase), businessService!),
        ),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider(CustomerService(supabase: supabase))),
        ChangeNotifierProvider(
          create: (_) {
            final ps = ProductService(supabase: supabase);
            return OrderProvider(OrderService(supabase: supabase, productService: ps));
          },
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider(InvoiceService(supabase: supabase)),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: AppConfig.appName,
            theme: theme.themeData,
            darkTheme: AppTheme.build(AppThemeMode.dark),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {'/login': (_) => const LoginScreen()},
          );
        },
      ),
    );
  }
}

class _NoSupabaseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.orange),
              const SizedBox(height: 24),
              Text('Supabase Not Configured', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDark)),
              const SizedBox(height: 12),
              const Text('1. Create a free project at supabase.com\n2. Copy your URL and anon key\n3. Run the SQL migration\n4. Launch with --dart-define flags', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () {}, child: const Text('Continue Offline')),
            ],
          ),
        ),
      ),
    );
  }
}

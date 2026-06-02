import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/business_service.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/product_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
import 'providers/invoice_provider.dart';
import 'services/product_service.dart';
import 'services/customer_service.dart';
import 'services/order_service.dart';
import 'services/invoice_service.dart';
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

  runApp(SpiceDeskApp(
    authService: authService,
    businessService: businessService,
  ));
}

class SpiceDeskApp extends StatelessWidget {
  final AuthService? authService;
  final BusinessService? businessService;

  const SpiceDeskApp({
    super.key,
    this.authService,
    this.businessService,
  });

  @override
  Widget build(BuildContext context) {
    if (authService == null || businessService == null) {
      return MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: _NoSupabaseScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService!),
        ),
        ChangeNotifierProvider(
          create: (_) => BusinessProvider(businessService!, authService!),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final productService = ProductService(supabase: Supabase.instance.client);
            return ProductProvider(productService, businessService!);
          },
        ),
        ChangeNotifierProvider(
          create: (_) => PosProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerProvider(
            CustomerService(supabase: Supabase.instance.client),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final productService = ProductService(supabase: Supabase.instance.client);
            return OrderProvider(OrderService(
              supabase: Supabase.instance.client,
              productService: productService,
            ));
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            return InvoiceProvider(
              InvoiceService(supabase: Supabase.instance.client),
            );
          },
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
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
              const Icon(
                Icons.cloud_off,
                size: 64,
                color: AppTheme.spiceOrange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Supabase Not Configured',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To run SpiceDesk, you need to set up Supabase.\n\n'
                '1. Create a free project at supabase.com\n'
                '2. Copy your project URL and anon key\n'
                '3. Run the SQL migration from the /sql folder\n'
                '4. Run the app with:\n'
                '   flutter run --dart-define=SUPABASE_URL=your_url \\\n'
                '               --dart-define=SUPABASE_ANON_KEY=your_key',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                child: const Text('I\'ll set it up later (offline mode)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

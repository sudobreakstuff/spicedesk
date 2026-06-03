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

  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }

  runApp(SpiceDeskApp(themeProvider: themeProvider));
}

class SpiceDeskApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const SpiceDeskApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final s = AppConfig.isSupabaseConfigured ? Supabase.instance.client : null;
    final auth = s != null ? AuthService(s) : null;
    final bizSvc = s != null ? BusinessService(supabase: s) : null;

    if (auth == null || bizSvc == null) {
      return MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, debugShowCheckedModeBanner: false, home: const Scaffold(body: Center(child: Text('Supabase not configured'))));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
        ChangeNotifierProvider(create: (_) => BusinessProvider(bizSvc, auth)),
        ChangeNotifierProvider(create: (_) => ProductProvider(ProductService(supabase: s), bizSvc)),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider(CustomerService(supabase: s))),
        ChangeNotifierProvider(create: (_) => OrderProvider(OrderService(supabase: s, productService: ProductService(supabase: s)))),
        ChangeNotifierProvider(create: (_) => InvoiceProvider(InvoiceService(supabase: s))),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: AppConfig.appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

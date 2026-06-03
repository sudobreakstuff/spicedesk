import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../core/glass_theme.dart';
import 'auth/login_screen.dart';
import 'setup/business_setup_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState(); _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final ap = context.read<AuthProvider>();
    final bp = context.read<BusinessProvider>();
    if (ap.isLoggedIn) {
      await bp.loadBusiness();
      _go(bp.business != null ? const DashboardScreen() : const BusinessSetupScreen());
    } else {
      _go(const LoginScreen());
    }
  }

  void _go(Widget s) => Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: GlassColors.primary,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(18)), child: const Center(child: Text('SD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: GlassColors.primary)))),
      const SizedBox(height: 16),
      const Text('SpiceDesk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
      const SizedBox(height: 4),
      const Text('Business Suite', style: TextStyle(fontSize: 13, color: Color(0xAAFFFFFF))),
      const SizedBox(height: 28),
      const CupertinoActivityIndicator(color: Color(0xFFFFFFFF)),
    ])),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
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
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final ap = context.read<AuthProvider>();
    final bp = context.read<BusinessProvider>();
    if (!ap.isLoggedIn) { _go(const LoginScreen()); return; }
    await bp.loadBusiness();
    if (!mounted) return;
    _go(bp.hasBusiness ? const DashboardScreen() : const BusinessSetupScreen());
  }

  void _go(Widget s) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.blue,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.spa, color: Colors.white, size: 56),
      SizedBox(height: 16),
      Text('SpiceDesk', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
      SizedBox(height: 4),
      Text('Business Suite', style: TextStyle(color: Colors.white70, fontSize: 13)),
      SizedBox(height: 28),
      CircularProgressIndicator(color: Colors.white),
    ])),
  );
}

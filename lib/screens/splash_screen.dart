import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../core/app_theme.dart';
import 'auth/login_screen.dart';
import 'setup/business_setup_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
  late final _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

  @override
  void initState() {
    super.initState(); _ctrl.forward(); _init();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final ap = context.read<AuthProvider>();
    final bp = context.read<BusinessProvider>();
    if (!ap.isLoggedIn) { _go(const LoginScreen()); return; }
    await bp.loadBusiness();
    if (!mounted) return;
    _go(bp.business != null ? const DashboardScreen() : const BusinessSetupScreen());
  }

  void _go(Widget s) => Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (_, __, ___) => s, transitionDuration: const Duration(milliseconds: 300), transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c)));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(color: SpiceColors.primary),
      child: Center(child: FadeTransition(opacity: _fade, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Center(child: Text('SD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: SpiceColors.primary, letterSpacing: -1)))),
        const SizedBox(height: 16),
        Text('SpiceDesk', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Business Suite', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 28),
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.7))),
      ]))),
    ),
  );
}

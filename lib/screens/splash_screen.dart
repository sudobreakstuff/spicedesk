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
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final ap = context.read<AuthProvider>();
    final bp = context.read<BusinessProvider>();

    if (!ap.isLoggedIn) {
      _go(const LoginScreen());
      return;
    }
    await bp.loadBusiness();
    if (!mounted) return;
    if (bp.hasBusiness) {
      _go(const DashboardScreen());
    } else {
      _go(const BusinessSetupScreen());
    }
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(pageBuilder: (_, __, ___) => screen, transitionDuration: const Duration(milliseconds: 400), transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child)),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.orange, AppColors.brown, AppColors.brownDark])),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))]),
                child: const Icon(Icons.spa_rounded, size: 48, color: AppColors.orange),
              ),
              const SizedBox(height: 20),
              Text('SpiceDesk', style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Business Suite', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              Text('Built by Shahid Singh', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
              const SizedBox(height: 40),
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)))),
            ]),
          ),
        ),
      ),
    );
  }
}

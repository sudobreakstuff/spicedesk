import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/glass_theme.dart';
import '../setup/business_setup_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _bio = false;

  @override
  void initState() { super.initState(); context.read<AuthProvider>().isBiometricsAvailable().then((v) { if (mounted) setState(() => _bio = v); }); }
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    final ap = context.read<AuthProvider>();
    if (await ap.signInWithEmail(email: _email.text.trim(), password: _password.text)) { _after(); }
  }

  Future<void> _google() async { if (await context.read<AuthProvider>().signInWithGoogle()) _after(); }
  Future<void> _biometric() async { if (await context.read<AuthProvider>().signInWithBiometrics()) _after(); }

  Future<void> _after() async {
    final bp = context.read<BusinessProvider>(); await bp.loadBusiness();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => bp.hasBusiness ? const DashboardScreen() : const BusinessSetupScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext c) {
    final ap = context.watch<AuthProvider>();
    final isDark = c.isGlassDark;
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 40),
          Container(width: 56, height: 56, decoration: BoxDecoration(color: GlassColors.primary, borderRadius: BorderRadius.circular(14)), child: const Center(child: Text('SD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFFFFFFF))))),
          const SizedBox(height: 18),
          Text('Welcome back', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.glassText)),
          const SizedBox(height: 4),
          Text('Sign in to SpiceDesk', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.glassText2)),
          const SizedBox(height: 32),
          if (ap.error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: GlassColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(ap.error!, style: const TextStyle(color: GlassColors.error, fontSize: 13))),
          CupertinoTextFormFieldRow(controller: _email, placeholder: 'Email', keyboardType: TextInputType.emailAddress, style: TextStyle(fontSize: 15, color: c.glassText)),
          const SizedBox(height: 12),
          CupertinoTextFormFieldRow(controller: _password, placeholder: 'Password', obscureText: true, style: TextStyle(fontSize: 15, color: c.glassText)),
          const SizedBox(height: 22),
          CupertinoButton.filled(onPressed: ap.loading ? null : _signIn, child: ap.loading ? const CupertinoActivityIndicator() : const Text('Sign In')),
          const SizedBox(height: 14),
          CupertinoButton(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFFFFFFFF), shape: BoxShape.circle, border: Border.all(color: GlassColors.lightBorder)), child: const Center(child: Text('G', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlassColors.error)))), const SizedBox(width: 8), const Text('Continue with Google')]), onPressed: ap.loading ? null : _google),
          if (_bio) CupertinoButton(child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.lock_shield, size: 18), SizedBox(width: 8), Text('Biometrics')]), onPressed: ap.loading ? null : _biometric),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('No account? ', style: TextStyle(fontSize: 13, color: c.glassText2)),
            GestureDetector(onTap: () => Navigator.push(c, CupertinoPageRoute(builder: (_) => const _SignUp())), child: const Text('Sign Up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GlassColors.primary))),
          ]),
          const SizedBox(height: 40),
          Text('Built by Shahid Singh', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: c.glassText3)),
        ]))),
      ),
    );
  }
}

class _SignUp extends StatefulWidget { const _SignUp(); @override
  State<_SignUp> createState() => _SignUpState(); }

class _SignUpState extends State<_SignUp> {
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController(), _cpw = TextEditingController();
  @override void dispose() { _name.dispose(); _email.dispose(); _pw.dispose(); _cpw.dispose(); super.dispose(); }

  Future<void> _signUp() async {
    if (await context.read<AuthProvider>().signUpWithEmail(name: _name.text.trim(), email: _email.text.trim(), password: _pw.text)) {
      if (mounted) Navigator.of(context).pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final ap = context.watch<AuthProvider>();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Sign Up'), leading: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.back), onPressed: () => Navigator.pop(c))),
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 8),
        if (ap.error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: GlassColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(ap.error!, style: const TextStyle(color: GlassColors.error, fontSize: 13))),
        CupertinoTextFormFieldRow(controller: _name, placeholder: 'Full Name', style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _email, placeholder: 'Email', keyboardType: TextInputType.emailAddress, style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _pw, placeholder: 'Password', obscureText: true, style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _cpw, placeholder: 'Confirm Password', obscureText: true, style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 22),
        CupertinoButton.filled(onPressed: ap.loading ? null : _signUp, child: ap.loading ? const CupertinoActivityIndicator() : const Text('Create Account')),
        const SizedBox(height: 30),
      ]))),
    );
  }
}

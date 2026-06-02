import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/app_theme.dart';
import '../setup/business_setup_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController(), _form = GlobalKey<FormState>();
  bool _obscure = true, _hasBio = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().isBiometricsAvailable().then((v) { if (mounted) setState(() => _hasBio = v); });
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    final ap = context.read<AuthProvider>();
    if (await ap.signInWithEmail(email: _email.text.trim(), password: _password.text)) {
      await _afterAuth();
    }
  }

  Future<void> _google() async {
    if (await context.read<AuthProvider>().signInWithGoogle()) await _afterAuth();
  }

  Future<void> _bio() async {
    if (await context.read<AuthProvider>().signInWithBiometrics()) await _afterAuth();
  }

  Future<void> _afterAuth() async {
    final bp = context.read<BusinessProvider>();
    await bp.loadBusiness();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => bp.hasBusiness ? const DashboardScreen() : const BusinessSetupScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuthProvider>();
    final tm = context.watch<ThemeProvider>();
    final isDark = tm.isDark;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 40),
                Container(width: 56, height: 56, decoration: BoxDecoration(color: SpiceColors.primary, borderRadius: BorderRadius.circular(14)), child: const Center(child: Text('SD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)))),
                const SizedBox(height: 16),
                Text('Welcome back', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Sign in to SpiceDesk', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary)),
                const SizedBox(height: 32),
                if (ap.error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: SpiceColors.errorBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: SpiceColors.error.withValues(alpha: 0.2))), child: Row(children: [const Icon(Icons.error_outline, color: SpiceColors.error, size: 16), const SizedBox(width: 8), Expanded(child: Text(ap.error!, style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.error)))])),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)), style: TextStyle(fontSize: 14, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary), validator: (v) => v == null || !v.contains('@') ? 'Enter email' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _password, obscureText: _obscure, textInputAction: TextInputAction.done, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined, size: 18), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _obscure = !_obscure))), style: TextStyle(fontSize: 14, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary), validator: (v) => (v ?? '').isEmpty ? 'Enter password' : null, onFieldSubmitted: (_) => _signIn()),
                const SizedBox(height: 18),
                ElevatedButton(onPressed: ap.loading ? null : _signIn, child: ap.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In')),
                const SizedBox(height: 14),
                Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: SpiceColors.textTertiary, fontSize: 12))), Expanded(child: Divider())]),
                const SizedBox(height: 14),
                OutlinedButton.icon(onPressed: ap.loading ? null : _google, icon: Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: SpiceColors.cardBorder)), child: const Center(child: Text('G', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)))), label: const Text('Continue with Google')),
                if (_hasBio) ...[const SizedBox(height: 8), OutlinedButton.icon(onPressed: ap.loading ? null : _bio, icon: const Icon(Icons.fingerprint, size: 18), label: const Text('Biometrics'))],
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("No account? ", style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary)),
                  GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SignUp())) , child: Text('Sign Up', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.primary))),
                ]),
                const SizedBox(height: 32),
                Text('Built by Shahid Singh', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: SpiceColors.textTertiary, fontStyle: FontStyle.italic)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUp extends StatefulWidget {
  const _SignUp();
  @override
  State<_SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<_SignUp> {
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController(), _cpw = TextEditingController(), _form = GlobalKey<FormState>();
  bool _ob1 = true, _ob2 = true;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pw.dispose(); _cpw.dispose(); super.dispose(); }

  Future<void> _signUp() async {
    if (!_form.currentState!.validate()) return;
    if (await context.read<AuthProvider>().signUpWithEmail(name: _name.text.trim(), email: _email.text.trim(), password: _pw.text)) {
      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 28), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 16), IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context), alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
        const SizedBox(height: 8), Text('Create Account', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
        Text('Join SpiceDesk', style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary)), const SizedBox(height: 24),
        if (ap.error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(ap.error!, style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.error))),
        TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 10), TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !v.contains('@') ? 'Valid email' : null),
        const SizedBox(height: 10), TextFormField(controller: _pw, obscureText: _ob1, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(_ob1 ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _ob1 = !_ob1))), validator: (v) => (v ?? '').length < 6 ? 'Min 6 chars' : null),
        const SizedBox(height: 10), TextFormField(controller: _cpw, obscureText: _ob2, textInputAction: TextInputAction.done, decoration: InputDecoration(labelText: 'Confirm Password', suffixIcon: IconButton(icon: Icon(_ob2 ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _ob2 = !_ob2))), validator: (v) => v != _pw.text ? 'Passwords mismatch' : null, onFieldSubmitted: (_) => _signUp()),
        const SizedBox(height: 18), ElevatedButton(onPressed: ap.loading ? null : _signUp, child: ap.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Account')),
        const SizedBox(height: 14), OutlinedButton.icon(onPressed: ap.loading ? null : () async { if (await context.read<AuthProvider>().signInWithGoogle()) { if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false); }}, icon: Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: SpiceColors.cardBorder)), child: const Center(child: Text('G', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)))), label: const Text('Sign up with Google')),
        const SizedBox(height: 24),
      ]))))),
    );
  }
}

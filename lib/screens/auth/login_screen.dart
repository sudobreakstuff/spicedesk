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
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  void _checkBiometrics() async {
    final provider = context.read<AuthProvider>();
    final available = await provider.isBiometricsAvailable();
    if (mounted) setState(() => _biometricsAvailable = available);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _emailSignIn() async {
    if (!_form.currentState!.validate()) return;
    final ap = context.read<AuthProvider>();
    final ok = await ap.signInWithEmail(email: _email.text.trim(), password: _password.text);
    if (ok && mounted) await _afterAuth();
  }

  Future<void> _googleSignIn() async {
    final ap = context.read<AuthProvider>();
    final ok = await ap.signInWithGoogle();
    if (ok && mounted) await _afterAuth();
  }

  Future<void> _biometricSignIn() async {
    final ap = context.read<AuthProvider>();
    final ok = await ap.signInWithBiometrics();
    if (ok && mounted) await _afterAuth();
  }

  Future<void> _afterAuth() async {
    final bp = context.read<BusinessProvider>();
    await bp.loadBusiness();
    if (!mounted) return;
    if (bp.hasBusiness) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()), (r) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusinessSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final ap = context.watch<AuthProvider>();
    final isDark = tm.isDark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.spa_rounded, size: 56,
                      color: isDark ? AppColors.orange : AppColors.orange),
                  const SizedBox(height: 12),
                  Text('SpiceDesk', textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.brownDark)),
                  const SizedBox(height: 4),
                  Text('Business Suite', textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                  const SizedBox(height: 40),

                  if (ap.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ap.error!, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.red))),
                      ]),
                    ),

                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                    onFieldSubmitted: (_) => _emailSignIn(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: ap.loading ? null : _emailSignIn,
                    child: ap.loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or', style: GoogleFonts.poppins(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: ap.loading ? null : _googleSignIn,
                    icon: _googleIcon(),
                    label: const Text('Continue with Google'),
                  ),
                  if (_biometricsAvailable) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: ap.loading ? null : _biometricSignIn,
                      icon: const Icon(Icons.fingerprint, size: 22),
                      label: const Text('Sign in with Biometrics'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Don't have an account? ", style: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SignUpScreen())),
                      child: Text('Sign Up', style: GoogleFonts.poppins(color: AppColors.orange, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  Text('Built by Shahid Singh', textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
      child: const Center(child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red))),
    );
  }
}

class _SignUpScreen extends StatefulWidget {
  const _SignUpScreen();
  @override
  State<_SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<_SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure1 = true, _obscure2 = true;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_form.currentState!.validate()) return;
    final ap = context.read<AuthProvider>();
    final ok = await ap.signUpWithEmail(name: _name.text.trim(), email: _email.text.trim(), password: _password.text);
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final ap = context.watch<AuthProvider>();
    final isDark = tm.isDark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context), alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  Text('Create Account', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.brownDark)),
                  const SizedBox(height: 4),
                  Text('Join SpiceDesk', style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                  const SizedBox(height: 28),
                  if (ap.error != null)
                    Container(
                      padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(ap.error!, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.red)),
                    ),
                  TextFormField(
                    controller: _name, textInputAction: TextInputAction.next,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                    decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outline), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                    decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password, obscureText: _obscure1, textInputAction: TextInputAction.next,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                    decoration: InputDecoration(
                      labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure1 = !_obscure1)),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm, obscureText: _obscure2, textInputAction: TextInputAction.done,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure2 = !_obscure2)),
                    ),
                    validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                    onFieldSubmitted: (_) => _signUp(),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: ap.loading ? null : _signUp,
                    child: ap.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Account'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: ap.loading ? null : () async {
                      final ok = await ap.signInWithGoogle();
                      if (ok && mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false);
                    },
                    icon: Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                        child: const Center(child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)))),
                    label: const Text('Sign up with Google'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

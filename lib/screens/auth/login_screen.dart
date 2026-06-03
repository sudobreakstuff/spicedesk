import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../setup/business_setup_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _pw = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _hide = true;

  @override
  void dispose() { _email.dispose(); _pw.dispose(); super.dispose(); }

  Future<void> _after() async {
    final bp = context.read<BusinessProvider>();
    await bp.loadBusiness();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => bp.hasBusiness ? const DashboardScreen() : const BusinessSetupScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext c) {
    final ap = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 32),
                const Icon(Icons.spa, color: Colors.blue, size: 48),
                const SizedBox(height: 12),
                const Text('SpiceDesk', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('Sign in to continue', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 32),
                if (ap.error != null)
                  Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)), child: Text(ap.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || !v.contains('@') ? 'Enter email' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _pw, obscureText: _hide, textInputAction: TextInputAction.done, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide))), validator: (v) => (v ?? '').isEmpty ? 'Enter password' : null, onFieldSubmitted: (_) => _signIn()),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: ap.loading ? null : _signIn, child: ap.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In')),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: ap.loading ? null : _google, icon: const Icon(Icons.g_mobiledata, size: 22), label: const Text('Continue with Google')),
                if (!ap.loading) ...[
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    GestureDetector(onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const SignUpScreen())), child: const Text('Sign Up', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13))),
                  ]),
                ],
                const SizedBox(height: 32),
                const Text('Built by Shahid Singh', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().signInWithEmail(email: _email.text.trim(), password: _pw.text);
    if (ok) await _after();
  }

  Future<void> _google() async {
    final ok = await context.read<AuthProvider>().signInWithGoogle();
    if (ok) await _after();
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController(), _cpw = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pw.dispose(); _cpw.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    final ap = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (ap.error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text(ap.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
              TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _pw, obscureText: true, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined)), validator: (v) => (v ?? '').length < 6 ? 'Min 6 characters' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _cpw, obscureText: true, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outlined)), validator: (v) => v != _pw.text ? 'Passwords do not match' : null),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: ap.loading ? null : _signUp, child: ap.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Account')),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: ap.loading ? null : _googleSignUp, icon: const Icon(Icons.g_mobiledata, size: 22), label: const Text('Sign up with Google')),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().signUpWithEmail(name: _name.text.trim(), email: _email.text.trim(), password: _pw.text);
    if (ok && mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false);
  }

  Future<void> _googleSignUp() async {
    final ok = await context.read<AuthProvider>().signInWithGoogle();
    if (ok && mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const BusinessSetupScreen()), (r) => false);
  }
}

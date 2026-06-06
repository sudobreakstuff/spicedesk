import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).register(
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
            _nameCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Check your email to confirm.'),
            backgroundColor: SpiceColors.accent,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      final message = e.toString().replaceFirst('AuthException: ', '');
      if (mounted) setState(() => _error = message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A0A2E),
              Color(0xFF0D1117),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(seconds: 2),
                          builder: (_, value, child) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    SpiceColors.primary,
                                    Color(0xFFA78BFA),
                                    Color(0xFF6366F1),
                                  ],
                                  stops: [0.0, value, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: SpiceColors.primary.withAlpha(60),
                                    blurRadius: 24,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        Text(
                          'SpiceDesk',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Business Suite',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: SpiceColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: SpiceColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: SpiceColors.primary.withAlpha(40),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded,
                                  color: SpiceColors.primary, size: 12),
                              SizedBox(width: 6),
                              Text(
                                'Dedicated to Mum and Dad',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideY(
                        begin: 0.05, curve: Curves.easeOut),

                    SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        color: SpiceColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: SpiceColors.border),
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create Account',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Set up your workspace',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 24),
                          TextFormField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _emailFocus.requestFocus(),
                            validator: (v) =>
                                v?.isEmpty == true ? 'Enter your name' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                            validator: (v) {
                              if (v?.isEmpty == true) return 'Enter your email';
                              if (v != null && !v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outlined),
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _register(),
                            validator: (v) {
                              if (v?.isEmpty == true) return 'Enter a password';
                              if (v != null && v.length < 8) return 'Min 8 characters';
                              if (v != null && !v.contains(RegExp(r'[A-Z]'))) return 'Include an uppercase letter';
                              if (v != null && !v.contains(RegExp(r'[0-9]'))) return 'Include a number';
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SpiceColors.danger.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: SpiceColors.danger.withAlpha(60),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: SpiceColors.danger, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: SpiceColors.danger,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SpiceColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).fadeIn(
                        duration: 500.ms).slideY(
                        begin: 0.08, curve: Curves.easeOut),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: SpiceColors.primary,
                          ),
                          child: Text(
                            'Sign in',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ).animate(delay: 500.ms).fadeIn(),

                    SizedBox(height: 32),
                    Center(
                      child: Text(
                        'Made by Shahid Singh',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontSize: 11),
                      ),
                    ).animate(delay: 800.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

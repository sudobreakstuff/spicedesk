import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

class SpiceDeskApp extends ConsumerStatefulWidget {
  const SpiceDeskApp({super.key});

  @override
  ConsumerState<SpiceDeskApp> createState() => _SpiceDeskAppState();
}

class _SpiceDeskAppState extends ConsumerState<SpiceDeskApp> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _locked = false;
  bool _appLockEnabled = false;
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSecuritySettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _appLockEnabled = prefs.getBool('app_lock') ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isBackground = true;
    } else if (state == AppLifecycleState.resumed && _isBackground && _appLockEnabled) {
      _isBackground = false;
      _locked = true;
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock SpiceDesk to continue',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (mounted && authenticated) {
        setState(() => _locked = false);
      }
    } catch (_) {
      if (mounted) setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);
    final mode = ref.watch(themeModeProvider);

    if (_locked) {
      return MaterialApp(
        theme: theme,
        darkTheme: appTheme,
        themeMode: mode == AppTheme.paperLight ? ThemeMode.light : ThemeMode.dark,
        home: Scaffold(
          backgroundColor: SpiceColors.surface,
          body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline, size: 64, color: SpiceColors.primary),
              SizedBox(height: 24),
              Text('SpiceDesk is locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              SizedBox(height: 8),
              Text('Tap to unlock', style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: Icon(Icons.fingerprint),
                label: Text('Unlock'),
              ),
            ]),
          ),
        ),
      );
    }

    return MaterialApp.router(
      theme: theme,
      darkTheme: appTheme,
      themeMode: mode == AppTheme.paperLight ? ThemeMode.light : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'SpiceDesk',
    );
  }
}

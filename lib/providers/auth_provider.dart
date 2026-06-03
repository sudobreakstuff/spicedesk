import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/business.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, needsSetup }

class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  AuthProvider(this._auth) { _auth.addListener(_onChanged); }

  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _auth.isLoggedIn;
  String? get userId => _auth.userId;
  String? get userEmail => _auth.userEmail;

  void _onChanged() => notifyListeners();

  Future<void> checkAuthStatus({Business? business}) async {
    _loading = true; _error = null; notifyListeners();
    if (_auth.isLoggedIn) {
      _status = business != null ? AuthStatus.authenticated : AuthStatus.needsSetup;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    _loading = false; notifyListeners();
  }

  Future<bool> signUpWithEmail({required String email, required String password, required String name}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final r = await _auth.signUpWithEmail(email: email, password: password, name: name);
      if (r.user != null) { _status = AuthStatus.needsSetup; _loading = false; notifyListeners(); return true; }
      _error = 'Sign up failed'; _loading = false; notifyListeners(); return false;
    } catch (e) { _error = _msg(e.toString()); _loading = false; notifyListeners(); return false; }
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      await _auth.signInWithEmail(email: email, password: password);
      _loading = false; notifyListeners(); return true;
    } catch (e) { _error = _msg(e.toString()); _loading = false; notifyListeners(); return false; }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final ok = await _auth.signInWithGoogle();
      if (!ok) { _error = 'Google sign-in cancelled'; _loading = false; notifyListeners(); return false; }
      _loading = false; notifyListeners(); return true;
    } catch (e) { _error = _msg(e.toString()); _loading = false; notifyListeners(); return false; }
  }

  void setAuthState(AuthStatus s) { _status = s; notifyListeners(); }

  Future<void> signOut() async { await _auth.signOut(); _status = AuthStatus.unauthenticated; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }

  String _msg(String e) {
    if (e.contains('Invalid login')) return 'Wrong email or password';
    if (e.contains('Email not confirmed')) return 'Please confirm your email';
    if (e.contains('already registered')) return 'Account already exists';
    if (e.contains('network')) return 'Check your internet connection';
    return 'Something went wrong. Try again.';
  }

  @override
  void dispose() { _auth.removeListener(_onChanged); super.dispose(); }
}

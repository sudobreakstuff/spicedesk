import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/business.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, needsSetup }

class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  AuthProvider(this._auth) { _auth.addListener(() => notifyListeners()); }

  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _auth.isLoggedIn;
  String? get userId => _auth.userId;
  String? get userEmail => _auth.userEmail;

  void checkAuthStatus({Business? business}) {
    if (_auth.isLoggedIn) {
      _status = business != null ? AuthStatus.authenticated : AuthStatus.needsSetup;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signUpWithEmail({required String email, required String password, required String name}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final r = await _auth.signUpWithEmail(email: email, password: password, name: name);
      if (r.session != null) {
        _status = AuthStatus.needsSetup; _loading = false; notifyListeners(); return true;
      }
      _error = 'Check your email to confirm your account, then sign in.'; _loading = false; notifyListeners(); return false;
    } catch (e) { _error = _clean(e.toString()); _loading = false; notifyListeners(); return false; }
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      await _auth.signInWithEmail(email: email, password: password);
      _loading = false; notifyListeners(); return true;
    } catch (e) { _error = _clean(e.toString()); _loading = false; notifyListeners(); return false; }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }

  String _clean(String e) {
    if (e.contains('Invalid login')) return 'Wrong email or password.';
    if (e.contains('Email not confirmed')) return 'Please confirm your email first.';
    if (e.contains('already registered')) return 'This email is already registered.';
    if (e.contains('network') || e.contains('SocketException')) return 'No internet connection.';
    return 'Something went wrong. Try again.';
  }
}

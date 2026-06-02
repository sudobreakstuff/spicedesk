import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/business.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticated,
  needsSetup,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  AuthProvider(this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _authService.isLoggedIn;
  String? get userId => _authService.userId;
  String? get userEmail => _authService.userEmail;

  void _onAuthChanged() {
    notifyListeners();
  }

  Future<void> checkAuthStatus({Business? business}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (_authService.isLoggedIn) {
        if (business != null) {
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.needsSetup;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (response.user != null) {
        await _authService.saveCredentialsForBiometrics(
          email: email,
          password: password,
        );
        _status = AuthStatus.needsSetup;
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = 'Sign up failed. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseAuthError(e.toString());
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      await _authService.saveCredentialsForBiometrics(
        email: email,
        password: password,
      );

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseAuthError(e.toString());
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = 'Google sign-in was cancelled or failed.';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseAuthError(e.toString());
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithBiometrics() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.signInWithBiometrics();
      if (success) {
        _loading = false;
        notifyListeners();
        return true;
      }

      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> isBiometricsAvailable() async {
    return await _authService.isBiometricsAvailable();
  }

  void setAuthState(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseAuthError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (error.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}

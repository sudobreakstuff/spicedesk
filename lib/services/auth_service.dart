import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart' as app_models;

class AuthService extends ChangeNotifier {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  app_models.AppUser? _currentAppUser;
  app_models.AppUser? get currentAppUser => _currentAppUser;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => _client.auth.currentUser != null;
  String? get userId => _client.auth.currentUser?.id;
  String? get userEmail => _client.auth.currentUser?.email;

  bool get canUseGoogleNative => Platform.isAndroid || Platform.isIOS;
  bool get canUseBiometrics => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  AuthService(this._client)
      : _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']),
        _secureStorage = const FlutterSecureStorage();

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'full_name': name},
    );
    if (response.user != null) {
      await _secureStorage.write(key: 'auth_method', value: 'email');
      await _saveCredentials(email, password);
    }
    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await _secureStorage.write(key: 'auth_method', value: 'email');
      await _saveCredentials(email, password);
    }
    return response;
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (canUseGoogleNative) {
        return await _googleSignInNative();
      } else {
        return await _googleSignInOAuth();
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<bool> _googleSignInNative() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null || accessToken == null) return false;

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    await _secureStorage.write(key: 'auth_method', value: 'google');
    return true;
  }

  Future<bool> _googleSignInOAuth() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.shahidsingh.spicedesk://login-callback',
      );
      await _secureStorage.write(key: 'auth_method', value: 'google');
      return true;
    } catch (e) {
      debugPrint('Google OAuth error: $e');
      return false;
    }
  }

  Future<bool> signInWithBiometrics() async {
    try {
      if (!canUseBiometrics) return false;

      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to SpiceDesk',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (!authenticated) return false;

      final savedEmail = await _secureStorage.read(key: 'saved_email');
      final savedPassword = await _secureStorage.read(key: 'saved_password');

      if (savedEmail == null || savedPassword == null) return false;

      await _client.auth.signInWithPassword(
        email: savedEmail,
        password: savedPassword,
      );
      return true;
    } catch (e) {
      debugPrint('Biometric sign-in error: $e');
      return false;
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    await _secureStorage.write(key: 'saved_email', value: email);
    await _secureStorage.write(key: 'saved_password', value: password);
  }

  Future<bool> isBiometricsAvailable() async {
    if (!canUseBiometrics) return false;
    final authMethod = await _secureStorage.read(key: 'auth_method');
    final savedEmail = await _secureStorage.read(key: 'saved_email');
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      return authMethod == 'email' && savedEmail != null && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!canUseBiometrics) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    if (canUseGoogleNative) {
      try { await _googleSignIn.signOut(); } catch (_) {}
    }
    await _secureStorage.deleteAll();
    _currentAppUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final user = currentUser;
    if (user == null) return;
    final metadata = <String, dynamic>{};
    if (name != null) metadata['name'] = name;
    if (phone != null) metadata['phone'] = phone;
    await _client.auth.updateUser(UserAttributes(data: metadata));
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart' as app_models;

class AuthService extends ChangeNotifier {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  
  app_models.AppUser? _currentAppUser;
  app_models.AppUser? get currentAppUser => _currentAppUser;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => _client.auth.currentUser != null;
  String? get userId => _client.auth.currentUser?.id;
  String? get userEmail => _client.auth.currentUser?.email;

  AuthService(this._client)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        ),
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
    }

    return response;
  }

  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) return false;

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      await _secureStorage.write(key: 'auth_method', value: 'google');
      return true;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<bool> signInWithBiometrics() async {
    try {
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

  Future<void> saveCredentialsForBiometrics({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: 'saved_email', value: email);
    await _secureStorage.write(key: 'saved_password', value: password);
  }

  Future<bool> isBiometricsAvailable() async {
    final authMethod = await _secureStorage.read(key: 'auth_method');
    final savedEmail = await _secureStorage.read(key: 'saved_email');
    return authMethod == 'email' && savedEmail != null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _googleSignIn.signOut();
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

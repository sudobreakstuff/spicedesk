import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client;
  AuthService(this._client) {
    _client.auth.onAuthStateChange.listen((event) {
      notifyListeners();
    });
  }

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;

  Future<String?> tryGetUserId() async {
    if (currentUser != null) return currentUser!.id;
    try {
      await _client.auth.refreshSession();
      return currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({required String email, required String password, required String name}) async {
    final response = await _client.auth.signUp(email: email, password: password, data: {'name': name});
    notifyListeners();
    return response;
  }

  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    notifyListeners();
    return response;
  }

  Future<bool> signInWithGoogle() async {
    final result = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.shahidsingh.spicedesk://login-callback',
    );
    if (result) notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    final user = currentUser;
    if (user == null) return;
    await _client.auth.updateUser(UserAttributes(data: {'name': name, if (phone != null) 'phone': phone}));
    notifyListeners();
  }
}

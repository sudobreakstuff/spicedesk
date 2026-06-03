import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client;
  AuthService(this._client) {
    _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;

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

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }
}

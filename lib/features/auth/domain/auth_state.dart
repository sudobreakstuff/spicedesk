import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({required this.isAuthenticated, this.user});

  factory AuthState.initial() => AuthState(isAuthenticated: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _init();
  }

  void _init() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      state = AuthState(isAuthenticated: true, user: session.user);
    }
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = AuthState(
        isAuthenticated: session != null,
        user: session?.user,
      );
    });
  }

  Future<void> login(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> register(String email, String password, String name) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

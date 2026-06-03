import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient _client;
late final SharedPreferences _prefs;

void initSupabaseClient(SupabaseClient client, SharedPreferences prefs) {
  _client = client;
  _prefs = prefs;
}

SupabaseClient get supabase => _client;
SharedPreferences get prefs => _prefs;

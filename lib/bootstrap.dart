import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/supabase_client.dart';

const _defaultUrl = 'https://hxwlqmfwbsydzoiwcfyr.supabase.co';
const _defaultAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4d2xxbWZ3YnN5ZHpvaXdjZnlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1MDA3MTYsImV4cCI6MjA5NjA3NjcxNn0.QX8mK8oKQyfYweaAhsfApFHWTJPeuVzxcQPSNU2e5Tk';

Future<void> bootstrap() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultUrl),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: _defaultAnonKey),
  );

  final prefs = await SharedPreferences.getInstance();
  initSupabaseClient(Supabase.instance.client, prefs);
}

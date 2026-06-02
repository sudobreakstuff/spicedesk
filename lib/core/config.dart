class AppConfig {
  static const String appName = 'SpiceDesk';
  static const String appTagline = 'Built by Shahid Singh';
  static const String appVersion = '1.0.0';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://luafdcyodyxyqufphpsf.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1YWZkY3lvZHl4eXF1ZnBocHNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAxMjksImV4cCI6MjA5NTk5NjEyOX0.9r4s2OoTWWwPe_eii4QUSg09vzm0c9IOOQbsyY6ZNec',
  );

  static const String defaultCurrency = 'ZAR';
  static const String defaultCurrencySymbol = 'R';
  static const double defaultVatRate = 0.15;
  static const String defaultCountry = 'South Africa';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

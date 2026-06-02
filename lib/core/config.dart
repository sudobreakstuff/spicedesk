class AppConfig {
  static const String appName = 'SpiceDesk';
  static const String appTagline = 'Built by Shahid Singh';
  static const String appVersion = '1.0.0';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String defaultCurrency = 'ZAR';
  static const String defaultCurrencySymbol = 'R';
  static const double defaultVatRate = 0.15;
  static const String defaultCountry = 'South Africa';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

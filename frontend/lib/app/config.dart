/// Run-time settings passed with `--dart-define-from-file=config/dev.json`.
///
/// Only public values belong here (the publishable key is safe in the
/// browser; RLS protects the data). Never put secret keys in the frontend.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  static bool get isComplete => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}

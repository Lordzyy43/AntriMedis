import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get oauthRedirectUrl =>
      dotenv.env['SUPABASE_OAUTH_REDIRECT_URL'] ??
      'antrimedis://login-callback/';
}

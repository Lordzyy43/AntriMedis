import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.oauthRedirectUrl,
      data: {'full_name': fullName},
    );
  }

  Future<void> resendSignupConfirmation({required String email}) async {
    await _client.auth.resend(
      email: email,
      type: OtpType.signup,
      emailRedirectTo: SupabaseConfig.oauthRedirectUrl,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? Uri.base.origin : SupabaseConfig.oauthRedirectUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signInWithGoogle() async {
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : SupabaseConfig.oauthRedirectUrl,
      queryParams: const {'prompt': 'select_account'},
    );
    if (!launched) {
      throw const AuthException('Gagal membuka halaman login Google.');
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}

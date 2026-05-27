import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;

  User? _user;
  bool _isBootstrapping = true;
  bool _isLoading = false;
  bool _isPasswordRecovery = false;
  String? _error;
  String? _notice;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isLoading => _isLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get error => _error;
  String? get notice => _notice;

  void clearMessages() {
    _error = null;
    _notice = null;
    notifyListeners();
  }

  void bootstrap() {
    _user = _repository.currentUser;
    _isBootstrapping = false;
    _subscription = _repository.authStateChanges.listen((state) {
      _user = state.session?.user;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _notice = 'Silakan buat password baru untuk akun Anda.';
      }
      if (state.event == AuthChangeEvent.signedOut) {
        _isPasswordRecovery = false;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    return _run(
      () => _repository.signIn(email: email, password: password),
      successMessage: null,
    );
  }

  Future<bool> signUp(String fullName, String email, String password) async {
    return _run(
      () => _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      ),
      successMessage:
          'Akun berhasil dibuat. Jika diminta verifikasi, cek email Anda sebelum masuk.',
    );
  }

  Future<bool> signInWithGoogle() async {
    return _run(_repository.signInWithGoogle, successMessage: null);
  }

  Future<bool> sendPasswordReset(String email) async {
    return _run(
      () => _repository.sendPasswordReset(email),
      successMessage:
          'Link reset password sudah dikirim. Cek inbox atau folder spam email Anda.',
    );
  }

  Future<bool> updatePassword(String password) async {
    final ok = await _run(
      () => _repository.updatePassword(password),
      successMessage:
          'Password berhasil diperbarui. Gunakan password baru saat masuk berikutnya.',
    );
    if (ok) _isPasswordRecovery = false;
    return ok;
  }

  Future<void> signOut() => _repository.signOut();

  Future<bool> _run(
    Future<void> Function() action, {
    required String? successMessage,
  }) async {
    _isLoading = true;
    _error = null;
    _notice = null;
    notifyListeners();
    try {
      await action();
      _notice = successMessage;
      return true;
    } on AuthException catch (error) {
      _error = _friendlyAuthMessage(error.message);
      return false;
    } catch (error) {
      _error = 'Terjadi kendala. Coba lagi sebentar.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyAuthMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'Email atau password belum sesuai.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Cek inbox email Anda.';
    }
    if (normalized.contains('already registered') ||
        normalized.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan masuk atau reset password.';
    }
    if (normalized.contains('password should be') ||
        normalized.contains('weak password')) {
      return 'Password terlalu lemah. Gunakan minimal 8 karakter dengan huruf dan angka.';
    }
    if (normalized.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    }
    return message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

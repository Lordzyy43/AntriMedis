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
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void bootstrap() {
    _user = _repository.currentUser;
    _isBootstrapping = false;
    _subscription = _repository.authStateChanges.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> signUp(String fullName, String email, String password) async {
    return _run(
      () => _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() => _repository.signOut();

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'Terjadi kendala. Coba lagi sebentar.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

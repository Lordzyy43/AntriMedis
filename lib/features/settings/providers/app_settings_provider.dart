import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider({
    SecurityPinStore? securityPinStore,
  }) : _securityPinStore = securityPinStore ?? const SecureStorageSecurityPinStore();

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _themeModeKey = 'theme_mode';

  final SecurityPinStore _securityPinStore;
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  ThemeMode _themeMode = ThemeMode.light;
  String? _pinHash;

  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  ThemeMode get themeMode => _themeMode;
  bool get securityEnabled => _pinHash != null;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingSeenKey) ?? false;
    _themeMode = _themeModeFromString(prefs.getString(_themeModeKey));
    _pinHash = await _securityPinStore.readPinHash();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setSecurityPin(String pin) async {
    final hash = _hash(pin);
    await _securityPinStore.writePinHash(hash);
    _pinHash = hash;
    notifyListeners();
  }

  Future<void> clearSecurityPin() async {
    await _securityPinStore.clearPinHash();
    _pinHash = null;
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (!securityEnabled) return true;
    return _hash(pin) == _pinHash;
  }

  String _hash(String value) {
    return sha256.convert(utf8.encode('antrimedis:$value')).toString();
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }
}

abstract class SecurityPinStore {
  const SecurityPinStore();

  Future<String?> readPinHash();
  Future<void> writePinHash(String hash);
  Future<void> clearPinHash();
}

class SecureStorageSecurityPinStore implements SecurityPinStore {
  const SecureStorageSecurityPinStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'security_pin_hash';

  @override
  Future<String?> readPinHash() {
    return _storage.read(key: _key);
  }

  @override
  Future<void> writePinHash(String hash) {
    return _storage.write(key: _key, value: hash);
  }

  @override
  Future<void> clearPinHash() {
    return _storage.delete(key: _key);
  }
}

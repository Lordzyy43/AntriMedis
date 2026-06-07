import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _themeModeKey = 'theme_mode';
  static const _securityEnabledKey = 'security_enabled';
  static const _securityHashKey = 'security_pin_hash';

  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _securityEnabled = false;
  String? _pinHash;

  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  ThemeMode get themeMode => _themeMode;
  bool get securityEnabled => _securityEnabled && _pinHash != null;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingSeenKey) ?? false;
    _themeMode = _themeModeFromString(prefs.getString(_themeModeKey));
    _securityEnabled = prefs.getBool(_securityEnabledKey) ?? false;
    _pinHash = prefs.getString(_securityHashKey);
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
    final prefs = await SharedPreferences.getInstance();
    _pinHash = _hash(pin);
    _securityEnabled = true;
    await prefs.setString(_securityHashKey, _pinHash!);
    await prefs.setBool(_securityEnabledKey, true);
    notifyListeners();
  }

  Future<void> clearSecurityPin() async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = null;
    _securityEnabled = false;
    await prefs.remove(_securityHashKey);
    await prefs.setBool(_securityEnabledKey, false);
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

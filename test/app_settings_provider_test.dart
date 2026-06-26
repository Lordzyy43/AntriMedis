import 'package:antrimedis/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppSettingsProvider stores security PIN outside shared preferences', () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_seen': true,
      'theme_mode': 'dark',
    });

    final store = _FakeSecurityPinStore();
    final provider = AppSettingsProvider(securityPinStore: store);

    await provider.load();

    expect(provider.hasSeenOnboarding, isTrue);
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.securityEnabled, isFalse);

    await provider.setSecurityPin('123456');

    expect(provider.securityEnabled, isTrue);
    expect(provider.verifyPin('123456'), isTrue);
    expect(provider.verifyPin('000000'), isFalse);
    expect(store.savedHash, isNotNull);
    expect(store.savedHash, isNot('123456'));

    await provider.clearSecurityPin();

    expect(provider.securityEnabled, isFalse);
    expect(provider.verifyPin('123456'), isTrue);
    expect(store.savedHash, isNull);
  });
}

class _FakeSecurityPinStore extends SecurityPinStore {
  String? savedHash;

  @override
  Future<void> clearPinHash() async {
    savedHash = null;
  }

  @override
  Future<String?> readPinHash() async => savedHash;

  @override
  Future<void> writePinHash(String hash) async {
    savedHash = hash;
  }
}

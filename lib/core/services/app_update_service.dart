import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService();

  static final AppUpdateService instance = AppUpdateService();

  StreamSubscription<InstallStatus>? _installSubscription;

  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!isSupported) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (_) {
      return null;
    }
  }

  Future<bool> startFlexibleUpdate() async {
    if (!isSupported) return false;
    try {
      await _installSubscription?.cancel();
      _installSubscription = InAppUpdate.installUpdateListener.listen(
        (status) async {
          if (status != InstallStatus.downloaded) return;
          try {
            await InAppUpdate.completeFlexibleUpdate();
          } finally {
            await _installSubscription?.cancel();
            _installSubscription = null;
          }
        },
      );
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.userDeniedUpdate ||
          result == AppUpdateResult.inAppUpdateFailed) {
        await _installSubscription?.cancel();
        _installSubscription = null;
        return false;
      }
      return true;
    } catch (_) {
      await _installSubscription?.cancel();
      _installSubscription = null;
      return false;
    }
  }

  Future<bool> startImmediateUpdate() async {
    if (!isSupported) return false;
    try {
      await InAppUpdate.performImmediateUpdate();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeFlexibleUpdate() async {
    if (!isSupported) return false;
    try {
      await InAppUpdate.completeFlexibleUpdate();
      await _installSubscription?.cancel();
      _installSubscription = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    await _installSubscription?.cancel();
    _installSubscription = null;
  }
}

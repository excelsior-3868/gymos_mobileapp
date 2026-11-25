import 'dart:io';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

class AppConfig {
  static const int port = 5001;

  // Change this if pointing to a remote staging/production domain:
  static String? customOrigin;

  /// Build environment: local | staging | production (--dart-define APP_ENV).
  static const String env = String.fromEnvironment('APP_ENV', defaultValue: 'local');
  static bool get isProduction => env == 'production';

  static Future<void> init() async {
    // Production builds are pinned to the baked-in API_ORIGIN; the saved
    // override is a tester convenience and is ignored there.
    if (isProduction) {
      customOrigin = null;
      return;
    }
    final saved = await StorageService.getServerUrl();
    if (saved != null && saved.trim().isNotEmpty) {
      customOrigin = saved.trim();
    }
  }

  static Future<void> updateOrigin(String url) async {
    if (isProduction) return;
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'/api$'), '');
    customOrigin = clean;
    await StorageService.setServerUrl(clean);
  }

  static String get apiOrigin {
    if (customOrigin != null && customOrigin!.isNotEmpty) {
      return customOrigin!.replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'/api$'), '');
    }
    const envOrigin = String.fromEnvironment('API_ORIGIN');
    if (envOrigin.isNotEmpty) {
      return envOrigin.replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'/api$'), '');
    }
    const useLocalhost = bool.fromEnvironment('USE_LOCALHOST', defaultValue: false);
    if (useLocalhost || kIsWeb) {
      return 'http://127.0.0.1:$port';
    }
    if (Platform.isAndroid) {
      // Android emulator: 10.0.2.2 always maps to the host PC, no 'adb reverse' needed.
      // For a real phone over USB, use `--dart-define=API_ORIGIN=http://127.0.0.1:5001`
      // with 'adb reverse tcp:5001 tcp:5001', or set the server URL in the login dialog.
      return 'http://10.0.2.2:$port';
    }
    return 'http://127.0.0.1:$port';
  }

  static String get apiUrl => '$apiOrigin/api';

  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$apiOrigin$cleanPath';
  }
}

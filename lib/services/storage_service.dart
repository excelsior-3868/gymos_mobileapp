import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyToken = 'gymos_member_token';
  static const String keyServerUrl = 'gymos_server_url';
  static const String keyBiometricEnabled = 'gymos_biometric_enabled';
  static const String keyBiometricPrompted = 'gymos_biometric_prompted';
  static const String keySpotlightSeen = 'gymos_spotlight_seen_key';
  static const String _keyBioUsername = 'gymos_bio_username';
  static const String _keyBioPassword = 'gymos_bio_password';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<String?> getServerUrl() async => getString(keyServerUrl);
  static Future<void> setServerUrl(String url) async => setString(keyServerUrl, url);

  static Future<String?> getSpotlightSeenKey() async => getString(keySpotlightSeen);
  static Future<void> setSpotlightSeenKey(String value) async => setString(keySpotlightSeen, value);

  static Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyBiometricEnabled) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyBiometricEnabled, enabled);
  }

  static Future<bool> getBiometricPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyBiometricPrompted) ?? false;
  }

  static Future<void> setBiometricPrompted(bool prompted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyBiometricPrompted, prompted);
  }

  static Future<void> saveBiometricCredentials({
    required String username,
    required String password,
  }) async {
    await _secure.write(key: _keyBioUsername, value: username);
    await _secure.write(key: _keyBioPassword, value: password);
  }

  static Future<({String username, String password})?> getBiometricCredentials() async {
    try {
      final username = await _secure.read(key: _keyBioUsername);
      final password = await _secure.read(key: _keyBioPassword);
      if (username != null && username.isNotEmpty && password != null && password.isNotEmpty) {
        return (username: username, password: password);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearBiometricCredentials() async {
    try {
      await _secure.delete(key: _keyBioUsername);
      await _secure.delete(key: _keyBioPassword);
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String keyMustChange = 'gymos_must_change_password';
  static const String keyRegNumber = 'gymos_saved_reg_number';

  bool _isReady = false;
  String? _token;
  bool _mustChangePassword = false;
  String? _savedRegistrationNumber;

  bool get isReady => _isReady;
  String? get token => _token;
  bool get isSignedIn => _token != null && _token!.isNotEmpty;
  bool get mustChangePassword => _mustChangePassword;
  String? get savedRegistrationNumber => _savedRegistrationNumber;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    ApiService.onUnauthorized = () {
      signOut(revoke: false);
    };

    final saved = await StorageService.getToken();
    final mustChange = await StorageService.getString(keyMustChange);
    final savedReg = await StorageService.getString(keyRegNumber);

    _mustChangePassword = mustChange == 'true';
    _savedRegistrationNumber = savedReg;

    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      ApiService.setToken(saved);
    }
    _isReady = true;
    notifyListeners();
  }

  Future<bool> login({
    required String registrationNumber,
    required String password,
  }) async {
    final cleanReg = registrationNumber.trim().toUpperCase();
    final cleanPass = password.trim();

    final res = await ApiService.post('/portal/auth/login', body: {
      'username': cleanReg,
      'password': cleanPass,
    });

    final token = res['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException('Invalid token received from server');
    }

    final mustChange = res['mustChangePassword'] == true;
    _mustChangePassword = mustChange;
    _savedRegistrationNumber = cleanReg;

    await StorageService.setString(keyMustChange, mustChange ? 'true' : 'false');
    await StorageService.setString(keyRegNumber, cleanReg);
    await signIn(token);

    return mustChange;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await ApiService.post('/portal/auth/change-password', body: {
      'currentPassword': currentPassword.trim(),
      'newPassword': newPassword.trim(),
    });

    _mustChangePassword = res['mustChangePassword'] == true;
    await StorageService.setString(keyMustChange, 'false');
    // The server revokes all older tokens on password change and returns a fresh one.
    final newToken = res['token'];
    if (newToken is String && newToken.isNotEmpty) {
      await signIn(newToken);
    }
    notifyListeners();
  }

  Future<void> signIn(String token) async {
    _token = token;
    ApiService.setToken(token);
    await StorageService.setToken(token);
    notifyListeners();
  }

  /// [revoke] asks the server to invalidate the session. Skipped when the server
  /// already rejected the token (401), to avoid a pointless/looping call.
  Future<void> signOut({bool revoke = true}) async {
    if (revoke && _token != null) {
      try {
        await ApiService.post('/portal/auth/logout', body: {});
      } catch (_) {
        // Best effort: still sign out locally if offline.
      }
    }
    _token = null;
    _mustChangePassword = false;
    ApiService.setToken(null);
    await StorageService.removeToken();
    await StorageService.remove(keyMustChange);
    notifyListeners();
  }
}

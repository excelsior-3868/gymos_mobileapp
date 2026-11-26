import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String keyMustChange = 'gymos_must_change_password';
  static const String keyRegNumber = 'gymos_saved_reg_number';

  bool _isReady = false;
  String? _token;
  bool _mustChangePassword = false;
  String? _savedRegistrationNumber;
  String? _sessionPassword;

  bool _biometricSupported = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricPrompted = false;
  String _biometricLabel = 'Biometrics';

  /// True once the login spotlight (Member of the Month + notices) has been
  /// shown/dismissed for the current session. Reset on login() and signOut().
  bool spotlightShownThisSession = false;

  bool get isReady => _isReady;
  String? get token => _token;
  bool get isSignedIn => _token != null && _token!.isNotEmpty;
  bool get mustChangePassword => _mustChangePassword;
  String? get savedRegistrationNumber => _savedRegistrationNumber;

  bool get biometricSupported => _biometricSupported;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricPrompted => _biometricPrompted;
  String get biometricLabel => _biometricLabel;
  bool get hasSessionPassword => _sessionPassword != null && _sessionPassword!.isNotEmpty;

  /// True when the user is signed in (and past forced password change), the
  /// device supports biometrics, and they haven't enabled or dismissed setup yet.
  bool get shouldPromptBiometricSetup =>
      isSignedIn &&
      !mustChangePassword &&
      _biometricAvailable &&
      !_biometricEnabled &&
      !_biometricPrompted;

  /// True when biometric login can be offered on the login screen.
  bool get canLoginWithBiometrics => _biometricAvailable && _biometricEnabled;

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
      PushNotificationService.registerForMember();
    }

    await _loadBiometricState();

    _isReady = true;
    notifyListeners();
  }

  Future<void> _loadBiometricState() async {
    _biometricSupported = await BiometricService.isDeviceSupported();
    _biometricAvailable = await BiometricService.isAvailable();
    if (_biometricAvailable) {
      _biometricLabel = await BiometricService.getBiometricLabel();
    }
    _biometricPrompted = await StorageService.getBiometricPrompted();
    final storedEnabled = await StorageService.getBiometricEnabled();
    if (storedEnabled) {
      final creds = await StorageService.getBiometricCredentials();
      if (creds != null) {
        _biometricEnabled = true;
      } else {
        _biometricEnabled = false;
        await StorageService.setBiometricEnabled(false);
      }
    } else {
      _biometricEnabled = false;
    }
  }

  Future<void> refreshBiometricStatus() async {
    await _loadBiometricState();
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
    _sessionPassword = cleanPass;
    spotlightShownThisSession = false;

    // Sync or reset biometric credentials if a different account logs in.
    final existingCreds = await StorageService.getBiometricCredentials();
    if (_biometricEnabled && existingCreds != null) {
      if (existingCreds.username.toUpperCase() != cleanReg) {
        await StorageService.clearBiometricCredentials();
        await StorageService.setBiometricEnabled(false);
        await StorageService.setBiometricPrompted(false);
        _biometricEnabled = false;
        _biometricPrompted = false;
      } else {
        await StorageService.saveBiometricCredentials(
          username: cleanReg,
          password: cleanPass,
        );
      }
    }

    await StorageService.setString(keyMustChange, mustChange ? 'true' : 'false');
    await StorageService.setString(keyRegNumber, cleanReg);
    await signIn(token);

    return mustChange;
  }

  /// Authenticates via biometrics and logs in using securely stored credentials.
  /// Returns true if login succeeded, false if the user cancelled the prompt.
  Future<bool> loginWithBiometrics() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      throw ApiException('$_biometricLabel login is not set up.');
    }

    final authResult = await BiometricService.authenticate(
      reason: 'Log in to your member account',
    );
    if (!authResult.success) {
      if (authResult.cancelled) return false;
      throw ApiException(authResult.error ?? '$_biometricLabel authentication failed.');
    }

    final creds = await StorageService.getBiometricCredentials();
    if (creds == null) {
      await disableBiometric();
      throw ApiException(
        'Saved $_biometricLabel credentials not found. Please log in with your password.',
      );
    }

    await login(
      registrationNumber: creds.username,
      password: creds.password,
    );
    return true;
  }

  /// Verifies identity via biometrics and saves credentials in secure storage.
  /// If [password] is supplied (e.g. when the user was already signed in before
  /// enabling biometrics), it is verified against the server first.
  Future<BiometricAuthResult> enableBiometric({
    String? username,
    String? password,
  }) async {
    if (!_biometricAvailable) {
      return const BiometricAuthResult(
        success: false,
        error: 'Biometric authentication is not available on this device.',
      );
    }

    final cleanUser = (username ?? _savedRegistrationNumber)?.trim().toUpperCase() ?? '';
    final cleanPass = (password ?? _sessionPassword)?.trim() ?? '';

    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      return BiometricAuthResult(
        success: false,
        error: 'Please enter your password to enable $_biometricLabel login.',
      );
    }

    // Whenever a password is explicitly provided, verify it against the server
    // before storing so biometric login is guaranteed to work.
    if (password != null && password.trim().isNotEmpty) {
      final res = await ApiService.post('/portal/auth/login', body: {
        'username': cleanUser,
        'password': cleanPass,
      });
      final newToken = res['token']?.toString();
      if (newToken != null && newToken.isNotEmpty) {
        await signIn(newToken);
      }
    }

    final result = await BiometricService.authenticate(
      reason: 'Verify your identity to enable $_biometricLabel login',
    );

    if (result.success) {
      await StorageService.saveBiometricCredentials(
        username: cleanUser,
        password: cleanPass,
      );
      await StorageService.setBiometricEnabled(true);
      await StorageService.setBiometricPrompted(true);
      _savedRegistrationNumber = cleanUser;
      _sessionPassword = cleanPass;
      _biometricEnabled = true;
      _biometricPrompted = true;
      await StorageService.setString(keyRegNumber, cleanUser);
      notifyListeners();
    }

    return result;
  }

  Future<void> disableBiometric() async {
    await StorageService.clearBiometricCredentials();
    await StorageService.setBiometricEnabled(false);
    _biometricEnabled = false;
    notifyListeners();
  }

  Future<void> dismissBiometricSetup() async {
    await StorageService.setBiometricPrompted(true);
    _biometricPrompted = true;
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final cleanNew = newPassword.trim();
    final res = await ApiService.post('/portal/auth/change-password', body: {
      'currentPassword': currentPassword.trim(),
      'newPassword': cleanNew,
    });

    _mustChangePassword = res['mustChangePassword'] == true;
    _sessionPassword = cleanNew;
    await StorageService.setString(keyMustChange, 'false');

    if (_biometricEnabled && _savedRegistrationNumber != null && _savedRegistrationNumber!.isNotEmpty) {
      await StorageService.saveBiometricCredentials(
        username: _savedRegistrationNumber!,
        password: cleanNew,
      );
    }

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
    PushNotificationService.registerForMember();
    notifyListeners();
  }

  /// [revoke] asks the server to invalidate the session. Skipped when the server
  /// already rejected the token (401), to avoid a pointless/looping call.
  Future<void> signOut({bool revoke = true}) async {
    if (revoke && _token != null) {
      await PushNotificationService.unregisterForMember();
      try {
        await ApiService.post('/portal/auth/logout', body: {});
      } catch (_) {
        // Best effort: still sign out locally if offline.
      }
    }
    _token = null;
    _mustChangePassword = false;
    _sessionPassword = null;
    spotlightShownThisSession = false;
    ApiService.setToken(null);
    await StorageService.removeToken();
    await StorageService.remove(keyMustChange);
    notifyListeners();
  }
}

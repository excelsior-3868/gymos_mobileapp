import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool success;
  final String? error;
  final bool cancelled;

  const BiometricAuthResult({
    required this.success,
    this.error,
    this.cancelled = false,
  });
}

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device has biometric hardware (even if not yet enrolled).
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the device has biometric hardware and at least one
  /// biometric (fingerprint / Face ID) is enrolled.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns a user-facing label such as "Face ID", "Fingerprint", or "Biometrics".
  static Future<String> getBiometricLabel() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (Platform.isIOS) {
        if (types.contains(BiometricType.face)) return 'Face ID';
        if (types.contains(BiometricType.fingerprint)) return 'Touch ID';
      }
      if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
      if (types.contains(BiometricType.face)) return 'Face ID';
    } catch (_) {}
    return 'Biometrics';
  }

  /// Triggers the native biometric authentication prompt.
  static Future<BiometricAuthResult> authenticate({
    required String reason,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return BiometricAuthResult(success: ok, cancelled: !ok);
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notEnrolled:
          return const BiometricAuthResult(
            success: false,
            error: 'No biometrics are enrolled on this device. Set up Fingerprint or Face ID in device settings first.',
          );
        case auth_error.notAvailable:
        case auth_error.passcodeNotSet:
          return const BiometricAuthResult(
            success: false,
            error: 'Biometric authentication is not available on this device.',
          );
        case auth_error.lockedOut:
          return const BiometricAuthResult(
            success: false,
            error: 'Too many failed attempts. Please try again shortly or log in with your password.',
          );
        case auth_error.permanentlyLockedOut:
          return const BiometricAuthResult(
            success: false,
            error: 'Biometrics are locked. Unlock your device with your PIN/passcode first.',
          );
        default:
          return BiometricAuthResult(
            success: false,
            error: e.message ?? 'Biometric authentication failed.',
          );
      }
    } catch (_) {
      return const BiometricAuthResult(
        success: false,
        error: 'Biometric authentication failed.',
      );
    }
  }
}

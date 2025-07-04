import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      bool isAvailable = await _localAuth.canCheckBiometrics;
      bool hasHardware = await _localAuth.isDeviceSupported();
      List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      return isAvailable && hasHardware && availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Check if user has enabled biometric authentication in settings
  Future<bool> isBiometricEnabled() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      print('Error checking biometric setting: $e');
      return false;
    }
  }

  // Check if biometric should be used (available + enabled)
  Future<bool> shouldUseBiometric() async {
    bool available = await isBiometricAvailable();
    bool enabled = await isBiometricEnabled();
    return available && enabled;
  }

  // Authenticate using biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to proceed',
  }) async {
    try {
      bool shouldUse = await shouldUseBiometric();
      if (!shouldUse) {
        return false;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return authenticated;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Get a user-friendly string describing available biometrics
  Future<String> getBiometricTypeName() async {
    try {
      List<BiometricType> biometrics = await getAvailableBiometrics();

      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      } else if (biometrics.contains(BiometricType.strong)) {
        return 'Biometric';
      } else if (biometrics.contains(BiometricType.weak)) {
        return 'Biometric';
      } else {
        return 'Biometric';
      }
    } catch (e) {
      print('Error getting biometric type name: $e');
      return 'Biometric';
    }
  }
}

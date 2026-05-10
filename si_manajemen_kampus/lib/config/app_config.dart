import 'package:flutter/foundation.dart';

/// App Configuration
/// Manage different environments: development, staging, production
class AppConfig {
  // Environment types
  static const String DEV = 'development';
  static const String STAGING = 'staging';
  static const String PROD = 'production';

  // Set current environment
  // Ubah ini sesuai environment Anda
  static const String currentEnv = DEV;

  // API Base URLs untuk berbagai environment
  static const Map<String, String> apiUrls = {
    // Using encoded spaces in URL path
    DEV: 'http://localhost:80/1_Project_Thesis/SI-manajemen-kampus/backend/api',

    // Alternative: Untuk testing lokal dengan IP address
    // DEV: 'http://192.168.1.100/SI%20manajemen%20kampus/backend/api',
    STAGING: 'https://staging.yourdomain.com/api',
    PROD: 'https://yourdomain.com/api',
  };

  static const String _androidEmulatorDevUrl =
      'http://10.0.2.2:80/1_Project_Thesis/SI-manajemen-kampus/backend/api';

  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  /// Get API Base URL berdasarkan environment
  static String getApiUrl() {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (currentEnv != DEV) {
      return apiUrls[currentEnv] ?? apiUrls[DEV]!;
    }

    if (kIsWeb) {
      return apiUrls[DEV]!;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorDevUrl;
    }

    return apiUrls[currentEnv] ?? apiUrls[DEV]!;
  }

  /// Check if production
  static bool isProduction() {
    return currentEnv == PROD;
  }

  /// Check if development
  static bool isDevelopment() {
    return currentEnv == DEV;
  }

  /// Get debug mode status
  static bool get debugMode {
    return isDevelopment();
  }

  /// Get HTTP timeout
  static Duration get httpTimeout {
    // Lebih lama untuk production
    return isProduction()
        ? const Duration(seconds: 30)
        : const Duration(seconds: 30);
  }

  /// Get SSL verification setting
  static bool get verifySslCertificate {
    // Jangan verify SSL di development
    return isProduction();
  }
}

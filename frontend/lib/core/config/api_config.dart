import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// The base URL for the Go backend API.
  /// 
  /// - Use 'http://localhost:8080' for iOS Simulators and Web.
  /// - Use 'http://10.0.2.2:8080' for Android Emulators.
  /// - Use your machine's local IP (e.g., 'http://192.168.1.5:8080') for physical devices.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    
    if (Platform.isAndroid) {
      // Using localhost because we've enabled 'adb reverse tcp:8080 tcp:8080'
      // This works for both Emulator (with 10.0.2.2) and Physical Device (with adb reverse)
      return 'http://localhost:8080';
    }
    
    return 'http://localhost:8080';
  }
}

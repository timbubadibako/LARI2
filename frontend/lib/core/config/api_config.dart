import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dev/dev_providers.dart';

class ApiConfig {
  static const String hfUrl = 'https://chivasy1-lari2.hf.space';
  static const String tunnelUrl = 'https://xvcs1ml0-8080.asse.devtunnels.ms';
  static const String localUrl = 'http://localhost:8080';

  static String getBaseUrl(Ref ref) {
    if (kReleaseMode) return hfUrl;
    
    final isLocal = ref.watch(localBackendActiveProvider);
    if (isLocal) {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://localhost:8080'; // Menggunakan localhost + adb reverse untuk HP Asli
      }
      return localUrl;
    }
    return tunnelUrl;
  }
}

final baseUrlProvider = Provider<String>((ref) {
  if (kReleaseMode) return ApiConfig.hfUrl;
  
  final isLocal = ref.watch(localBackendActiveProvider);
  if (isLocal) {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://localhost:8080'; // Menggunakan localhost + adb reverse untuk HP Asli
    }
    return ApiConfig.localUrl;
  }
  return ApiConfig.tunnelUrl;
});

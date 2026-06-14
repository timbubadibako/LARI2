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
    
    // 🔥 TUNNEL PRIORITY: Use tunnel if available, fallback to localhost
    // We use tunnelUrl for physical devices testing via devtunnels
    const url = tunnelUrl; 
    debugPrint('API_CONFIG: Using base URL: $url');
    return url;
  }
}

final baseUrlProvider = Provider<String>((ref) {
  if (kReleaseMode) return ApiConfig.hfUrl;
  
  // Default to tunnel for dev, change to localUrl if testing on emulator only
  return ApiConfig.tunnelUrl;
});

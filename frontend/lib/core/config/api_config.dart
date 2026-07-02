import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiConfig {
  static const String hfUrl = 'https://chivasy1-lari2.hf.space';
  static const String tunnelUrl = 'https://xvcs1ml0-8080.asse.devtunnels.ms';
  static const String localUrl = 'http://localhost:8080';

  static String getBaseUrl(Ref ref) {
    return hfUrl; // ALWAYS use HF Backend for field testing
  }
}

final baseUrlProvider = Provider<String>((ref) {
  return ApiConfig.hfUrl; // ALWAYS use HF Backend for field testing
});

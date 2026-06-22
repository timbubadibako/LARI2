import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'shared_preferences_provider.dart';

class AuthInterceptorClient extends http.BaseClient {
  final http.Client _inner;
  final Ref _ref;

  AuthInterceptorClient(this._inner, this._ref);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final token = prefs.getString('auth.jwt_token');
    
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}

final httpClientProvider = Provider<http.Client>((ref) {
  final innerClient = http.Client();
  ref.onDispose(() => innerClient.close());
  return AuthInterceptorClient(innerClient, ref);
});

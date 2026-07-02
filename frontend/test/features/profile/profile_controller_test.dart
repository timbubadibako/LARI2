import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lari_lari/core/services/http_client_provider.dart';
import 'package:lari_lari/features/profile/application/profile_controller.dart';
import 'package:lari_lari/features/auth/application/auth_controller.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockCurrentUserSessionNotifier extends CurrentUserSessionNotifier {
  @override
  String? build() => 'test-user-id';
}

class UriFake extends Fake implements Uri {}

void main() {
  late MockHttpClient mockClient;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(UriFake());
  });

  setUp(() {
    mockClient = MockHttpClient();
    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        currentUserSessionProvider.overrideWith(MockCurrentUserSessionNotifier.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProfileController', () {
    test('build fetches profile and returns UserProfile', () async {
      final profileJson = {
        'id': 'test-user-id',
        'display_name': 'Test Agent',
        'level': 5,
        'xp': 100,
        'public_profile': true,
        'ghost_mode': false,
      };

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(profileJson), 200),
      );

      final profile = await container.read(profileControllerProvider.future);

      expect(profile, isNotNull);
      expect(profile!.displayName, 'Test Agent');
      expect(profile.level, 5);
    });

    test('updateProfile sends PUT request and invalidates state', () async {
      when(() => mockClient.put(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"message": "success"}', 200));

      final controller = container.read(profileControllerProvider.notifier);
      final success = await controller.updateProfile(displayName: 'New Name');

      expect(success, true);
      verify(() => mockClient.put(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });
  });
}

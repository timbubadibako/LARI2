import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lari_lari/core/services/http_client_provider.dart';
import 'package:lari_lari/features/social/application/social_controller.dart';

class MockHttpClient extends Mock implements http.Client {}

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
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SocialController', () {
    test('fetchLeaderboard returns list of entries', () async {
      final leaderboardJson = [
        {
          'rank': 1,
          'user_id': 'user-1',
          'display_name': 'Agent 1',
          'territory_color': '#FF0000',
          'total_area_sqm': 5000.0,
        },
      ];

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(leaderboardJson), 200),
      );

      final controller = container.read(socialControllerProvider);
      final entries = await controller.fetchLeaderboard('KEC-GLOBAL');

      expect(entries.length, 1);
      expect(entries[0].displayName, 'Agent 1');
    });

    test('fetchRecentGraffiti returns list of graffiti', () async {
      final graffitiJson = [
        {
          'id': 'tag-1',
          'user_id': 'user-1',
          'display_name': 'Agent 1',
          'color': '#FF0000',
          'data': [[{'x': 0.0, 'y': 0.0}]],
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(graffitiJson), 200),
      );

      final controller = container.read(socialControllerProvider);
      final tags = await controller.fetchRecentGraffiti();

      expect(tags.length, 1);
      expect(tags[0].displayName, 'Agent 1');
    });

    test('postGraffiti returns true on success', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"message": "created"}', 201));

      final controller = container.read(socialControllerProvider);
      final success = await controller.postGraffiti('user-1', [[{'x': 10.0, 'y': 10.0}]]);

      expect(success, true);
    });
  });
}

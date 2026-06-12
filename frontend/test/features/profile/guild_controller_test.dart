import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lari_lari/core/services/http_client_provider.dart';
import 'package:lari_lari/features/profile/application/guild_controller.dart';
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

  group('GuildController', () {
    test('fetchGuilds returns list of guilds on success', () async {
      final guildsJson = [
        {'id': '1', 'name': 'Faction A', 'emblem_color': '#FF0000'},
        {'id': '2', 'name': 'Faction B', 'emblem_color': '#00FF00'},
      ];

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(guildsJson), 200),
      );

      final controller = container.read(guildControllerProvider);
      final guilds = await controller.fetchGuilds();

      expect(guilds.length, 2);
      expect(guilds[0].name, 'Faction A');
      expect(guilds[1].name, 'Faction B');
    });

    test('fetchDominion returns list of dominion entries on success', () async {
      final dominionJson = [
        {
          'guild_id': '1',
          'name': 'Faction A',
          'emblem_color': '#FF0000',
          'total_area': 1000.0,
          'percentage': 60.0,
        },
      ];

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(dominionJson), 200),
      );

      final controller = container.read(guildControllerProvider);
      final dominion = await controller.fetchDominion();

      expect(dominion.length, 1);
      expect(dominion[0].name, 'Faction A');
      expect(dominion[0].percentage, 60.0);
    });

    test('joinGuild returns true on success', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"message": "success"}', 200));

      final controller = container.read(guildControllerProvider);
      final success = await controller.joinGuild('guild-1');

      expect(success, true);
      verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('leaveGuild returns true on success', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"message": "success"}', 200));

      final controller = container.read(guildControllerProvider);
      final success = await controller.leaveGuild();

      expect(success, true);
    });
  });
}

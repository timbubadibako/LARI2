import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/lari_sync_service.dart';
import 'core/services/workout_storage_service.dart';
import 'core/services/shared_preferences_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_skill/flutter_skill.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Flutter Skills (Internal)
  FlutterSkillBinding.ensureInitialized();
  
  // 2. Initialize Storage (Hive)
  await Hive.initFlutter();
  final workoutBox = await Hive.openBox('workouts');
  final syncBox = await Hive.openBox('lari_sync_queue');
  final sharedPreferences = await SharedPreferences.getInstance();

  // 4. Create ProviderContainer with ALL overrides
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      workoutStorageServiceProvider.overrideWithValue(WorkoutStorageService(workoutBox)),
      syncBoxProvider.overrideWithValue(syncBox),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LariLariApp(),
    ),
  );
}

class LariLariApp extends ConsumerWidget {
  const LariLariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LARI',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

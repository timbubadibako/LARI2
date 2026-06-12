import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/sync_queue_service.dart';
import 'core/services/workout_storage_service.dart';
import 'dev/dev_providers.dart';
import 'dev/dev_menu.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/application/auth_controller.dart';
import 'package:flutter_skill/flutter_skill.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Flutter Skills (Internal)
  FlutterSkillBinding.ensureInitialized();
  
  // 2. Initialize Storage (Hive)
  await Hive.initFlutter();
  
  // Open boxes and wait for them to be ready
  final workoutBox = await Hive.openBox('workouts');
  final syncBox = await Hive.openBox('sync_queue');
  
  // 3. Initialize Services
  final syncService = SyncQueueService(syncBox);
  final workoutStorage = WorkoutStorageService(workoutBox);
  
  // 4. Initialize Core dependencies
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        syncQueueServiceProvider.overrideWithValue(syncService),
        workoutStorageServiceProvider.overrideWithValue(workoutStorage),
      ],
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
      routes: (!kReleaseMode || kAllowDevMenuInRelease)
          ? {'/dev': (_) => const DevMenu()}
          : const {},
      debugShowCheckedModeBanner: false,
    );
  }
}

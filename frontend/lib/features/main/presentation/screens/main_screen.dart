import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../map/presentation/screens/map_dashboard_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../social/presentation/screens/social_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../map/presentation/widgets/hud_bottom_nav_bar.dart';
import '../../../workout/presentation/screens/active_workout_screen.dart';
import '../../../workout/application/workout_controller.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../../core/domain/models/workout_session.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapDashboardScreen(),
    const HistoryScreen(),
    const SocialScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Map content (IndexedStack)
          IndexedStack(index: _currentIndex, children: _screens),

          // LAYER: Navigation (Bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30, // Floating position
            child: HudBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              modeName: workoutState.ghostMode 
                  ? AppStrings.modeGhost 
                  : AppStrings.modeRogue,
            ),
          ),
        ],
      ),
    );
  }
}

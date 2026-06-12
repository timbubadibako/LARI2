import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../map/presentation/screens/map_dashboard_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../social/presentation/screens/social_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../map/presentation/widgets/hud_bottom_nav_bar.dart';
import '../../../workout/application/workout_controller.dart';
import '../../../../ui/components/app_strings.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  // Initialize immediately to prevent LateInitializationError during Hot Reload
  PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    if (index > 0) {
      if (_currentIndex > 0) {
        // Already in swipeable area, animate normally
        _pageController.animateToPage(
          index - 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        // Coming from Map Dashboard
        // Recreate controller with correct initial page to avoid "not attached" crash
        // and ensure the PageView starts at the right screen immediately.
        setState(() {
          _pageController = PageController(initialPage: index - 1);
          _currentIndex = index;
        });
      }
    } else {
      // Going back to Map Dashboard
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Switch between Map (0) and the Swipeable Pages (1, 2, 3)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _currentIndex == 0
                ? const MapDashboardScreen(key: ValueKey('map_screen'))
                : KeyedSubtree(
                    key: const ValueKey('swipeable_pages'),
                    child: PageView(
                      controller: _pageController,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (page) {
                        // Update bottom nav when user swipes manually
                        setState(() {
                          _currentIndex = page + 1;
                        });
                      },
                      children: const [
                        HistoryScreen(),
                        SocialScreen(),
                        ProfileScreen(),
                      ],
                    ),
                  ),
          ),

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

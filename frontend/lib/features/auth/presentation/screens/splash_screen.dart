import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../main/presentation/screens/main_screen.dart';
import 'login_screen.dart';
import '../../application/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _startTransition();
  }

  Future<void> _startTransition() async {
    // 1. Initialize persistent session from disk
    await ref.read(authControllerProvider).initSession();
    
    // 2. Short delay for visual immersion
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final session = ref.read(currentUserSessionProvider);
    
    if (session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          Positioned(
            left: -20,
            bottom: 100,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'LARI_LARI',
                style: StrideTypography.graffitiStyle.copyWith(
                  fontSize: 100,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Image.asset(
                      'assets/images/LARI-BlackNeon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      color: StrideColors.neonGreen,
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.initializing,
                    style: StrideTypography.labelTactical.copyWith(
                      fontSize: 8,
                      letterSpacing: 2,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppStrings.copyright,
                style: StrideTypography.labelTactical.copyWith(
                  fontSize: 6,
                  color: Colors.white10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

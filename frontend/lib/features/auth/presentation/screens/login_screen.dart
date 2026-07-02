import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/v3_input_field.dart';
import '../../../../core/services/lari_sync_service.dart';
import '../../../main/presentation/screens/main_screen.dart';
import '../../application/auth_controller.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: StrideColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(authControllerProvider)
          .signInWithEmailPassword(email, password);
      
      if (success) {
        await ref.read(lariSyncServiceProvider).processQueue();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credentials.'),
            backgroundColor: StrideColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: StrideColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Stack(
        children: [
          // Background Graffiti Watermark
          Positioned(
            right: -40,
            top: 100,
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                'STREET',
                style: StrideTypography.graffitiStyle.copyWith(
                  fontSize: 120,
                  color: StrideColors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // TOP SECTION
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              
                              // Header with Graffiti LARI
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: -20,
                                    left: -10,
                                    child: Transform.rotate(
                                      angle: -0.2,
                                      child: Text(
                                        'LARI',
                                        style: StrideTypography.graffitiStyle.copyWith(
                                          color: StrideColors.outline,
                                          fontSize: 64,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, top: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('SIGN ', style: StrideTypography.displayXL.copyWith(fontSize: 72)),
                                            Text('IN', style: StrideTypography.displayXL.copyWith(fontSize: 72, color: StrideColors.neonGreen)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'WELCOME BACK TO THE MOVEMENT.',
                                          style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 60),

                              // Input Group for Autofill
                              AutofillGroup(
                                child: Column(
                                  children: [
                                    V3InputField(
                                      controller: _emailController,
                                      label: 'EMAIL ADDRESS',
                                      hint: 'IDENTIFIER',
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                    ),
                                    const SizedBox(height: 32),
                                    V3InputField(
                                      controller: _passwordController,
                                      label: 'PASSWORD',
                                      hint: 'SECURITY KEY',
                                      isPassword: true,
                                      autofillHints: const [AutofillHints.password],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 60),

                              // Login Button
                              Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.65,
                                  child: V3SkewBox(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: StrideColors.neonGreen,
                                        foregroundColor: StrideColors.background,
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(StrideColors.background),
                                              ),
                                            )
                                          : Text(
                                              'SIGN IN',
                                              style: StrideTypography.buttonText.copyWith(fontSize: 28),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // BOTTOM SECTION
                          Padding(
                            padding: const EdgeInsets.only(top: 48, bottom: 24),
                            child: Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: StrideColors.white, width: 2)),
                                    ),
                                    child: Text(
                                      'CREATE NEW ACCOUNT',
                                      style: StrideTypography.labelBold.copyWith(fontSize: 10, letterSpacing: 1.5, color: StrideColors.textPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: Text(
                                    'FORGOT PASSWORD?',
                                    style: StrideTypography.labelTactical.copyWith(
                                      fontSize: 8,
                                      color: StrideColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom Hazard Pattern
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: V3HazardBar(height: 12),
          ),
        ],
      ),
    );
  }
}

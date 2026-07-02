import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/v3_input_field.dart';
import '../../../main/presentation/screens/main_screen.dart';
import '../../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  int _selectedColorIndex = 0;

  final List<Color> _factionColors = [
    const Color(0xFFCCFF00), // Neon Green
    const Color(0xFFFF007A), // Ultra Pink
    const Color(0xFF00F0FF), // Electric Blue
    const Color(0xFFFF5F00), // Inferno Orange
    const Color(0xFFBC00FF), // Phantom Purple
    const Color(0xFFFFF000), // High Volt
    const Color(0xFFFF0000), // Infra Red
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: StrideColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final selectedColor = _factionColors[_selectedColorIndex];
      final colorHex = '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      
      final success = await ref
          .read(authControllerProvider)
          .signUpWithEmailPassword(email, password, displayName, colorHex);
      if (!mounted) return;

      if (success) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. This email may already be in use.'),
            backgroundColor: StrideColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
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
          // Background Graffiti Watermark (Synced with Login)
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
                              const SizedBox(height: 20),
                              
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
                                            Text('UP', style: StrideTypography.displayXL.copyWith(fontSize: 72, color: StrideColors.neonGreen)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'JOIN THE MOVEMENT.',
                                          style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),

                              AutofillGroup(
                                child: Column(
                                  children: [
                                    V3InputField(
                                      controller: _displayNameController,
                                      label: 'FULL NAME',
                                      hint: 'Your name',
                                      activeBorderColor: _factionColors[_selectedColorIndex],
                                      autofillHints: const [AutofillHints.name],
                                    ),
                                    const SizedBox(height: 24),
                                    V3InputField(
                                      controller: _emailController,
                                      label: 'EMAIL',
                                      hint: 'Your email',
                                      activeBorderColor: _factionColors[_selectedColorIndex],
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                    ),
                                    const SizedBox(height: 24),
                                    V3InputField(
                                      controller: _passwordController,
                                      label: 'PASSWORD',
                                      hint: 'Min. 6 characters',
                                      isPassword: true,
                                      activeBorderColor: _factionColors[_selectedColorIndex],
                                      autofillHints: const [AutofillHints.newPassword],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),

                              // Faction Color Picker
                              Text(
                                'PICK YOUR COLOR',
                                style: StrideTypography.labelTactical.copyWith(fontSize: 8),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(_factionColors.length, (index) {
                                  final isSelected = _selectedColorIndex == index;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedColorIndex = index),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _factionColors[index],
                                        border: isSelected ? Border.all(color: StrideColors.white, width: 2) : null,
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 60),

                              // Sign Up Button
                              Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.65,
                                  child: V3SkewBox(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: StrideColors.white,
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
                                              'SIGN UP',
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
                            padding: const EdgeInsets.only(top: 40, bottom: 24),
                            child: Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: Text(
                                  'ALREADY HAVE AN ACCOUNT?',
                                  style: StrideTypography.labelBold.copyWith(
                                    fontSize: 10,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
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
            child: V3HazardBar(height: 12, color: StrideColors.white),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/signature_painter.dart';
import '../../application/profile_controller.dart';
import '../../../social/application/social_controller.dart';
import '../../../auth/application/auth_controller.dart';

class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSaving = false;
  bool _postToWall = true;

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // Convert strokes to a serializable format
    final data = _strokes.map((stroke) => 
      stroke.map((o) => {'x': o.dx, 'y': o.dy}).toList()
    ).toList();
    
    final jsonStr = jsonEncode(data);

    // 1. Update Profile Signature
    final successProfile = await ref.read(profileControllerProvider.notifier).updateProfile(
      signatureData: jsonStr,
    );

    // 2. Post to Global Wall if enabled
    if (_postToWall) {
      final userId = ref.read(currentUserSessionProvider);
      if (userId != null) {
        final List<List<Map<String, double>>> wallData = _strokes.map((stroke) => 
          stroke.map((o) => {'x': o.dx, 'y': o.dy}).toList()
        ).toList();
        await ref.read(socialControllerProvider).postGraffiti(userId, wallData);
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (successProfile) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SIGNATURE_POSTED_TO_UPLINK')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FAILED_TO_UPLOAD_SIGNATURE')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: 'SIGNATURE_TAG',
            subTitle: 'GRAFFITI_ENGINE',
            status: _isSaving ? 'UPLOADING...' : 'ACTIVE_CANVAS',
            statusColor: _isSaving ? StrideColors.warning : StrideColors.neonGreen,
            actions: [
              TacticalIconButton(
                onPressed: _isSaving ? null : _clear,
                icon: Icons.delete_sweep_outlined,
                color: StrideColors.error,
              ),
              TacticalIconButton(
                onPressed: _isSaving || _strokes.isEmpty ? null : () => _save(),
                icon: Icons.check,
                color: StrideColors.neonGreen,
              ),
              TacticalIconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.close,
              ),
            ],
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: StrideColors.surface,
                border: Border.all(color: StrideColors.white.withOpacity(0.05)),
              ),
              child: Stack(
                children: [
                  // Background Grid
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                  
                  // Drawing Area
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                        _strokes.add(_currentStroke);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      _currentStroke = [];
                    },
                    child: CustomPaint(
                      painter: SignaturePainter(strokes: _strokes),
                      size: Size.infinite,
                    ),
                  ),
                  
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      'TRACE_YOUR_IDENTITY_BELOW',
                      style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _postToWall,
                  onChanged: (v) => setState(() => _postToWall = v ?? true),
                  activeColor: StrideColors.neonGreen,
                  checkColor: Colors.black,
                ),
                Text('POST_TO_GLOBAL_WALL', style: StrideTypography.labelTactical.copyWith(fontSize: 9)),
              ],
            ),
          ),
          
          const V3HazardBar(height: 8),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StrideColors.white.withOpacity(0.02)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

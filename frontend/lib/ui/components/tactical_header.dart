import 'package:flutter/material.dart';
import '../theme/stride_colors.dart';
import '../theme/stride_typography.dart';
import 'v3_shapes.dart';

class TacticalHeader extends StatelessWidget {
  final String title;
  final String subTitle;
  final String? status;
  final Color? statusColor;
  final List<Widget>? actions;

  const TacticalHeader({
    super.key,
    required this.title,
    this.subTitle = 'YOUR RUNNING SPACE',
    this.status,
    this.statusColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatus = status != null && status!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    V3SlantBox(
                      slantWidth: 34,
                      isRightSlant: true,
                      color: StrideColors.surface,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.03),
                              Colors.transparent,
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(color: StrideColors.white.withValues(alpha: 0.06)),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 18, 84, hasStatus ? 30 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 42,
                                    margin: const EdgeInsets.only(right: 14, top: 2),
                                    color: statusColor ?? StrideColors.neonGreen,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subTitle,
                                          style: StrideTypography.labelTactical.copyWith(
                                            fontSize: 8,
                                            color: StrideColors.textSecondary,
                                            letterSpacing: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          style: StrideTypography.headlineLG.copyWith(
                                            fontSize: 34,
                                            color: StrideColors.white,
                                            height: 0.95,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasStatus)
                      Positioned(
                        bottom: -10,
                        left: 42,
                        child: V3SkewBox(
                          skewAmount: -0.18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor ?? StrideColors.neonGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: (statusColor ?? StrideColors.neonGreen).withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  spreadRadius: -6,
                                ),
                              ],
                            ),
                            child: Text(
                              status!,
                              style: StrideTypography.labelBold.copyWith(
                                fontSize: 8,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              if (actions != null)
                Container(
                  margin: const EdgeInsets.only(top: 18),
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: StrideColors.surface.withValues(alpha: 0.92),
                    border: Border(
                      left: BorderSide(
                        color: StrideColors.white.withValues(alpha: 0.06),
                      ),
                      right: BorderSide(
                        color: statusColor ?? StrideColors.neonGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Tactical Icon Button for Actions
class TacticalIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const TacticalIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = StrideColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: V3SkewBox(
        skewAmount: -0.15,
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: StrideColors.surface,
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 18,
                      spreadRadius: -6,
                    ),
                  ],
            border: Border.all(
              color: isDisabled ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.3), 
              width: 1.5,
            ),
          ),
          child: Icon(
            icon, 
            color: isDisabled ? color.withValues(alpha: 0.1) : color, 
            size: 20,
          ),
        ),
      ),
    );
  }
}

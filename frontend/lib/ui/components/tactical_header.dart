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
    this.subTitle = 'OPERATIONAL_ARCHIVES',
    this.status,
    this.statusColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SYSTEM METADATA BAR
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(color: StrideColors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _metaText('OP_PROTOCOL: LARI_V3.3'),
                  const Spacer(),
                  _metaText('UPLINK: ACTIVE'),
                  const SizedBox(width: 12),
                  _metaText('ENCRYPTION: AES_256'),
                ],
              ),
            ),
          ),
        ),

        // 2. MAIN HEADER STACK WITH ACTIONS
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // PRIMARY SLANTED PATCH
                  V3SlantBox(
                    slantWidth: 40,
                    isRightSlant: true,
                    color: StrideColors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 60, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subTitle, 
                            style: StrideTypography.labelTactical.copyWith(
                              fontSize: 8, 
                              color: Colors.black45,
                              letterSpacing: 2,
                            )
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title, 
                            style: StrideTypography.displayXL.copyWith(
                              fontSize: 48, 
                              color: Colors.black,
                              height: 0.9,
                              letterSpacing: -1,
                            )
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. DYNAMIC STATUS TAB (HITCHHIKER)
                  if (status != null)
                    Positioned(
                      bottom: -10,
                      left: 100,
                      child: V3SkewBox(
                        skewAmount: -0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: statusColor ?? StrideColors.neonGreen,
                          child: Text(
                            status!,
                            style: StrideTypography.labelBold.copyWith(
                              fontSize: 8,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // ACTION BUTTONS AREA
            if (actions != null)
              Padding(
                padding: const EdgeInsets.only(top: 24, right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _metaText(String text) {
    return Text(
      text,
      style: StrideTypography.labelTactical.copyWith(
        fontSize: 6,
        color: StrideColors.white.withOpacity(0.3),
        letterSpacing: 1,
      ),
    );
  }
}

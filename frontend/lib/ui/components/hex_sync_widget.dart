import 'package:flutter/material.dart';
import '../theme/stride_colors.dart';
import '../theme/stride_typography.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HexSyncWidget extends StatelessWidget {
  final int syncPercentage;

  const HexSyncWidget({super.key, required this.syncPercentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: StrideColors.sapphire.withOpacity(0.2), 
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: StrideColors.sapphire.withOpacity(0.1 + (syncPercentage / 100) * 0.15), 
            blurRadius: 40 + (syncPercentage.toDouble() / 2),
            spreadRadius: -10,
          )
        ]
      ),
      alignment: Alignment.center,
      child: Skeleton.keep(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$syncPercentage', 
              style: StrideTypography.displayXL.copyWith(
                fontSize: 84,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: StrideColors.sapphire.withOpacity(0.5), 
                    blurRadius: 20,
                  )
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '% SYNC', 
              style: StrideTypography.labelTactical.copyWith(
                color: StrideColors.sky,
                letterSpacing: 6.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

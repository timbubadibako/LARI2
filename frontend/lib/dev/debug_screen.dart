import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/theme/stride_colors.dart';
import '../ui/theme/stride_typography.dart';
import '../ui/components/tactical_header.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: 'DEBUG_CONSOLE',
            subTitle: 'DEVELOPER_TOOLS',
            status: 'GOD_MODE',
            statusColor: StrideColors.warning,
            actions: [
              TacticalIconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.close,
                color: StrideColors.error,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System logs and override controls will go here.', style: StrideTypography.bodyMD),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

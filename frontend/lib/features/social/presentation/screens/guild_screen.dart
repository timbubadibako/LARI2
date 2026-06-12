import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';

class GuildScreen extends ConsumerWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: 'FACTION_HQ',
            subTitle: 'GUILD_MANAGEMENT',
            status: 'UNALIGNED',
            statusColor: StrideColors.textMuted,
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
                  Text('Guild recruitment, alliances, and management will go here.', style: StrideTypography.bodyMD),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

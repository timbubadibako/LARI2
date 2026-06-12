import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../core/domain/models/user_profile.dart';
import '../../../profile/application/guild_controller.dart';
import '../../../profile/application/profile_controller.dart';

class GuildScreen extends ConsumerWidget {
  const GuildScreen({super.key});

  Future<void> _handleJoinGuild(BuildContext context, WidgetRef ref, Guild guild) async {
    HapticFeedback.mediumImpact();
    final success = await ref.read(guildControllerProvider).joinGuild(guild.id);
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SUCCESSFULLY ALIGNED WITH ${guild.name}'),
            backgroundColor: Color(int.parse(guild.emblemColor.replaceFirst('#', '0xFF'))),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ALIGNMENT FAILED. PROTOCOL ERROR.'),
            backgroundColor: StrideColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLeaveGuild(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    final success = await ref.read(guildControllerProvider).leaveGuild();
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ALIGNMENT SEVERED. YOU ARE NOW UNALIGNED.'),
            backgroundColor: StrideColors.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DISCONNECT FAILED. SYSTEM LOCK-IN ACTIVE.'),
            backgroundColor: StrideColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final guildsAsync = ref.watch(guildsProvider);
    final dominionAsync = ref.watch(dominionProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: 'FACTION_HQ',
            subTitle: 'GUILD_MANAGEMENT',
            status: 'SYSTEM_ACTIVE',
            statusColor: StrideColors.neonGreen,
            actions: [
              TacticalIconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.close,
                color: StrideColors.error,
              ),
            ],
          ),
          
          Expanded(
            child: profileAsync.when(
              data: (profile) => _buildContent(context, ref, profile, guildsAsync, dominionAsync),
              loading: () => const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen)),
              error: (e, s) => Center(child: Text('DATA_CORRUPTION_DETECTED', style: StrideTypography.labelBold.copyWith(color: StrideColors.error))),
            ),
          ),
          
          const V3HazardBar(height: 8),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, 
    WidgetRef ref, 
    UserProfile? profile, 
    AsyncValue<List<Guild>> guildsAsync,
    AsyncValue<List<FactionDominion>> dominionAsync,
  ) {
    final currentFactionId = profile?.factionId;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CURRENT STATUS
          _sectionHeader('CURRENT_ALIGNMENT'),
          const SizedBox(height: 16),
          _buildCurrentGuildCard(context, ref, profile, guildsAsync),
          
          const SizedBox(height: 48),

          // FACTION DOMINION
          _sectionHeader('GLOBAL_DOMINION'),
          const SizedBox(height: 16),
          _buildDominionList(dominionAsync),

          const SizedBox(height: 48),
          
          // AVAILABLE GUILDS
          _sectionHeader('FACTION_RECRUITMENT'),
          const SizedBox(height: 16),
          guildsAsync.when(
            data: (guilds) {
              final otherGuilds = guilds.where((g) => g.id != currentFactionId).toList();
              if (otherGuilds.isEmpty) {
                return Text('NO_AVAILABLE_FACTIONS_FOUND', style: StrideTypography.labelTactical.copyWith(color: StrideColors.textMuted));
              }
              return Column(
                children: otherGuilds.map((guild) => _buildGuildJoinCard(context, ref, guild)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen)),
            error: (e, s) => Text('ERROR_FETCHING_FACTIONS', style: StrideTypography.labelTactical.copyWith(color: StrideColors.error)),
          ),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: StrideColors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: StrideTypography.headlineMD.copyWith(fontSize: 18, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildCurrentGuildCard(BuildContext context, WidgetRef ref, UserProfile? profile, AsyncValue<List<Guild>> guildsAsync) {
    final hasGuild = profile?.factionId != null;
    final color = profile?.territoryColor != null 
        ? Color(int.parse(profile!.territoryColor!.replaceFirst('#', '0xFF')))
        : StrideColors.textMuted;

    String factionName = 'NO_AFFILIATION';
    if (hasGuild) {
      guildsAsync.whenData((guilds) {
        final g = guilds.firstWhere((element) => element.id == profile?.factionId, orElse: () => Guild(id: '', name: 'UNKNOWN', emblemColor: ''));
        factionName = g.name;
      });
    }
        
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasGuild ? 'ASSIGNED_TO_FACTION' : 'STATUS: UNALIGNED',
                style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: color.withOpacity(0.6)),
              ),
              if (hasGuild)
                TextButton(
                  onPressed: () => _handleLeaveGuild(context, ref),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('LEAVE_FACTION', style: StrideTypography.labelBold.copyWith(fontSize: 8, color: StrideColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            factionName.toUpperCase(),
            style: StrideTypography.displayXL.copyWith(fontSize: 32),
          ),
          if (hasGuild) ...[
            const SizedBox(height: 12),
            Text(
              'Your efforts contribute to the global dominion of this faction.',
              style: StrideTypography.bodyMD.copyWith(fontSize: 12, color: StrideColors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Align with a faction below to start claiming territory for your team.',
              style: StrideTypography.bodyMD.copyWith(fontSize: 12, color: StrideColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDominionList(AsyncValue<List<FactionDominion>> dominionAsync) {
    return dominionAsync.when(
      data: (dominion) => Column(
        children: dominion.map((d) => _buildDominionTile(d)).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen)),
      error: (e, s) => Text('ERROR_FETCHING_DOMINION', style: StrideTypography.labelTactical.copyWith(color: StrideColors.error)),
    );
  }

  Widget _buildDominionTile(FactionDominion d) {
    final color = Color(int.parse(d.emblemColor.replaceFirst('#', '0xFF')));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border(right: BorderSide(color: color.withOpacity(0.3), width: 2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d.name, style: StrideTypography.labelBold.copyWith(fontSize: 14)),
              Text('${d.percentage.toStringAsFixed(1)}%', style: StrideTypography.labelTactical.copyWith(fontSize: 14, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: d.percentage / 100,
              backgroundColor: StrideColors.background,
              color: color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'TOTAL_AREA: ${(d.totalArea / 1000).toStringAsFixed(1)}K SQM',
              style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildJoinCard(BuildContext context, WidgetRef ref, Guild guild) {
    final color = Color(int.parse(guild.emblemColor.replaceFirst('#', '0xFF')));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border.all(color: StrideColors.white.withOpacity(0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guild.name, style: StrideTypography.headlineMD.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      'FACTION_ID: ${guild.id.substring(0, 8).toUpperCase()}',
                      style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            V3SkewBox(
              child: Material(
                color: color,
                child: InkWell(
                  onTap: () => _handleJoinGuild(context, ref, guild),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: Text(
                      'JOIN',
                      style: StrideTypography.buttonText.copyWith(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

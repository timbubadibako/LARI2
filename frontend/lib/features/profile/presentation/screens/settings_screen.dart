import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/v3_input_field.dart';
import '../../../../core/domain/models/user_profile.dart';
import '../../application/profile_controller.dart';
import '../../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _publicProfile = false;
  bool _ghostMode = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFields(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _nameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _publicProfile = profile.publicProfile;
    _ghostMode = profile.ghostMode;
    _initialized = true;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      publicProfile: _publicProfile,
      ghostMode: _ghostMode,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Settings saved' : 'Failed to save settings'),
          backgroundColor: success ? StrideColors.neonGreen : StrideColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    
    profileAsync.whenData((profile) => _initFields(profile));

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                  TacticalHeader(
            title: 'Settings',
            subTitle: 'ACCOUNT, PRIVACY, AND APP INFO',
            status: _isSaving ? 'SAVING' : 'ACCOUNT',
            statusColor: _isSaving ? StrideColors.warning : StrideColors.neonGreen,
            actions: [
              TacticalIconButton(
                onPressed: _isSaving ? null : () => _handleSave(),
                icon: Icons.save_outlined,
                color: StrideColors.neonGreen,
              ),
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
                  _sectionHeader('ACCOUNT'),
                  const SizedBox(height: 24),
                  V3InputField(
                    controller: _nameController,
                    label: 'DISPLAY NAME',
                    hint: 'Your name',
                  ),
                  const SizedBox(height: 24),
                  V3InputField(
                    controller: _bioController,
                    label: 'BIO',
                    hint: 'A little about yourself',
                  ),
                  
                  const SizedBox(height: 48),
                  
                  _sectionHeader('PRIVACY'),
                  const SizedBox(height: 16),
                  _buildToggle(
                    'PUBLIC PROFILE',
                    'Visibility of your stats to other runners.',
                    _publicProfile,
                    (v) => setState(() => _publicProfile = v),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    'GHOST MODE',
                    'Hide your presence from real-time radar.',
                    _ghostMode,
                    (v) => setState(() => _ghostMode = v),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  _sectionHeader('ABOUT'),
                  const SizedBox(height: 16),
                  _buildInfoRow('APP VERSION', '3.8.2-BETA'),
                  _buildInfoRow('DEVELOPER', 'Stride IO'),
                  _buildInfoRow('SUPPORT', 'support@lari2.app'),
                  
                  const SizedBox(height: 32),

                  _sectionHeader('LEGAL'),
                  const SizedBox(height: 16),
                  _buildInfoRow('TERMS & CONDITIONS', 'Available in-app'),
                  _buildInfoRow('PRIVACY POLICY', 'Available in-app'),
                  
                  const SizedBox(height: 64),

                  _sectionHeader('ACCOUNT ACTIONS'),
                  const SizedBox(height: 16),
                  _buildDebugButton(
                    'SIGN OUT',
                    Icons.logout,
                    StrideColors.warning,
                    () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Sign out?',
                        'You will be logged out from this device. Your running data will stay saved.'
                      );
                      if (confirmed) {
                        await ref.read(authControllerProvider).signOut();
                        if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDebugButton(
                    'DELETE ACCOUNT',
                    Icons.delete_forever,
                    StrideColors.error,
                    () async {
                      final confirmed = await _showConfirmDialog(
                        context, 
                        'Delete account?',
                        'This will permanently delete your profile and running history. This action cannot be undone.'
                      );
                      if (confirmed) {
                        ref.read(authControllerProvider).signOut();
                        if (mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account deleted.')),
                          );
                        }
                      }
                    },
                  ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          const V3HazardBar(height: 8),
        ],
      ),
    );
  }

  Widget _buildDebugButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: StrideColors.surface,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(label, style: StrideTypography.labelBold.copyWith(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: StrideColors.surface,
        title: Text(title, style: StrideTypography.labelBold.copyWith(color: StrideColors.warning)),
        content: Text(content, style: StrideTypography.bodyMD.copyWith(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PROCEED', style: TextStyle(color: StrideColors.error)),
          ),
        ],
      ),
    ) ?? false;
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

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border(left: BorderSide(color: value ? StrideColors.neonGreen : StrideColors.white.withOpacity(0.1), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: StrideTypography.labelBold.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: StrideColors.neonGreen,
            activeTrackColor: StrideColors.neonGreen.withOpacity(0.2),
            inactiveThumbColor: StrideColors.textMuted,
            inactiveTrackColor: StrideColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 9, color: StrideColors.textMuted)),
          Text(value, style: StrideTypography.labelBold.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

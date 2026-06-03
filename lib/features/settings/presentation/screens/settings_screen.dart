import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../workspace/domain/workspace_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceStateProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),

        // Store profile
        _section('Store Profile', [
          _settingTile(
            icon: Icons.store,
            title: 'Business Name',
            subtitle: workspace.selectedName ?? 'Not set',
            onTap: () {},
          ),
          _settingTile(
            icon: Icons.phone,
            title: 'Contact Number',
            subtitle: 'Not set',
            onTap: () {},
          ),
          _settingTile(
            icon: Icons.location_on,
            title: 'Address',
            subtitle: 'Not set',
            onTap: () {},
          ),
          _settingTile(
            icon: Icons.receipt_long,
            title: 'Receipt Header',
            subtitle: 'Customize receipt info',
            onTap: () {},
          ),
        ]).animate().fadeIn(),

        const SizedBox(height: 20),

        // Printer
        _section('Receipt Printer', [
          _settingTile(
            icon: Icons.print,
            title: 'Connect Printer',
            subtitle: 'Niimbot B21 / Bluetooth ESC/POS',
            onTap: () => context.go('/printer-connect'),
          ),
          _settingTile(
            icon: Icons.qr_code,
            title: 'Print Test Receipt',
            subtitle: 'Verify printer setup',
            onTap: () {},
          ),
        ]).animate(delay: 100.ms).fadeIn(),

        const SizedBox(height: 20),

        // Workspace
        _section('Workspace', [
          _settingTile(
            icon: Icons.group,
            title: 'Members',
            subtitle: 'Manage team access',
            onTap: () {},
          ),
          _settingTile(
            icon: Icons.link,
            title: 'Invite Code',
            subtitle: 'Share to invite members',
            onTap: () {},
          ),
        ]).animate(delay: 200.ms).fadeIn(),

        const SizedBox(height: 20),

        // Data
        _section('Data & Sync', [
          _settingTile(
            icon: Icons.cloud_sync,
            title: 'Sync Status',
            subtitle: 'All changes synced',
            onTap: () {},
          ),
          _settingTile(
            icon: Icons.backup,
            title: 'Export Data',
            subtitle: 'Download CSV backup',
            onTap: () {},
          ),
        ]).animate(delay: 300.ms).fadeIn(),

        const SizedBox(height: 20),

        // Account
        _section('Account', [
          _settingTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle: ref.watch(authStateProvider).user?.email ?? 'Not signed in',
            onTap: () {},
          ),
          _settingTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of SpiceDesk',
            textColor: SpiceColors.danger,
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ]).animate(delay: 400.ms).fadeIn(),

        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text('SpiceDesk v1.0.0',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text('Made by Shahid Singh',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: TextStyle(
                color: SpiceColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
        ),
        GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? SpiceColors.textSecondary),
      title: Text(title,
          style: TextStyle(
              color: textColor ?? SpiceColors.textPrimary,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: SpiceColors.textSecondary),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

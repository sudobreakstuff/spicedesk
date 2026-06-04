import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../workspace/domain/workspace_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceStateProvider);
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Manage your business preferences',
              style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),

          const SizedBox(height: 32),

          _section('Store Profile', [
            _tile(Icons.store, 'Business Name', workspace.selectedName ?? 'Not set',
                onTap: () => _showEditDialog(context, 'Business Name', workspace.selectedName ?? '', (v) {})),
            _tile(Icons.phone, 'Contact Number', 'Not set',
                onTap: () => _showEditDialog(context, 'Contact Number', '', (v) {})),
            _tile(Icons.location_on, 'Address', 'Not set',
                onTap: () {}),
            _tile(Icons.receipt_long, 'Receipt Header', 'Customize receipt info',
                onTap: () {}),
          ]),

          const SizedBox(height: 24),

          _section('Receipt Printer', [
            _tile(Icons.print, 'Connect Printer', 'Niimbot B21 / Bluetooth',
                onTap: () => context.go('/printer-connect')),
            _tile(Icons.qr_code, 'Test Print', 'Verify printer setup',
                onTap: () {}),
          ]),

          const SizedBox(height: 24),

          _section('Workspace', [
            _tile(Icons.group, 'Members', 'Manage team access',
                onTap: () {}),
            _tile(Icons.link, 'Invite Code', 'Share to invite members',
                onTap: () {}),
          ]),

          const SizedBox(height: 24),

          _section('Data & Sync', [
            _tile(Icons.cloud_sync, 'Sync Status', 'All changes synced',
                onTap: () {}),
            _tile(Icons.download, 'Export Data', 'Download CSV backup',
                onTap: () {}),
          ]),

          const SizedBox(height: 24),

          _section('Account', [
            _tile(Icons.person, 'Profile', user?.email ?? 'Not signed in',
                onTap: () {}),
            _tile(Icons.logout, 'Sign Out', 'Log out of SpiceDesk',
                onTap: () => ref.read(authStateProvider.notifier).logout(),
                color: SpiceColors.danger),
          ]).animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 32),
          const Center(
            child: Column(
              children: [
                Text('SpiceDesk v1.0.0',
                    style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
                SizedBox(height: 4),
                Text('Made by Shahid Singh',
                    style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String label, String current, Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: Text('Edit $label'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (v) {
            onSave(v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onSave(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SpiceColors.primary,
                letterSpacing: 1.2,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: SpiceColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SpiceColors.border),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast) const Divider(height: 1, indent: 52, color: SpiceColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? color}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: (color ?? SpiceColors.textSecondary).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? SpiceColors.textSecondary, size: 18),
      ),
      title: Text(title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? SpiceColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: SpiceColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

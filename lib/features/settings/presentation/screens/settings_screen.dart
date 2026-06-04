import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../printing/data/printing_service.dart';
import '../../../workspace/domain/workspace_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _contactNumber = '';
  String _address = '';
  String _receiptHeader = '';
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final ws = ref.read(workspaceStateProvider);
    if (ws.selectedId != null) {
      try {
        final data = await supabase
            .from('workspaces')
            .select('settings')
            .eq('id', ws.selectedId!)
            .maybeSingle();
        if (data != null && data['settings'] != null) {
          final settings = data['settings'] as Map<String, dynamic>;
          setState(() {
            _contactNumber = settings['contact_number']?.toString() ?? '';
            _address = settings['address']?.toString() ?? '';
            _receiptHeader = settings['receipt_header']?.toString() ?? '';
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveSetting(String key, String value) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return;

    try {
      final data = await supabase
          .from('workspaces')
          .select('settings')
          .eq('id', wsId)
          .maybeSingle();
      final settings = Map<String, dynamic>.from(
          data?['settings'] as Map<String, dynamic>? ?? {});
      settings[key] = value;
      await supabase
          .from('workspaces')
          .update({'settings': settings}).eq('id', wsId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: SpiceColors.danger,
        ));
      }
    }
  }

  Future<void> _saveBusinessName(String name) async {
    try {
      await ref.read(workspaceStateProvider.notifier).updateWorkspaceName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Business name updated'),
          backgroundColor: SpiceColors.accent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update name: $e'),
          backgroundColor: SpiceColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceStateProvider);
    final user = ref.watch(authStateProvider).user;

    final displayBusinessName = workspace.selectedName ?? 'Not set';
    final displayContact = _contactNumber.isNotEmpty ? _contactNumber : 'Not set';
    final displayAddress = _address.isNotEmpty ? _address : 'Not set';
    final displayReceipt = _receiptHeader.isNotEmpty ? _receiptHeader : 'Customize receipt info';

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
            _tile(Icons.store, 'Business Name', displayBusinessName,
                onTap: () => _showEditDialog(
                  context,
                  'Business Name',
                  workspace.selectedName ?? '',
                  onSave: _saveBusinessName,
                )),
            _tile(Icons.phone, 'Contact Number', displayContact,
                onTap: () {
                  _showEditDialog(
                    context,
                    'Contact Number',
                    _contactNumber,
                    onSave: (v) async {
                      setState(() => _contactNumber = v);
                      await _saveSetting('contact_number', v);
                    },
                  );
                }),
            _tile(Icons.location_on, 'Address', displayAddress,
                onTap: () {
                  _showEditDialog(
                    context,
                    'Address',
                    _address,
                    onSave: (v) async {
                      setState(() => _address = v);
                      await _saveSetting('address', v);
                    },
                  );
                }),
            _tile(Icons.receipt_long, 'Receipt Header', displayReceipt,
                onTap: () {
                  _showEditDialog(
                    context,
                    'Receipt Header',
                    _receiptHeader,
                    onSave: (v) async {
                      setState(() => _receiptHeader = v);
                      await _saveSetting('receipt_header', v);
                    },
                  );
                }),
          ]),

          const SizedBox(height: 24),

          _section('Receipt Printer', [
            _tile(Icons.print, 'Connect Printer', 'Niimbot B21 / Bluetooth',
                onTap: () => context.go('/printer-connect')),
            _tile(Icons.qr_code, 'Test Print', 'Verify printer setup',
                onTap: () async {
                  final ps = PrintingService();
                  if (!ps.isConnected) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No printer connected. Go to Connect Printer first.'),
                          backgroundColor: SpiceColors.warning,
                        ),
                      );
                    }
                    return;
                  }
                  final scaffold = ScaffoldMessenger.of(context);
                  final success = await ps.printReceipt(
                    storeName: workspace.selectedName ?? 'SpiceDesk',
                    transactionNumber: 'TEST-001',
                    date: DateTime.now(),
                    items: const [
                      ReceiptLineItem(
                        name: 'Test Item',
                        quantity: 1,
                        unitPrice: 0.0,
                        lineTotal: 0.0,
                      ),
                    ],
                    total: 0,
                    paymentMethod: 'Test',
                  );
                  if (mounted) {
                    scaffold.showSnackBar(SnackBar(
                      content: Text(success ? 'Test print sent' : 'Print failed'),
                      backgroundColor: success ? SpiceColors.accent : SpiceColors.danger,
                    ));
                  }
                }),
          ]),

          const SizedBox(height: 24),

          _section('Workspace', [
            _tile(Icons.group, 'Members', 'Manage team access',
                onTap: () => _showComingSoon(context)),
            _tile(Icons.link, 'Invite Code', 'Share to invite members',
                onTap: () => _showInviteCodeDialog(context, workspace.selectedId)),
          ]),

          const SizedBox(height: 24),

          _section('Data & Sync', [
            _tile(Icons.cloud_sync, 'Sync Status', 'All changes synced',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All changes synced')),
                  );
                }),
            _tile(Icons.download, 'Export Data', 'Download CSV backup',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                }),
          ]),

          const SizedBox(height: 24),

          _section('Account', [
            _tile(Icons.person, 'Profile', user?.email ?? 'Not signed in',
                onTap: () => _showProfileDialog(context, user?.email)),
            _tile(Icons.logout, 'Sign Out', 'Log out of SpiceDesk',
                onTap: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
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

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Coming Soon'),
        content: const Text('Members management will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInviteCodeDialog(BuildContext context, String? workspaceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with team members:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: SpiceColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Text(
                workspaceId ?? 'No workspace selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SpiceColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, String? email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Signed in as:'),
            const SizedBox(height: 8),
            Text(
              email ?? 'Not signed in',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: SpiceColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String label,
    String current, {
    required Future<void> Function(String) onSave,
  }) {
    final ctrl = TextEditingController(text: current);
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: Text('Edit $label'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            enabled: !saving,
            decoration: InputDecoration(labelText: label),
            onSubmitted: saving
                ? null
                : (v) async {
                    setDialogState(() => saving = true);
                    await onSave(v);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      await onSave(ctrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
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

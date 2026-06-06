import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../customers/data/customers_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../sales/data/sales_provider.dart';
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
  Map<String, dynamic> _settings = {};

  String _getSetting(String key, String fallback) {
    final val = _settings[key];
    return val?.toString() ?? fallback;
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64 = 'data:image/png;base64,${base64Encode(bytes)}';
    await _saveSetting('company_logo', base64);
    setState(() => _settings['company_logo'] = base64);
  }

  Future<void> _editSetting(String key, String title, String current) async {
    final ctrl = TextEditingController(text: _getSetting(key, current));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: SpiceColors.border)),
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await _saveSetting(key, result);
      setState(() => _settings[key] = result);
    }
  }
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return;
    final data = await supabase.from('workspaces').select('settings').eq('id', wsId).maybeSingle();
    final settings = (data?['settings'] as Map<String, dynamic>?) ?? {};
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _saveSetting(String key, String value) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select or create a workspace first'),
          backgroundColor: SpiceColors.danger,
        ));
      }
      return;
    }

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

          _section('Workspace', [
            _tile(Icons.group, 'Members', 'Manage team access',
                onTap: () => _showComingSoon(context)),
            _tile(Icons.link, 'Invite Code', 'Share to invite members',
                onTap: () => _showInviteCodeDialog(context, workspace.selectedId)),
          ]),

          const SizedBox(height: 24),

          _section('POS Settings', [
            _tile(Icons.local_shipping, 'Delivery Charge', 'R${_getSetting('delivery_charge', '20.00')}',
                onTap: () => _editSetting('delivery_charge', 'Delivery Charge (R)', '20.00')),
            _tile(Icons.percent, 'Tax Rate', '${_getSetting('tax_rate', '0')}%',
                onTap: () => _editSetting('tax_rate', 'Tax Rate (%)', '0')),
            _tile(Icons.receipt_long, 'Invoice Footer', _getSetting('invoice_footer', 'Thank you for your business'),
                onTap: () => _editSetting('invoice_footer', 'Invoice Footer', 'Thank you for your business')),
          ]),
          const SizedBox(height: 20),
          _section('Invoice Settings', [
            _tile(Icons.image, 'Company Logo', _getSetting('company_logo', '').isNotEmpty ? 'Logo uploaded' : 'Tap to upload',
                onTap: _uploadLogo),
            _tile(Icons.business, 'Company Name', _getSetting('company_name', 'SpiceDesk'),
                onTap: () => _editSetting('company_name', 'Company Name', 'SpiceDesk')),
            _tile(Icons.credit_card, 'VAT / Tax Number', _getSetting('tax_number', ''),
                onTap: () => _editSetting('tax_number', 'VAT / Tax Number', '')),
            _tile(Icons.account_balance, 'Bank Name', _getSetting('bank_name', ''),
                onTap: () => _editSetting('bank_name', 'Bank Name', '')),
            _tile(Icons.person, 'Account Holder', _getSetting('account_holder', ''),
                onTap: () => _editSetting('account_holder', 'Account Holder', '')),
            _tile(Icons.numbers, 'Account Number', _getSetting('account_number', ''),
                onTap: () => _editSetting('account_number', 'Account Number', '')),
            _tile(Icons.location_on, 'Address', _getSetting('company_address', ''),
                onTap: () => _editSetting('company_address', 'Company Address', '')),
            _tile(Icons.phone, 'Phone', _getSetting('company_phone', ''),
                onTap: () => _editSetting('company_phone', 'Company Phone', '')),
            _tile(Icons.email, 'Email', _getSetting('company_email', ''),
                onTap: () => _editSetting('company_email', 'Company Email', '')),
            _tile(Icons.tag, 'Invoice Prefix', _getSetting('invoice_prefix', 'INV-'),
                onTap: () => _editSetting('invoice_prefix', 'Invoice Prefix', 'INV-')),
            _tile(Icons.article, 'Terms & Conditions', _getSetting('invoice_terms', 'Payment due within 30 days'),
                onTap: () => _editSetting('invoice_terms', 'Terms & Conditions', 'Payment due within 30 days')),
          ]),

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

          const SizedBox(height: 24),

          _section('Danger Zone', [
            _tile(Icons.delete_forever, 'Reset All Data',
                'Permanently delete all sales, products, inventory, and customers',
                onTap: () => _showResetAllDataDialog(context, workspace.selectedId),
                color: SpiceColors.danger),
          ]),

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

  void _showResetAllDataDialog(BuildContext context, String? workspaceId) {
    bool deleting = false;
    String? progress;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.danger),
          ),
          title: const Text('Reset All Data', style: TextStyle(color: SpiceColors.danger)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete all sales, products, inventory, and customers for this workspace. This cannot be undone.',
                style: TextStyle(color: SpiceColors.textSecondary),
              ),
              if (progress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: SpiceColors.border,
                  color: SpiceColors.danger,
                ),
                const SizedBox(height: 8),
                Text(progress!, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: deleting
                  ? null
                  : () async {
                      if (workspaceId == null) return;
                      try {
                        setDialogState(() {
                          deleting = true;
                          progress = 'Deleting sale items...';
                        });
                        await supabase.from('sale_items').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting invoices...');
                        await supabase.from('invoices').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting quote items...');
                        await supabase.from('quote_items').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting sales transactions...');
                        await supabase.from('sales_transactions').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting stock movements...');
                        await supabase.from('stock_movements').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting quotes...');
                        await supabase.from('quotes').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting inventory...');
                        await supabase.from('inventory').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting products...');
                        await supabase.from('products').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Deleting customers...');
                        await supabase.from('customers').delete().eq('workspace_id', workspaceId);

                        setDialogState(() => progress = 'Invalidating providers...');
                        ref.invalidate(productsProvider);
                        ref.invalidate(inventoryProvider);
                        ref.invalidate(productsNeedingInventoryProvider);
                        ref.invalidate(customersProvider);
                        ref.invalidate(customerCountProvider);
                        ref.invalidate(salesProvider);
                        ref.invalidate(todaySalesProvider);
                        ref.invalidate(dailySalesProvider);
                        ref.invalidate(weeklySalesProvider);
                        ref.invalidate(monthlySalesProvider);
                        ref.invalidate(totalTransactionsProvider);
                        ref.invalidate(profitProvider);
                        ref.invalidate(allCustomerSalesProvider);
                        ref.invalidate(workspacesProvider);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('All data has been reset for this workspace'),
                            backgroundColor: SpiceColors.accent,
                          ));
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Failed to reset data: $e'),
                            backgroundColor: SpiceColors.danger,
                          ));
                          Navigator.pop(ctx);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: SpiceColors.danger),
              child: deleting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete Everything'),
            ),
          ],
        ),
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
                    try {
                      await onSave(v);
                    } catch (_) {}
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
                      try {
                        await onSave(ctrl.text.trim());
                      } catch (_) {}
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

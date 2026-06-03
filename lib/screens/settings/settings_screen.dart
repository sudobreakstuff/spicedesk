import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final bp = context.watch<BusinessProvider>();
    final b = bp.business;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: Icon(tp.isDark ? Icons.dark_mode : Icons.light_mode, color: tp.isDark ? T.pL : T.w),
            title: const Text('Dark Mode'),
            value: tp.isDark,
            onChanged: (_) => tp.toggle(),
          ),
          const Divider(),
          _SectionHeader(title: 'Business'),
          ListTile(
            leading: const Icon(Icons.store),
            title: Text(b?.name ?? 'Not set'),
            subtitle: Text('VAT: ${((b?.vatRate ?? 0.15) * 100).toStringAsFixed(1)}% · ${b?.country ?? 'N/A'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBusinessEdit(context),
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('Built by Shahid Singh'), subtitle: Text('Version 1.0.0')),
          const Divider(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, color: T.e, size: 18),
              label: const Text('Sign Out', style: TextStyle(color: T.e)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), side: const BorderSide(color: T.e)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Sign Out'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign Out', style: TextStyle(color: T.e)))]));
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  void _showBusinessEdit(BuildContext context) {
    final bp = context.read<BusinessProvider>();
    final b = bp.business;
    if (b == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _BusinessEditSheet(business: b),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: T.t3, letterSpacing: 0.8)),
    );
  }
}

class _BusinessEditSheet extends StatefulWidget {
  final dynamic business;
  const _BusinessEditSheet({required this.business});

  @override
  State<_BusinessEditSheet> createState() => _BusinessEditSheetState();
}

class _BusinessEditSheetState extends State<_BusinessEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vatCtrl;
  late final TextEditingController _footerCtrl;
  late double _vatRate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _nameCtrl = TextEditingController(text: b.name ?? '');
    _addrCtrl = TextEditingController(text: b.address ?? '');
    _phoneCtrl = TextEditingController(text: b.phone ?? '');
    _vatCtrl = TextEditingController(text: b.vatNumber ?? '');
    _footerCtrl = TextEditingController(text: b.receiptFooter ?? '');
    _vatRate = b.vatRate ?? 0.15;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _vatCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final bp = context.read<BusinessProvider>();
    await bp.updateBusiness(
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      vatNumber: _vatCtrl.text.trim(),
      receiptFooter: _footerCtrl.text.trim(),
      vatRate: _vatRate,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: T.t3))),
              const SizedBox(height: 16),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Business Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: _vatCtrl, decoration: const InputDecoration(labelText: 'VAT Number')),
              const SizedBox(height: 12),
              TextFormField(controller: _footerCtrl, decoration: const InputDecoration(labelText: 'Receipt Footer'), maxLines: 2),
              const SizedBox(height: 14),
              Text('VAT Rate: ${(_vatRate * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
              Slider(value: _vatRate, min: 0, max: 0.25, divisions: 25, label: '${(_vatRate * 100).toStringAsFixed(0)}%', onChanged: (v) => setState(() => _vatRate = v)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: bp.loading ? null : _save,
                  child: bp.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

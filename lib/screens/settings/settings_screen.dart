import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final bp = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Section('Appearance'),
        Card(child: SwitchListTile(title: const Text('Dark Mode'), subtitle: Text(tm.isDark ? 'On' : 'Off', style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.textSecondary)), value: tm.isDark, onChanged: (_) => tm.toggle(), secondary: const Icon(Icons.dark_mode_outlined))),
        const SizedBox(height: 16),
        Section('Business'),
        Card(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.store_outlined, size: 20), title: Text(bp.business?.name ?? 'Not set', style: GoogleFonts.inter(fontWeight: FontWeight.w500)), subtitle: Text('VAT: ${((bp.business?.vatRate ?? 0.15) * 100).toStringAsFixed(0)}% · ${bp.business?.currency ?? 'ZAR'}', style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textSecondary)), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () => _editBusiness(context)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.receipt_outlined, size: 20), title: Text('Invoice Prefix: ${bp.business?.invoicePrefix ?? 'INV'}', style: GoogleFonts.inter(fontSize: 13)), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () {}),
          ]),
        ),
        const SizedBox(height: 16),
        Section('Data'),
        Card(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.cloud_outlined, size: 20), title: const Text('Cloud Sync'), subtitle: const Text('Supabase', style: TextStyle(fontSize: 11)), trailing: Switch(value: bp.business?.cloudSyncEnabled ?? false, onChanged: (_) {})),
          ]),
        ),
        const SizedBox(height: 16),
        Section('About'),
        Card(
          child: Column(children: [
            ListTile(leading: CircleAvatar(radius: 14, backgroundColor: SpiceColors.primaryBg, child: Text('SS', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: SpiceColors.primary))), title: const Text('Built by Shahid Singh'), subtitle: const Text('Flutter 3.27 · Supabase · SQLite', style: TextStyle(fontSize: 11))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.info_outline, size: 20), title: const Text('Version 1.0.0'), onTap: () {}),
          ]),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: () async { await context.read<AuthProvider>().signOut(); if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const _LoginRedirect()), (r) => false); }, icon: const Icon(Icons.logout, size: 18), label: const Text('Sign Out'), style: OutlinedButton.styleFrom(foregroundColor: SpiceColors.error, side: const BorderSide(color: SpiceColors.error))),
        const SizedBox(height: 32),
      ]),
    );
  }

  void _editBusiness(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (context) {
        final b = context.watch<BusinessProvider>().business;
        return _BusinessEditForm(business: b);
      },
    );
  }
}

class _BusinessEditForm extends StatefulWidget {
  final dynamic business;
  const _BusinessEditForm({required this.business});
  @override
  State<_BusinessEditForm> createState() => _BusinessEditFormState();
}

class _BusinessEditFormState extends State<_BusinessEditForm> {
  late final TextEditingController _name, _address, _phone, _vatNum, _footer;
  double _vat = 0.15;

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _name = TextEditingController(text: b?.name ?? '');
    _address = TextEditingController(text: b?.address ?? '');
    _phone = TextEditingController(text: b?.phone ?? '');
    _vatNum = TextEditingController(text: b?.vatNumber ?? '');
    _footer = TextEditingController(text: b?.receiptFooter ?? '');
    _vat = b?.vatRate ?? 0.15;
  }

  @override
  void dispose() { _name.dispose(); _address.dispose(); _phone.dispose(); _vatNum.dispose(); _footer.dispose(); super.dispose(); }

  Future<void> _save() async {
    await context.read<BusinessProvider>().updateBusiness(name: _name.text.trim(), address: _address.text.trim(), phone: _phone.text.trim(), vatNumber: _vatNum.text.trim(), vatRate: _vat, receiptFooter: _footer.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Edit Business', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _address, maxLines: 1, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 8),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 8),
          TextField(controller: _vatNum, decoration: const InputDecoration(labelText: 'VAT Number')),
          const SizedBox(height: 8),
          TextField(controller: _footer, maxLines: 1, decoration: const InputDecoration(labelText: 'Receipt Footer')),
          const SizedBox(height: 8),
          Text('VAT Rate: ${(_vat * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 13)),
          Slider(value: _vat, min: 0, max: 0.25, divisions: 25, onChanged: (v) => setState(() => _vat = v)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(height: 14),
        ]),
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  const Section(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 2, bottom: 8), child: Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: SpiceColors.textTertiary, letterSpacing: 1)));
}

class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect();
  @override
  Widget build(BuildContext context) { WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false)); return const SizedBox(); }
}

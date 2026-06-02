import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';
import '../../core/config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Appearance'),
          _ThemeSelector(),
          const SizedBox(height: 12),
          _SectionHeader('Business'),
          _BusinessSettings(),
          const SizedBox(height: 12),
          _SectionHeader('About'),
          _AboutTile(),
          const SizedBox(height: 24),
          _SignOutButton(),
          const SizedBox(height: 32),
          Center(child: Text('SpiceDesk v${AppConfig.appVersion}\n${AppConfig.appTagline}',
              textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500))),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(title.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange, letterSpacing: 1)),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Card(
      child: Column(
        children: [
          _ThemeTile(mode: AppThemeMode.light, current: theme.mode, onTap: () => theme.setMode(AppThemeMode.light)),
          const Divider(height: 1, indent: 56),
          _ThemeTile(mode: AppThemeMode.dark, current: theme.mode, onTap: () => theme.setMode(AppThemeMode.dark)),
          const Divider(height: 1, indent: 56),
          _ThemeTile(mode: AppThemeMode.spiceDark, current: theme.mode, onTap: () => theme.setMode(AppThemeMode.spiceDark)),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppThemeMode mode;
  final AppThemeMode current;
  final VoidCallback onTap;
  const _ThemeTile({required this.mode, required this.current, required this.onTap});

  IconData _icon() => switch (mode) {
    AppThemeMode.light => Icons.light_mode,
    AppThemeMode.dark => Icons.dark_mode,
    AppThemeMode.spiceDark => Icons.nights_stay,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(radius: 18, backgroundColor: mode == AppThemeMode.spiceDark ? AppColors.orange.withValues(alpha: 0.2) : null,
          child: Icon(_icon(), size: 20, color: mode == AppThemeMode.spiceDark ? AppColors.orange : null)),
      title: Text(AppThemeModeExt.label(mode), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: mode == AppThemeMode.spiceDark ? Text('Dark with warm spice accents', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)) : null,
      trailing: current == mode ? const Icon(Icons.check_circle, color: AppColors.orange) : null,
      onTap: onTap,
    );
  }
}

class _BusinessSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>().business;
    if (business == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.orange, child: Icon(Icons.business, color: Colors.white, size: 20)),
            title: Text(business.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text('VAT: ${(business.vatRate * 100).toStringAsFixed(0)}% · ${business.currency}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditBusinessSheet(context, business),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessSheet(BuildContext ctx, dynamic business) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _BusinessEditSheet(business: business),
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
  late final TextEditingController _name, _address, _phone, _email, _vatNumber, _receiptFooter;
  late double _vatRate;
  late String _currency, _currencySymbol;

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _name = TextEditingController(text: b.name);
    _address = TextEditingController(text: b.address ?? '');
    _phone = TextEditingController(text: b.phone ?? '');
    _email = TextEditingController(text: b.email ?? '');
    _vatNumber = TextEditingController(text: b.vatNumber ?? '');
    _receiptFooter = TextEditingController(text: b.receiptFooter ?? '');
    _vatRate = b.vatRate;
    _currency = b.currency;
    _currencySymbol = b.currencySymbol;
  }

  @override
  void dispose() {
    _name.dispose(); _address.dispose(); _phone.dispose();
    _email.dispose(); _vatNumber.dispose(); _receiptFooter.dispose();
    super.dispose();
  }

  void _save() async {
    final bp = context.read<BusinessProvider>();
    await bp.updateBusiness(
      name: _name.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      vatNumber: _vatNumber.text.trim(),
      currency: _currency,
      currencySymbol: _currencySymbol,
      vatRate: _vatRate,
      receiptFooter: _receiptFooter.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Edit Business', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.business))),
          const SizedBox(height: 10),
          TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 10),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 10),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
          const SizedBox(height: 10),
          TextField(controller: _vatNumber, decoration: const InputDecoration(labelText: 'VAT Number', prefixIcon: Icon(Icons.receipt_long))),
          const SizedBox(height: 10),
          TextField(controller: _receiptFooter, maxLines: 2, decoration: const InputDecoration(labelText: 'Receipt Footer', prefixIcon: Icon(Icons.text_fields), hintText: 'Thank you for your support!')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: TextEditingController(text: _currency), readOnly: true, decoration: const InputDecoration(labelText: 'Currency'), onTap: () {})),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: TextEditingController(text: _currencySymbol), readOnly: true, decoration: const InputDecoration(labelText: 'Symbol'), onTap: () {})),
          ]),
          const SizedBox(height: 10),
          Text('VAT Rate: ${(_vatRate * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Slider(value: _vatRate, min: 0, max: 0.25, divisions: 25, activeColor: AppColors.orange, onChanged: (v) => setState(() => _vatRate = v)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
          const SizedBox(height: 14),
        ]),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        ListTile(
          leading: const CircleAvatar(backgroundColor: AppColors.brown, child: Icon(Icons.code, color: Colors.white, size: 20)),
          title: Text('Built by Shahid Singh', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text('Flutter 3.27 · Supabase · SQLite', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ),
        ListTile(
          leading: const CircleAvatar(backgroundColor: AppColors.orange, child: Icon(Icons.bug_report, color: Colors.white, size: 20)),
          title: Text('Report Issues', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          subtitle: Text('github.com/sudobreakstuff/spicedesk', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ),
      ]),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      icon: const Icon(Icons.logout, color: AppColors.red),
      label: Text('Sign Out', style: GoogleFonts.poppins(color: AppColors.red)),
      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red), minimumSize: const Size(double.infinity, 52)),
    );
  }
}

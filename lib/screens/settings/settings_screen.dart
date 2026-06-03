import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final b = context.watch<BusinessProvider>().business;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const SizedBox(height: 8),
        const _S('Appearance'),
        Card(
          child: SwitchListTile(
            title: const Text('Dark Mode'),
            value: tm.isDark,
            onChanged: (_) => tm.toggle(),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
        ),
        const _S('Business'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(b?.name ?? 'Not set', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('VAT: ${((b?.vatRate ?? 0.15) * 100).toStringAsFixed(0)}% · ${b?.currency ?? 'ZAR'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _ed(context, b),
            ),
          ]),
        ),
        const _S('About'),
        Card(
          child: Column(children: [
            const ListTile(leading: Icon(Icons.code), title: Text('Built by Shahid Singh'), subtitle: Text('Flutter · Supabase · SQLite', style: TextStyle(fontSize: 11, color: Colors.grey))),
          ]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  void _ed(BuildContext ctx, dynamic biz) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (c) {
        final nm = TextEditingController(text: biz?.name ?? '');
        final ad = TextEditingController(text: biz?.address ?? '');
        final ph = TextEditingController(text: biz?.phone ?? '');
        final vn = TextEditingController(text: biz?.vatNumber ?? '');
        final rf = TextEditingController(text: biz?.receiptFooter ?? '');
        double vr = biz?.vatRate ?? 0.15;
        return StatefulBuilder(builder: (context, setSt) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Edit Business', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                TextField(controller: nm, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8), TextField(controller: ad, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 8), TextField(controller: ph, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8), TextField(controller: vn, decoration: const InputDecoration(labelText: 'VAT Number')),
                const SizedBox(height: 8), TextField(controller: rf, decoration: const InputDecoration(labelText: 'Receipt Footer')),
                const SizedBox(height: 8),
                Row(children: [const Text('VAT Rate'), const Spacer(), Text('${(vr * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))]),
                Slider(value: vr, min: 0, max: 0.25, divisions: 25, onChanged: (v) => setSt(() => vr = v)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () async {
                  await ctx.read<BusinessProvider>().updateBusiness(name: nm.text.trim(), address: ad.text.trim(), phone: ph.text.trim(), vatNumber: vn.text.trim(), vatRate: vr, receiptFooter: rf.text.trim());
                  if (context.mounted) Navigator.pop(context);
                }, child: const Text('Save')),
                const SizedBox(height: 14),
              ]),
            ),
          );
        });
      },
    );
  }
}

class _S extends StatelessWidget {
  final String t;
  const _S(this.t);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 6), child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5)));
}

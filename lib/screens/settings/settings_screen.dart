import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/glass_theme.dart';
import '../../core/config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final bp = context.watch<BusinessProvider>();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Settings')),
      child: SafeArea(
        child: ListView(children: [
          const SizedBox(height: 10),
          _section('Appearance'),
          CupertinoListSection.insetGrouped(children: [
            CupertinoListTile(title: const Text('Dark Mode'), trailing: CupertinoSwitch(value: tm.isDark, onChanged: (_) => tm.toggle())),
          ]),
          _section('Business'),
          CupertinoListSection.insetGrouped(children: [
            CupertinoListTile(title: Text(bp.business?.name ?? 'Not set'), subtitle: Text('VAT: ${((bp.business?.vatRate ?? 0.15)*100).toStringAsFixed(0)}% · ${bp.business?.currency ?? 'ZAR'}'), trailing: const CupertinoListTileChevron(), onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => _EditSheet(business: bp.business)))),
          ]),
          _section('About'),
          CupertinoListSection.insetGrouped(children: [
            CupertinoListTile(title: const Text('Built by Shahid Singh'), subtitle: const Text('Flutter · Supabase · SQLite')),
            CupertinoListTile(title: const Text('Version'), subtitle: Text(AppConfig.appVersion)),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CupertinoButton(child: const Text('Sign Out', style: TextStyle(color: GlassColors.error)), onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
            }),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 6), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GlassColors.lightText2, letterSpacing: 0.5)));
}

class _EditSheet extends StatefulWidget {
  final dynamic business;
  const _EditSheet({required this.business});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _name = TextEditingController(text: widget.business?.name ?? ''), _address = TextEditingController(text: widget.business?.address ?? ''), _phone = TextEditingController(text: widget.business?.phone ?? '');
  late final _vat = TextEditingController(text: widget.business?.vatNumber ?? ''), _footer = TextEditingController(text: widget.business?.receiptFooter ?? '');
  double _vatRate = 0.15;

  @override
  void initState() { super.initState(); _vatRate = widget.business?.vatRate ?? 0.15; }
  @override
  void dispose() { _name.dispose(); _address.dispose(); _phone.dispose(); _vat.dispose(); _footer.dispose(); super.dispose(); }

  Future<void> _save() async {
    await context.read<BusinessProvider>().updateBusiness(name: _name.text.trim(), address: _address.text.trim(), phone: _phone.text.trim(), vatRate: _vatRate, vatNumber: _vat.text.trim(), receiptFooter: _footer.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: const Text('Edit Business')),
    child: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      CupertinoTextFormFieldRow(controller: _name, placeholder: 'Name', style: TextStyle(fontSize: 15, color: c.glassText)),
      const SizedBox(height: 10),
      CupertinoTextFormFieldRow(controller: _address, placeholder: 'Address', style: TextStyle(fontSize: 15, color: c.glassText)),
      const SizedBox(height: 10),
      CupertinoTextFormFieldRow(controller: _phone, placeholder: 'Phone', style: TextStyle(fontSize: 15, color: c.glassText)),
      const SizedBox(height: 10),
      CupertinoTextFormFieldRow(controller: _vat, placeholder: 'VAT Number', style: TextStyle(fontSize: 15, color: c.glassText)),
      const SizedBox(height: 10),
      CupertinoTextFormFieldRow(controller: _footer, placeholder: 'Receipt Footer', style: TextStyle(fontSize: 15, color: c.glassText)),
      const SizedBox(height: 10),
      Row(children: [Text('VAT Rate', style: TextStyle(fontSize: 13, color: c.glassText2)), const Spacer(), Text('${(_vatRate*100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GlassColors.primary))]),
      CupertinoSlider(value: _vatRate, min: 0, max: 0.25, divisions: 25, onChanged: (v) => setState(() => _vatRate = v)),
      const SizedBox(height: 18),
      CupertinoButton.filled(child: const Text('Save'), onPressed: _save),
      const SizedBox(height: 30),
    ])),
  );
}

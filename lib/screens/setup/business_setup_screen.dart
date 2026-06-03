import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../core/glass_theme.dart';
import '../dashboard/dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});
  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _name = TextEditingController(), _address = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController(), _vat = TextEditingController();
  double _vatRate = 0.15;
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _address.dispose(); _phone.dispose(); _email.dispose(); _vat.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    final bp = context.read<BusinessProvider>();
    await bp.createBusiness(name: _name.text.trim(), address: _address.text.trim(), phone: _phone.text.trim(), email: _email.text.trim(), vatRate: _vatRate, vatNumber: _vat.text.trim());
    setState(() => _saving = false);
    if (!mounted) return;
    if (bp.error != null) { showCupertinoDialog(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('Error'), content: Text(bp.error!), actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(_))])); return; }
    Navigator.of(context).pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => const DashboardScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext c) {
    final bp = context.watch<BusinessProvider>();
    return CupertinoPageScaffold(
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Container(width: 56, height: 56, decoration: BoxDecoration(color: GlassColors.primary, borderRadius: BorderRadius.circular(14)), child: const Center(child: Text('SD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFFFFFFF))))),
        const SizedBox(height: 18),
        Text('Set Up Your Business', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.glassText)),
        const SizedBox(height: 4),
        Text('Tell us about your shop', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.glassText2)),
        const SizedBox(height: 28),
        CupertinoTextFormFieldRow(controller: _name, placeholder: 'Business Name', style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _address, placeholder: 'Address', style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _phone, placeholder: 'Phone', keyboardType: TextInputType.phone, style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _email, placeholder: 'Email', keyboardType: TextInputType.emailAddress, style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 12),
        CupertinoTextFormFieldRow(controller: _vat, placeholder: 'VAT Number (optional)', style: TextStyle(fontSize: 15, color: c.glassText)),
        const SizedBox(height: 14),
        Row(children: [Text('VAT Rate', style: TextStyle(fontSize: 13, color: c.glassText2)), const Spacer(), Text('${(_vatRate*100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GlassColors.primary))]),
        CupertinoSlider(value: _vatRate, min: 0, max: 0.25, divisions: 25, onChanged: (v) => setState(() => _vatRate = v)),
        const SizedBox(height: 22),
        CupertinoButton.filled(onPressed: _saving ? null : _save, child: _saving ? const CupertinoActivityIndicator() : const Text('Create My Shop')),
        const SizedBox(height: 30),
      ]))),
    );
  }
}

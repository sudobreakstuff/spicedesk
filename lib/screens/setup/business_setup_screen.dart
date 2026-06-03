import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
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
    await bp.createBusiness(name: _name.text.trim(), address: _address.text.trim(), phone: _phone.text.trim(), email: _email.text.trim(), vatNumber: _vat.text.trim(), vatRate: _vatRate);
    setState(() => _saving = false);
    if (!mounted) return;
    if (bp.error != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bp.error!), backgroundColor: Colors.red)); return; }
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashboardScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext c) {
    final bp = context.watch<BusinessProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 20),
            const Icon(Icons.store, color: Colors.blue, size: 48),
            const SizedBox(height: 12),
            const Text('Set Up Your Business', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Tell us about your shop', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 28),
            TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.business)), onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            TextFormField(controller: _address, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 12),
            TextFormField(controller: _vat, decoration: const InputDecoration(labelText: 'VAT Number (optional)', prefixIcon: Icon(Icons.receipt_long))),
            const SizedBox(height: 12),
            Row(children: [const Text('VAT Rate', style: TextStyle(fontSize: 13)), const Spacer(), Text('${(_vatRate * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue))]),
            Slider(value: _vatRate, min: 0, max: 0.25, divisions: 25, onChanged: (v) => setState(() => _vatRate = v)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create My Shop')),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

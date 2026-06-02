import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/business_provider.dart';
import '../../core/app_theme.dart';
import '../dashboard/dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});
  @override
  State<BusinessSetupScreen> createState() => BusinessSetupScreenState();
}

class BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _address = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController(), _vatNum = TextEditingController();
  double _vat = 0.15;
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _address.dispose(); _phone.dispose(); _email.dispose(); _vatNum.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final bp = context.read<BusinessProvider>();
    await bp.createBusiness(name: _name.text.trim(), address: _address.text.trim(), phone: _phone.text.trim(), email: _email.text.trim(), vatNumber: _vatNum.text.trim(), vatRate: _vat);
    if (!mounted) return;
    setState(() => _saving = false);
    if (bp.error != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bp.error!), backgroundColor: SpiceColors.error, behavior: SnackBarBehavior.floating)); return; }
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashboardScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 20),
              Container(width: 56, height: 56, decoration: BoxDecoration(color: SpiceColors.primary, borderRadius: BorderRadius.circular(14)), child: const Center(child: Text('SD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)))),
              const SizedBox(height: 16),
              Text('Set Up Your Business', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Tell us about your shop', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary)),
              const SizedBox(height: 28),
              TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Business Name *'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _address, maxLines: 1, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Phone', hintText: '+27 81 234 5678')),
              const SizedBox(height: 12),
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextFormField(controller: _vatNum, decoration: const InputDecoration(labelText: 'VAT Number (optional)')),
              const SizedBox(height: 12),
              Row(children: [
                Text('VAT Rate', style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary)),
                const Spacer(),
                Text('${(_vat * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
              ]),
              Slider(value: _vat, min: 0, max: 0.25, divisions: 25, onChanged: (v) => setState(() => _vat = v)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create My Shop')),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

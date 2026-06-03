import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  double _vatRate = 0.15;
  String _country = 'South Africa';

  static const _countries = [
    'South Africa', 'Namibia', 'Botswana', 'Zimbabwe',
    'Mozambique', 'Zambia', 'Lesotho', 'Eswatini',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _vatCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final bp = context.read<BusinessProvider>();
    await bp.createBusiness(
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      vatNumber: _vatCtrl.text.trim(),
      vatRate: _vatRate,
      country: _country,
    );
    if (!mounted) return;
    if (bp.hasBusiness) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashboardScreen()), (_) => false);
    } else if (bp.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bp.error!), backgroundColor: T.e));
      bp.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = context.watch<AuthProvider>().userEmail ?? '';
    final bp = context.watch<BusinessProvider>();
    _emailCtrl.text = _emailCtrl.text.isEmpty ? userEmail : _emailCtrl.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Business')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.store)), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _addrCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
                const SizedBox(height: 14),
                TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 14),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 14),
                TextFormField(controller: _vatCtrl, decoration: const InputDecoration(labelText: 'VAT Number', prefixIcon: Icon(Icons.receipt_long_outlined))),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(labelText: 'Country', prefixIcon: Icon(Icons.public)),
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _country = v!),
                ),
                const SizedBox(height: 20),
                Text('VAT Rate: ${(_vatRate * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
                Slider(value: _vatRate, min: 0, max: 0.25, divisions: 25, label: '${(_vatRate * 100).toStringAsFixed(0)}%', onChanged: (v) => setState(() => _vatRate = v)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: bp.loading ? null : _create,
                    child: bp.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Create My Shop', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

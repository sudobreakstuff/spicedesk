import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/app_theme.dart';
import '../dashboard/dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});
  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _vatNumber = TextEditingController();
  final _currency = TextEditingController(text: 'ZAR');
  final _symbol = TextEditingController(text: 'R');
  double _vatRate = 0.15;
  String _country = 'South Africa';
  final _countries = ['South Africa', 'Namibia', 'Botswana', 'Zimbabwe', 'Mozambique', 'Zambia', 'Lesotho', 'Eswatini', 'Other'];

  @override
  void dispose() {
    _name.dispose(); _address.dispose(); _phone.dispose();
    _email.dispose(); _vatNumber.dispose(); _currency.dispose(); _symbol.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final bp = context.read<BusinessProvider>();
    await bp.createBusiness(
      name: _name.text.trim(), address: _address.text.trim(),
      phone: _phone.text.trim(), email: _email.text.trim(),
      vatNumber: _vatNumber.text.trim(), currency: _currency.text.trim(),
      currencySymbol: _symbol.text.trim(), vatRate: _vatRate, country: _country,
    );
    if (!mounted) return;
    if (bp.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bp.error!), backgroundColor: AppColors.red));
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashboardScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final bp = context.watch<BusinessProvider>();
    final isDark = tm.isDark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 16),
              Icon(Icons.store_rounded, size: 48, color: AppColors.orange),
              const SizedBox(height: 12),
              Text('Set Up Your Business', textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.brownDark)),
              const SizedBox(height: 4),
              Text('Tell us about your shop', textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _name, textInputAction: TextInputAction.next,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                decoration: InputDecoration(labelText: 'Business Name *', prefixIcon: const Icon(Icons.business), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address, maxLines: 2, textInputAction: TextInputAction.next,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                decoration: InputDecoration(labelText: 'Address', prefixIcon: const Icon(Icons.location_on_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                decoration: InputDecoration(labelText: 'Phone', prefixIcon: const Icon(Icons.phone_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
              ),
              const SizedBox(height: 20),
              Text('Tax & Currency', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.brownDark)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: InputDecoration(labelText: 'Country', prefixIcon: const Icon(Icons.public), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setState(() => _country = v); },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vatNumber, textInputAction: TextInputAction.next,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                decoration: InputDecoration(labelText: 'VAT Number (optional)', prefixIcon: const Icon(Icons.receipt_long), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(flex: 2, child: TextFormField(
                  controller: _currency,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                  decoration: InputDecoration(labelText: 'Currency', prefixIcon: const Icon(Icons.attach_money), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
                )),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: TextFormField(
                  controller: _symbol,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.brownDark),
                  decoration: InputDecoration(labelText: 'Symbol', prefixIcon: const Icon(Icons.monetization_on_outlined), fillColor: isDark ? AppColors.surfaceDark : Colors.white),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('VAT Rate', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.brownDark))),
                Text('${(_vatRate * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.orange)),
              ]),
              Slider(value: _vatRate, min: 0, max: 0.25, divisions: 25, activeColor: AppColors.orange, onChanged: (v) => setState(() => _vatRate = v)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: bp.loading ? null : _submit,
                child: bp.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create My Shop'),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/business_provider.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _currencyController = TextEditingController(text: 'ZAR');
  final _currencySymbolController = TextEditingController(text: 'R');
  double _vatRate = 0.15;
  String _country = 'South Africa';

  final List<String> _countries = [
    'South Africa',
    'Namibia',
    'Botswana',
    'Zimbabwe',
    'Mozambique',
    'Zambia',
    'Lesotho',
    'Eswatini',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vatNumberController.dispose();
    _currencyController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final businessProvider = context.read<BusinessProvider>();
    await businessProvider.createBusiness(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      vatNumber: _vatNumberController.text.trim(),
      currency: _currencyController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      vatRate: _vatRate,
      country: _country,
    );

    if (!mounted) return;

    if (businessProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(businessProvider.error!),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<BusinessProvider>(
            builder: (context, businessProvider, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.store_rounded,
                      size: 56,
                      color: AppTheme.spiceOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set Up Your Business',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSpice,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your shop',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Business Name *',
                        prefixIcon: Icon(Icons.business),
                        hintText: 'e.g. Mum\'s Savories',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: 'Physical address or area',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Business Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+27 81 234 5678',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Business Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'orders@mumssavories.co.za',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tax & Currency Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSpice,
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _country,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.public),
                      ),
                      items: _countries.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _country = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _vatNumberController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'VAT Number (optional)',
                        prefixIcon: Icon(Icons.receipt_long),
                        hintText: 'SARS VAT registration number',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _currencySymbolController,
                            decoration: const InputDecoration(
                              labelText: 'Symbol',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'VAT Rate',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkSpice,
                            ),
                          ),
                        ),
                        Text(
                          '${(_vatRate * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.spiceOrange,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _vatRate,
                      min: 0,
                      max: 0.25,
                      divisions: 25,
                      activeColor: AppTheme.spiceOrange,
                      label: '${(_vatRate * 100).toStringAsFixed(0)}%',
                      onChanged: (value) {
                        setState(() => _vatRate = value);
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed:
                          businessProvider.loading ? null : _handleSubmit,
                      child: businessProvider.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create My Shop'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

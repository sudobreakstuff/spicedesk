import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/customer_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/app_theme.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) context.read<CustomerProvider>().loadCustomers(b.id);
    });
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CustomerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _search,
            style: TextStyle(fontSize: 13, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary),
            decoration: InputDecoration(hintText: 'Search customers...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(vertical: 10), isDense: true, suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _search.clear(); cp.setSearchQuery(null); }) : null),
            onChanged: (v) => cp.setSearchQuery(v.isEmpty ? null : v),
          ),
        ),
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isDark ? SpiceColors.darkSurface : SpiceColors.surfaceAlt,
          child: Row(children: [
            const SizedBox(width: 36),
            const Expanded(flex: 2, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5))),
            const Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5))),
            const SizedBox(width: 44),
          ]),
        ),
        Expanded(
          child: cp.loading && cp.customers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : cp.customers.isEmpty
              ? _empty(context)
              : ListView.builder(
                  itemCount: cp.customers.length,
                  itemBuilder: (_, i) => _CustomerRow(customer: cp.customers[i]),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Add Customer', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: SpiceColors.primaryBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.people_outline, color: SpiceColors.primaryLight, size: 28)),
      const SizedBox(height: 12),
      Text('No customers', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () => _showForm(), child: const Text('Add Customer')),
    ]),
  );

  void _showForm({dynamic customer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) => _CustomerForm(customer: customer),
    ).then((_) { final b = context.read<BusinessProvider>().business; if (b != null) context.read<CustomerProvider>().loadCustomers(b.id); });
  }
}

class _CustomerRow extends StatelessWidget {
  final dynamic customer;
  const _CustomerRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = customer.phone as String?;
    return InkWell(
      onTap: () {
        final listScreen = context.findAncestorStateOfType<_CustomerListScreenState>();
        listScreen?._showForm(customer: customer);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder))),
        child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: SpiceColors.primaryBg, child: Text('${(customer.name as String)[0]}'.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primaryLight))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: Text(customer.name as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary))),
          Expanded(flex: 2, child: Text(phone ?? '—', style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.textSecondary))),
          if (phone != null)
            IconButton(icon: Icon(Icons.chat_bubble_outline, size: 18, color: const Color(0xFF25D366)), onPressed: () async {
              final num = phone.replaceAll(RegExp(r'[^\d]'), '');
              final uri = Uri.parse('https://wa.me/$num');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
      ),
    );
  }
}

class _CustomerForm extends StatefulWidget {
  final dynamic customer;
  const _CustomerForm({this.customer});
  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController(), _address = TextEditingController(), _notes = TextEditingController();
  bool _saving = false;
  bool get _edit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_edit) { final c = widget.customer!; _name.text = c.name ?? ''; _phone.text = c.phone ?? ''; _email.text = c.email ?? ''; _address.text = c.address ?? ''; _notes.text = c.notes ?? ''; }
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); _address.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final bp = context.read<BusinessProvider>();
    final cp = context.read<CustomerProvider>();
    if (bp.business == null) { setState(() => _saving = false); return; }
    try {
      if (_edit) {
        await cp.updateCustomer(widget.customer!.copyWith(name: _name.text.trim(), phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(), email: _email.text.trim().isEmpty ? null : _email.text.trim(), address: _address.text.trim().isEmpty ? null : _address.text.trim(), notes: _notes.text.trim().isEmpty ? null : _notes.text.trim()));
      } else {
        await cp.createCustomer(businessId: bp.business!.id, name: _name.text.trim(), phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(), email: _email.text.trim().isEmpty ? null : _email.text.trim(), address: _address.text.trim().isEmpty ? null : _address.text.trim(), notes: _notes.text.trim().isEmpty ? null : _notes.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: SpiceColors.error, behavior: SnackBarBehavior.floating));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_edit ? 'Edit Customer' : 'New Customer', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (WhatsApp)', hintText: '+27 81 234 5678')),
          const SizedBox(height: 10),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextFormField(controller: _address, maxLines: 1, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 10),
          TextFormField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_edit ? 'Update' : 'Save Customer')),
          if (_edit) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () { context.read<CustomerProvider>().deleteCustomer(widget.customer!.id); Navigator.pop(context); }, style: OutlinedButton.styleFrom(foregroundColor: SpiceColors.error), child: const Text('Delete')),
          ],
          const SizedBox(height: 14),
        ]),
      ),
    );
  }
}

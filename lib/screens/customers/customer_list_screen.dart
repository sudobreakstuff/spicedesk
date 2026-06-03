import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/customer_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/glass_theme.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  void _load() { final b = context.read<BusinessProvider>().business; if (b != null) context.read<CustomerProvider>().loadCustomers(b.id); }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  @override
  Widget build(BuildContext c) {
    final cp = context.watch<CustomerProvider>();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Customers'), trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.person_add), onPressed: () => _showForm())),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Container(decoration: GlassTheme.glassCard(c.isGlassDark), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: CupertinoSearchTextField(placeholder: 'Search customers...', onChanged: (v) => cp.setSearchQuery(v.isEmpty ? null : v))))),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: c.isGlassDark ? const Color(0x33000000) : const Color(0x33C7C7CC), child: Row(children: const [SizedBox(width: 36), Expanded(flex: 2, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2))), Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2))), SizedBox(width: 40)])),
          Expanded(
            child: cp.loading && cp.customers.isEmpty ? const Center(child: CupertinoActivityIndicator()) :
              cp.customers.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(CupertinoIcons.person_2, size: 40, color: c.glassText3), const SizedBox(height: 10),
                const Text('No customers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10), CupertinoButton.filled(child: const Text('Add Customer'), onPressed: () => _showForm()),
              ])) :
              ListView.builder(itemCount: cp.customers.length, itemBuilder: (_, i) => _Row(customer: cp.customers[i], onTap: () => _showForm(customer: cp.customers[i]), onReload: _load)),
          ),
        ]),
      ),
    );
  }

  void _showForm({dynamic customer}) {
    showCupertinoModalPopup(context: context, builder: (_) => _Form(customer: customer)).then((_) => _load());
  }
}

class _Row extends StatelessWidget {
  final dynamic customer; final VoidCallback onTap; final VoidCallback onReload;
  const _Row({required this.customer, required this.onTap, required this.onReload});
  @override
  Widget build(BuildContext c) {
    final phone = customer.phone as String?;
    return CupertinoButton(
      padding: EdgeInsets.zero, alignment: Alignment.centerLeft, onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.glassBorder.withValues(alpha: 0.3), width: 0.5))),
        child: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: GlassColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Center(child: Text((customer.name as String)[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GlassColors.purple)))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: Text(customer.name ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.glassText))),
          Expanded(flex: 2, child: Text(phone ?? '—', style: TextStyle(fontSize: 13, color: c.glassText2))),
          if (phone != null) CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.chat_bubble, size: 18, color: const Color(0xFF25D366)), onPressed: () async {
            final num = phone.replaceAll(RegExp(r'[^\d]'), '');
            final uri = Uri.parse('https://wa.me/$num');
            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
          }),
        ]),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  final dynamic customer;
  const _Form({this.customer});
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController(), _address = TextEditingController(), _notes = TextEditingController();
  bool _saving = false; String? _error;
  bool get _edit => widget.customer != null;

  @override
  void initState() { super.initState(); if (_edit) { final c = widget.customer!; _name.text = c.name ?? ''; _phone.text = c.phone ?? ''; _email.text = c.email ?? ''; _address.text = c.address ?? ''; _notes.text = c.notes ?? ''; } }
  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); _address.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final bp = context.read<BusinessProvider>();
    if (bp.business == null) { await bp.loadBusiness(); if (bp.business == null) { setState(() { _saving = false; _error = 'Could not load business. Restart the app.'; }); return; } }
    try {
      if (_edit) {
        await context.read<CustomerProvider>().updateCustomer(widget.customer!.copyWith(name: _name.text.trim(), phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(), email: _email.text.trim().isEmpty ? null : _email.text.trim(), address: _address.text.trim().isEmpty ? null : _address.text.trim(), notes: _notes.text.trim().isEmpty ? null : _notes.text.trim()));
      } else {
        await context.read<CustomerProvider>().createCustomer(businessId: bp.business!.id, name: _name.text.trim(), phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(), email: _email.text.trim().isEmpty ? null : _email.text.trim(), address: _address.text.trim().isEmpty ? null : _address.text.trim(), notes: _notes.text.trim().isEmpty ? null : _notes.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) { setState(() => _error = e.toString()); }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext c) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: Text(_edit ? 'Edit Customer' : 'New Customer')),
    child: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
      if (_error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: GlassColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(_error!, style: const TextStyle(color: GlassColors.error, fontSize: 13))),
      _field('Full Name', _name, validator: (v) => (v??'').trim().isEmpty ? 'Required' : null),
      const SizedBox(height: 14),
      _field('Phone (WhatsApp)', _phone, keyboard: TextInputType.phone, hint: '+27 81 234 5678'),
      const SizedBox(height: 14),
      _field('Email', _email, keyboard: TextInputType.emailAddress),
      const SizedBox(height: 14),
      _field('Address', _address),
      const SizedBox(height: 14),
      _field('Notes', _notes, maxLines: 2),
      const SizedBox(height: 24),
      CupertinoButton.filled(onPressed: _saving ? null : _save, child: _saving ? const CupertinoActivityIndicator() : Text(_edit ? 'Update' : 'Save Customer')),
      if (_edit) ...[const SizedBox(height: 8), CupertinoButton(child: const Text('Delete', style: TextStyle(color: GlassColors.error)), onPressed: () async {
        final ok = await showCupertinoDialog<bool>(context: c, builder: (_) => CupertinoAlertDialog(title: const Text('Delete?'), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(_, false)), CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.pop(_, true))]));
        if (ok == true) { await c.read<CustomerProvider>().deleteCustomer(widget.customer!.id); if (mounted) Navigator.pop(c); }
      })],
      const SizedBox(height: 30),
    ])),
  );

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: context.glassText2)),
      const SizedBox(height: 4),
      CupertinoTextFormFieldRow(controller: ctrl, maxLines: maxLines, keyboardType: keyboard, placeholder: hint, style: TextStyle(fontSize: 15, color: context.glassText), validator: validator),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/customer_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/customer.dart';

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

  void _openForm([Customer? c]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (_) => _CustomerFormSheet(customer: c));

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final cp = context.watch<CustomerProvider>();
    final t2 = d ? T.dt2 : T.t2, hasQ = _search.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(), label: const Text('Add Customer'), icon: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(
          controller: _search, decoration: InputDecoration(hintText: 'Search customers...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: hasQ ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _search.clear(); cp.setSearchQuery(null); }) : null),
          onChanged: (v) => cp.setSearchQuery(v.isEmpty ? null : v))),
        const Divider(height: 1),
        Expanded(child: cp.loading
          ? const Center(child: CircularProgressIndicator())
          : cp.customers.isEmpty
            ? Center(child: Text('No customers found', style: Theme.of(context).textTheme.bodyMedium))
            : ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
                  const SizedBox(width: 36),
                  Expanded(child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2))),
                  SizedBox(width: 120, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2))),
                  const SizedBox(width: 44)])),
                ...cp.customers.map((c) => InkWell(onTap: () => _openForm(c),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: T.pBg, child: Text(c.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.p))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 120, child: Text(c.phone ?? '', style: TextStyle(fontSize: 12, color: T.t2), overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 40, child: c.phone != null
                      ? IconButton(icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)), onPressed: () async {
                          final uri = Uri.parse(c.whatsappUri);
                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); })
                      : null),
                    ])))),

              ])),
      ]));
  }
}

class _CustomerFormSheet extends StatefulWidget {
  final Customer? customer;
  const _CustomerFormSheet({this.customer});
  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _k = GlobalKey<FormState>();
  late final _n = TextEditingController(), _p = TextEditingController(), _e = TextEditingController();
  late final _a = TextEditingController(), _nt = TextEditingController();
  bool _sv = false;
  bool get _ed => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _n.text = widget.customer?.name ?? '';
    _p.text = widget.customer?.phone ?? '';
    _e.text = widget.customer?.email ?? '';
    _a.text = widget.customer?.address ?? '';
    _nt.text = widget.customer?.notes ?? '';
  }
  @override
  void dispose() { _n.dispose(); _p.dispose(); _e.dispose(); _a.dispose(); _nt.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_k.currentState!.validate()) return;
    setState(() => _sv = true);
    final cp = context.read<CustomerProvider>(), bp = context.read<BusinessProvider>();
    var bid = bp.business?.id;
    if (bid == null) { await bp.loadBusiness(); bid = bp.business?.id; }
    if (bid == null) { if (mounted) { setState(() => _sv = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No business found'))); } return; }
    try {
      if (_ed) {
        await cp.updateCustomer(widget.customer!.copyWith(name: _n.text.trim(),
          phone: _p.text.trim().isEmpty ? null : _p.text.trim(), email: _e.text.trim().isEmpty ? null : _e.text.trim(),
          address: _a.text.trim().isEmpty ? null : _a.text.trim(), notes: _nt.text.trim().isEmpty ? null : _nt.text.trim()));
      } else {
        final r = await cp.createCustomer(businessId: bid, name: _n.text.trim(),
          phone: _p.text.trim().isEmpty ? null : _p.text.trim(), email: _e.text.trim().isEmpty ? null : _e.text.trim(),
          address: _a.text.trim().isEmpty ? null : _a.text.trim(), notes: _nt.text.trim().isEmpty ? null : _nt.text.trim());
        if (r == null) throw Exception(cp.error ?? 'Create failed');
      }
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ed ? 'Customer updated' : 'Customer created'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: T.e)); }
    if (mounted) setState(() => _sv = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Customer'), content: Text('Delete "${widget.customer!.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: T.e)))]));
    if (ok == true && mounted) { await context.read<CustomerProvider>().deleteCustomer(widget.customer!.id); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted'))); } }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), child: Form(key: _k,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: T.t3))),
          const SizedBox(height: 16),
          TextFormField(controller: _n, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _p, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          TextFormField(controller: _e, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          TextFormField(controller: _a, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
          const SizedBox(height: 12),
          TextFormField(controller: _nt, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _sv ? null : _save, child: _sv ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_ed ? 'Update Customer' : 'Save Customer')),
          if (_ed) ...[const SizedBox(height: 10), OutlinedButton(onPressed: _delete, style: OutlinedButton.styleFrom(foregroundColor: T.e), child: const Text('Delete Customer'))],
          const SizedBox(height: 8),
        ]))));
  }
}

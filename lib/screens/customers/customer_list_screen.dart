import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/customer_provider.dart';
import '../../providers/business_provider.dart';

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
    return Scaffold(
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), onChanged: (v) => cp.setSearchQuery(v.isEmpty ? null : v))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [SizedBox(width: 36), Expanded(flex:2,child:Text('NAME',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.grey))),Expanded(flex:2,child:Text('PHONE',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.grey))),SizedBox(width:44)])),
        Expanded(
          child: cp.customers.isEmpty ? Center(child: Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.people_outline,size:48,color:Colors.grey),const SizedBox(height:12),const Text('No customers',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600)),const SizedBox(height:8),ElevatedButton(onPressed:()=>_showForm(),child:const Text('Add Customer'))])) :
          ListView.builder(itemCount: cp.customers.length, itemBuilder: (_, i) {
            final cu = cp.customers[i];
            return ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text(cu.name[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))),
              title: Text(cu.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(cu.phone ?? '—', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (cu.phone != null) IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20), onPressed: () async { final n = cu.phone!.replaceAll(RegExp(r'[^\d]'), ''); final u = Uri.parse('https://wa.me/$n'); if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication); }),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showForm(customer: cu)),
              ]),
              onTap: () => _showForm(customer: cu),
            );
          }),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showForm(), icon: const Icon(Icons.person_add), label: const Text('Add Customer')),
    );
  }

  void _showForm({dynamic customer}) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (_) => _Form(customer: customer)).then((_) => _load());
  }
}

class _Form extends StatefulWidget { final dynamic customer; const _Form({this.customer}); @override State<_Form> createState() => _FormState(); }
class _FormState extends State<_Form> {
  final _k = GlobalKey<FormState>();
  final _n = TextEditingController(), _p = TextEditingController(), _e = TextEditingController(), _a = TextEditingController(), _nt = TextEditingController();
  bool _sv = false;
  bool get _ed => widget.customer != null;

  @override
  void initState() { super.initState(); final x = widget.customer; if (x != null) { _n.text = x.name ?? ''; _p.text = x.phone ?? ''; _e.text = x.email ?? ''; _a.text = x.address ?? ''; _nt.text = x.notes ?? ''; } }
  @override
  void dispose() { _n.dispose(); _p.dispose(); _e.dispose(); _a.dispose(); _nt.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_k.currentState!.validate()) return;
    setState(() => _sv = true);
    final bp = context.read<BusinessProvider>();
    if (bp.business == null) { await bp.loadBusiness(); if (bp.business == null) { setState(() => _sv = false); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load business'), backgroundColor: Colors.red)); return; } }
    final cp = context.read<CustomerProvider>();
    try {
      if (_ed) { await cp.updateCustomer(widget.customer!.copyWith(name: _n.text.trim(), phone: _p.text.trim().isEmpty ? null : _p.text.trim(), email: _e.text.trim().isEmpty ? null : _e.text.trim(), address: _a.text.trim().isEmpty ? null : _a.text.trim(), notes: _nt.text.trim().isEmpty ? null : _nt.text.trim())); }
      else { await cp.createCustomer(businessId: bp.business!.id, name: _n.text.trim(), phone: _p.text.trim().isEmpty ? null : _p.text.trim(), email: _e.text.trim().isEmpty ? null : _e.text.trim(), address: _a.text.trim().isEmpty ? null : _a.text.trim(), notes: _nt.text.trim().isEmpty ? null : _nt.text.trim()); }
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
    setState(() => _sv = false);
  }

  @override
  Widget build(BuildContext c) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20), child: Form(key: _k, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(_ed ? 'Edit Customer' : 'New Customer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 14),
    TextFormField(controller: _n, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
    const SizedBox(height: 10), TextFormField(controller: _p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (WhatsApp)')),
    const SizedBox(height: 10), TextFormField(controller: _e, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
    const SizedBox(height: 10), TextFormField(controller: _a, decoration: const InputDecoration(labelText: 'Address')),
    const SizedBox(height: 10), TextFormField(controller: _nt, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
    const SizedBox(height: 14),
    ElevatedButton(onPressed: _sv ? null : _save, child: _sv ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_ed ? 'Update' : 'Save Customer')),
    if (_ed) ...[const SizedBox(height: 8), TextButton(onPressed: () { context.read<CustomerProvider>().deleteCustomer(widget.customer!.id); Navigator.pop(c); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))],
    const SizedBox(height: 14),
  ])));
}

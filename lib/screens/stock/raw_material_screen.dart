import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/raw_material.dart';
import '../../providers/business_provider.dart';
import '../../services/database_service.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class RawMaterialScreen extends StatefulWidget {
  const RawMaterialScreen({super.key});
  @override
  State<RawMaterialScreen> createState() => _RawMaterialScreenState();
}

class _RawMaterialScreenState extends State<RawMaterialScreen> {
  List<RawMaterial> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final b = context.read<BusinessProvider>().business;
    if (b == null) return;
    final rows = await DatabaseService.query(
      'SELECT * FROM raw_materials WHERE business_id = ? ORDER BY name',
      [b.id],
    );
    setState(() {
      _items = rows.map((e) => RawMaterial.fromMap(e)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raw Stock')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.grain, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No raw materials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => _showForm(), child: const Text('Add Raw Material')),
            ]))
          : Column(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [
                Expanded(flex: 3, child: Text('MATERIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey))),
                Expanded(flex: 1, child: Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('COST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.right)),
                SizedBox(width: 52),
              ])),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final m = _items[i];
                    return InkWell(
                      onTap: () => _showForm(item: m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: Row(children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            if (m.supplier != null) Text(m.supplier!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ])),
                          Expanded(flex: 1, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: m.isLow ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text('${m.quantity.toStringAsFixed(1)} ${m.unit}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: m.isLow ? Colors.orange : Colors.green)),
                          )),
                          Expanded(flex: 2, child: Text(AppConstants.formatCurrency(m.costPerUnit), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: () => _adjust(m, -0.5), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue), onPressed: () => _adjust(m, 0.5), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ])),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Add Material')),
    );
  }

  Future<void> _adjust(RawMaterial m, double delta) async {
    final newQty = m.quantity + delta;
    if (newQty < 0) return;
    final updated = m.copyWith(quantity: newQty);
    await DatabaseService.update('raw_materials', updated.toMap(), where: 'id = ?', whereArgs: [m.id]);
    _load();
  }

  void _showForm({RawMaterial? item}) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    builder: (_) => _RawForm(item: item),
  ).then((_) => _load());

  void _delete(RawMaterial m) async {
    await DatabaseService.delete('raw_materials', where: 'id = ?', whereArgs: [m.id]);
    _load();
  }
}

class _RawForm extends StatefulWidget {
  final RawMaterial? item;
  const _RawForm({this.item});
  @override
  State<_RawForm> createState() => _RawFormState();
}

class _RawFormState extends State<_RawForm> {
  final _k = GlobalKey<FormState>();
  final _n = TextEditingController(), _q = TextEditingController(), _u = TextEditingController(text: 'kg'), _c = TextEditingController(), _rl = TextEditingController(), _s = TextEditingController(), _nt = TextEditingController();
  bool _sv = false;
  bool get _ed => widget.item != null;

  @override
  void initState() {
    super.initState();
    final x = widget.item;
    if (x != null) {
      _n.text = x.name; _q.text = x.quantity.toString(); _u.text = x.unit;
      _c.text = x.costPerUnit.toString(); _rl.text = x.reorderLevel.toString();
      _s.text = x.supplier ?? ''; _nt.text = x.notes ?? '';
    }
  }

  @override
  void dispose() { _n.dispose(); _q.dispose(); _u.dispose(); _c.dispose(); _rl.dispose(); _s.dispose(); _nt.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_k.currentState!.validate() || _n.text.trim().isEmpty) return;
    setState(() => _sv = true);
    final b = context.read<BusinessProvider>().business;
    if (b == null) { setState(() => _sv = false); return; }
    final uuid = const Uuid();
    final now = DateTime.now();
    final data = {
      'business_id': b.id,
      'name': _n.text.trim(),
      'quantity': double.tryParse(_q.text) ?? 0,
      'unit': _u.text.trim(),
      'cost_per_unit': double.tryParse(_c.text) ?? 0,
      'reorder_level': double.tryParse(_rl.text) ?? 0,
      'supplier': _s.text.trim().isEmpty ? null : _s.text.trim(),
      'notes': _nt.text.trim().isEmpty ? null : _nt.text.trim(),
      'updated_at': now.toIso8601String(),
    };
    if (_ed) {
      await DatabaseService.update('raw_materials', data, where: 'id = ?', whereArgs: [widget.item!.id]);
    } else {
      data['id'] = uuid.v4();
      data['created_at'] = now.toIso8601String();
      await DatabaseService.insert('raw_materials', data);
    }
    setState(() => _sv = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
    child: Form(key: _k, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_ed ? 'Edit Material' : 'Add Raw Material', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      TextFormField(controller: _n, decoration: const InputDecoration(labelText: 'Name')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(controller: _q, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _u, decoration: const InputDecoration(labelText: 'Unit'))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(controller: _c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost/Unit (R)'))),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _rl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder at'))),
      ]),
      const SizedBox(height: 10),
      TextFormField(controller: _s, decoration: const InputDecoration(labelText: 'Supplier')),
      const SizedBox(height: 10),
      TextFormField(controller: _nt, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
      const SizedBox(height: 14),
      ElevatedButton(onPressed: _sv ? null : _save, child: _sv ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_ed ? 'Update' : 'Save')),
      if (_ed) ...[const SizedBox(height: 8), TextButton(onPressed: () { _rawFormState.deleteIfExists; Navigator.pop(c); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))],
      const SizedBox(height: 14),
    ])),
  );

  _RawFormState get _rawFormState => this;
  void deleteIfExists() { if (widget.item != null) { _delete(); } }
  Future<void> _delete() async {
    final b = context.read<BusinessProvider>().business;
    if (b == null || widget.item == null) return;
    await DatabaseService.delete('raw_materials', where: 'id = ?', whereArgs: [widget.item!.id]);
  }
}

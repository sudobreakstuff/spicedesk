import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/constants.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _catFilter;
  bool _lowStock = false;

  void _load() {
    final b = context.read<BusinessProvider>().business;
    if (b != null) context.read<ProductProvider>().loadProducts(b.id);
  }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  @override
  Widget build(BuildContext c) {
    final pp = context.watch<ProductProvider>();
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v),
          ),
        ),
        SizedBox(height: 30, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
          _chip('All', _catFilter == null, () { setState(() { _catFilter = null; pp.setCategoryFilter(null); }); }),
          ...pp.categories.take(8).map((c) => _chip(c.name, _catFilter == c.id, () { setState(() { _catFilter = c.id; pp.setCategoryFilter(c.id); }); })),
          _chip('Low', _lowStock, () { setState(() { _lowStock = !_lowStock; if (_lowStock) pp.toggleLowStockOnly(); else pp.clearFilters(); }); }),
        ])),
        const SizedBox(height: 4),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [
          SizedBox(width: 32), Expanded(flex: 3, child: Text('PRODUCT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey))),
          Expanded(flex: 2, child: Text('PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text('STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.center)),
          SizedBox(width: 52),
        ])),
        Expanded(
          child: pp.products.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey), const SizedBox(height: 12), const Text('No products yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), ElevatedButton(onPressed: () => _form(), child: const Text('Add Product'))]))
            : ListView.builder(itemCount: pp.products.length, itemBuilder: (_, i) {
                final p = pp.products[i];
                final low = (p.stockQty as int) <= (p.lowStockThreshold as int? ?? 5);
                return InkWell(
                  onTap: () => _form(product: p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.inventory_2, color: Colors.blue, size: 14)),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        if (p.description != null && p.description!.isNotEmpty) Text(p.description!, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      Expanded(flex: 2, child: Text(AppConstants.formatCurrency(p.price), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      Expanded(flex: 1, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: low ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text('${p.stockQty}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: low ? Colors.orange : Colors.green)),
                      )),
                      SizedBox(width: 60, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: () => pp.adjustStock(p.id, -1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue), onPressed: () => pp.adjustStock(p.id, 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ])),
                    ]),
                  ),
                );
              }),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Add Product')),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: active ? Colors.blue : null, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? Colors.blue : Colors.grey.shade300)), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : Colors.grey.shade700))),
      ),
    );
  }

  void _form({dynamic product}) => Navigator.push(context, MaterialPageRoute(builder: (_) => _ProductForm(product: product))).then((_) => _load());
}

class _ProductForm extends StatefulWidget {
  final dynamic product;
  const _ProductForm({this.product});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _k = GlobalKey<FormState>();
  final _n = TextEditingController(), _p = TextEditingController(), _c = TextEditingController(), _q = TextEditingController(text: '0'), _b = TextEditingController(), _d = TextEditingController();
  String? _cid;
  double _th = 5;
  bool _sv = false;
  bool get _ed => widget.product != null;

  @override
  void initState() {
    super.initState();
    final x = widget.product;
    if (x != null) { _n.text = x.name ?? ''; _p.text = x.price.toString(); _c.text = x.costPrice.toString(); _q.text = '${x.stockQty}'; _b.text = x.barcode ?? ''; _d.text = x.description ?? ''; _cid = x.categoryId; _th = (x.lowStockThreshold ?? 5).toDouble(); }
  }

  @override
  void dispose() { _n.dispose(); _p.dispose(); _c.dispose(); _q.dispose(); _b.dispose(); _d.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_k.currentState!.validate()) return;
    setState(() => _sv = true);
    final bp = context.read<BusinessProvider>();
    if (bp.business == null) { await bp.loadBusiness(); if (bp.business == null) { setState(() => _sv = false); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load business'), backgroundColor: Colors.red)); return; } }
    final pp = context.read<ProductProvider>();
    try {
      if (_ed) {
        await pp.updateProduct(widget.product!.copyWith(name: _n.text.trim(), description: _d.text.trim(), price: double.tryParse(_p.text) ?? 0, costPrice: double.tryParse(_c.text) ?? 0, stockQty: int.tryParse(_q.text) ?? 0, barcode: _b.text.trim(), categoryId: _cid, lowStockThreshold: _th.toInt()));
      } else {
        await pp.createProduct(businessId: bp.business!.id, name: _n.text.trim(), description: _d.text.trim(), price: double.tryParse(_p.text) ?? 0, costPrice: double.tryParse(_c.text) ?? 0, stockQty: int.tryParse(_q.text) ?? 0, barcode: _b.text.trim(), categoryId: _cid, lowStockThreshold: _th.toInt());
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ed ? 'Updated' : 'Created'))); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
    setState(() => _sv = false);
  }

  @override
  Widget build(BuildContext c) {
    final cats = context.watch<ProductProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: Text(_ed ? 'Edit Product' : 'New Product'), actions: _ed ? [IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
        final ok = await showDialog<bool>(context: c, builder: (_) => AlertDialog(title: const Text('Delete?'), actions: [TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
        if (ok == true) { await context.read<ProductProvider>().deleteProduct(widget.product!.id); if (mounted) Navigator.pop(c); }
      })] : null),
      body: Form(key: _k, child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _n, decoration: const InputDecoration(labelText: 'Product Name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _cid, decoration: const InputDecoration(labelText: 'Category'), items: [const DropdownMenuItem(value: null, child: Text('None')), ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))], onChanged: (v) => setState(() => _cid = v)),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: TextFormField(controller: _p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (R)'), validator: (v) => (v ?? '').isEmpty ? 'Required' : null)), const SizedBox(width: 10), Expanded(child: TextFormField(controller: _c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (R)')))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: TextFormField(controller: _q, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Qty'))), const SizedBox(width: 10), Expanded(child: TextFormField(controller: _b, decoration: const InputDecoration(labelText: 'Barcode')))]),
        const SizedBox(height: 12),
        TextFormField(controller: _d, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 12),
        Row(children: [const Text('Low stock alert:', style: TextStyle(fontSize: 13)), const Spacer(), Text('${_th.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]),
        Slider(value: _th, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _th = v)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _sv ? null : _save, child: _sv ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_ed ? 'Save Changes' : 'Create Product')),
        const SizedBox(height: 30),
      ])),
    );
  }
}

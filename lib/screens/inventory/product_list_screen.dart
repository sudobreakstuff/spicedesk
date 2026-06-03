import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/theme.dart';
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
    final isDark = Theme.of(c).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v),
          ),
        ),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('All', _catFilter == null, () { setState(() { _catFilter = null; pp.setCategoryFilter(null); }); }),
              ...pp.categories.take(8).map((c) => _chip(c.name, _catFilter == c.id, () { setState(() { _catFilter = c.id; pp.setCategoryFilter(c.id); }); })),
              _chip('Low Stock', _lowStock, () { setState(() { _lowStock = !_lowStock; if (_lowStock) pp.toggleLowStockOnly(); else pp.clearFilters(); }); }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          child: const Row(children: [
            SizedBox(width: 32),
            Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: T.t2))),
            Expanded(flex: 2, child: Text('Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: T.t2), textAlign: TextAlign.right)),
            Expanded(flex: 1, child: Text('Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: T.t2), textAlign: TextAlign.center)),
            SizedBox(width: 52),
          ]),
        ),
        Expanded(
          child: pp.products.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? T.dt3 : T.t3),
                const SizedBox(height: 12),
                const Text('No products yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => _showForm(), child: const Text('Add Product')),
              ]))
            : ListView.builder(itemCount: pp.products.length, itemBuilder: (_, i) {
                final p = pp.products[i];
                final low = (p.stockQty as int) <= (p.lowStockThreshold as int);
                return InkWell(
                  onTap: () => _showForm(product: p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? T.dbd : T.bd))),
                    child: Row(children: [
                      Container(width: 28, height: 28, decoration: BoxDecoration(color: T.pBg, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.inventory_2, color: T.p, size: 14)),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          if (p.description != null && (p.description as String).isNotEmpty)
                            Text(p.description as String, style: TextStyle(fontSize: 11, color: isDark ? T.dt3 : T.t3), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      Expanded(flex: 2, child: Text(AppConstants.formatCurrency((p.price as num).toDouble()), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: low ? T.wBg : T.sBg, borderRadius: BorderRadius.circular(4)),
                          child: Text('${p.stockQty}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: low ? T.w : T.s)),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: () => pp.adjustStock(p.id, -1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: T.p), onPressed: () => pp.adjustStock(p.id, 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        ]),
                      ),
                    ]),
                  ),
                );
              }),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Add Product')),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: active ? T.p : null, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? T.p : T.bd)),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : T.t2)),
        ),
      ),
    );
  }

  void _showForm({dynamic product}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ProductForm(product: product))).then((_) => _load());
  }
}

class _ProductForm extends StatefulWidget {
  final dynamic product;
  const _ProductForm({this.product});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _catId;
  double _threshold = 5;
  bool _saving = false;
  bool get _edit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name ?? '';
      _priceCtrl.text = (p.price is double ? p.price : (p.price as num).toDouble()).toString();
      _costCtrl.text = (p.costPrice is double ? p.costPrice : (p.costPrice as num).toDouble()).toString();
      _qtyCtrl.text = (p.stockQty ?? 0).toString();
      _barcodeCtrl.text = p.barcode ?? '';
      _descCtrl.text = p.description ?? '';
      _catId = p.categoryId;
      _threshold = (p.lowStockThreshold ?? 5).toDouble();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _qtyCtrl.dispose();
    _barcodeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final bp = context.read<BusinessProvider>();
    if (bp.business == null) {
      await bp.loadBusiness();
      if (bp.business == null) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load business'), backgroundColor: Colors.red));
        }
        return;
      }
    }
    final bid = bp.business!.id;
    final pp = context.read<ProductProvider>();
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final barcode = _barcodeCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    try {
      if (_edit) {
        await pp.updateProduct(widget.product!.copyWith(
          name: name, description: desc, price: price,
          costPrice: cost, stockQty: qty, barcode: barcode,
          categoryId: _catId, lowStockThreshold: _threshold.toInt(),
        ));
      } else {
        await pp.createProduct(
          businessId: bid, name: name, description: desc,
          price: price, costPrice: cost, stockQty: qty,
          barcode: barcode, categoryId: _catId,
          lowStockThreshold: _threshold.toInt(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edit ? 'Updated' : 'Created')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext c) {
    final cats = context.watch<ProductProvider>().categories;
    return Scaffold(
      appBar: AppBar(
        title: Text(_edit ? 'Edit Product' : 'New Product'),
        actions: _edit ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: c,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                await context.read<ProductProvider>().deleteProduct(widget.product!.id);
                if (mounted) Navigator.pop(c);
              }
            },
          ),
        ] : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _catId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _catId = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (R)'), validator: (v) => (v ?? '').isEmpty ? 'Required' : null)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (R)'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Qty'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode'))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Low stock alert:', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Text('${_threshold.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            Slider(value: _threshold, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _threshold = v)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_edit ? 'Save Changes' : 'Create Product'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

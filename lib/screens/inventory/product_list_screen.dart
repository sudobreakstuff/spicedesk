import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  String? _catFilter;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final b = context.read<BusinessProvider>().business;
    if (b != null) context.read<ProductProvider>().loadProducts(b.id);
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _search, style: TextStyle(fontSize: 13, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary),
                decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(vertical: 10), isDense: true, suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _search.clear(); pp.setSearchQuery(null); }) : null),
                onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            _filterChip('Low Stock', _lowStockOnly, () { setState(() { _lowStockOnly = !_lowStockOnly; if (_lowStockOnly) pp.toggleLowStockOnly(); else pp.clearFilters(); }); }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
          children: [
            _catChip(null, _catFilter == null, () { setState(() { _catFilter = null; pp.setCategoryFilter(null); }); }),
            ...pp.categories.take(6).map((c) => _catChip(c.name, _catFilter == c.id, () { setState(() { _catFilter = c.id; pp.setCategoryFilter(c.id); }); })),
          ]),
        ),
        const SizedBox(height: 6),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isDark ? SpiceColors.darkSurface : SpiceColors.surfaceAlt,
          child: Row(children: [
            const SizedBox(width: 32),
            const Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5))),
            const Expanded(flex: 2, child: Text('Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5), textAlign: TextAlign.right)),
            const Expanded(flex: 1, child: Text('Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5), textAlign: TextAlign.center)),
            const SizedBox(width: 60),
          ]),
        ),
        Expanded(
          child: pp.loading && pp.products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : pp.products.isEmpty
              ? _emptyState()
              : ListView.builder(
                  itemCount: pp.products.length,
                  itemBuilder: (_, i) => _ProductRow(product: pp.products[i]),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Product', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: SpiceColors.primaryBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_outlined, color: SpiceColors.primaryLight, size: 28)),
      const SizedBox(height: 12),
      Text('No products', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Add your first product to get started', style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.textSecondary)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () => _showForm(), child: const Text('Add Product')),
    ]),
  );

  Widget _catChip(String? label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: selected ? SpiceColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? SpiceColors.primary : SpiceColors.cardBorder)),
          child: Text(label ?? 'All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? Colors.white : SpiceColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: selected ? SpiceColors.warningBg : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? SpiceColors.warning : SpiceColors.cardBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber, size: 14, color: selected ? SpiceColors.warning : SpiceColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? SpiceColors.warning : SpiceColors.textSecondary)),
        ]),
      ),
    );
  }

  void _showForm({dynamic product}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product))).then((_) => _load());
  }
}

class _ProductRow extends StatelessWidget {
  final dynamic product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowStock = (product.stockQty as int) <= (product.lowStockThreshold as int);
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product))).then((_) {
          final b = context.read<BusinessProvider>().business;
          if (b != null) context.read<ProductProvider>().loadProducts(b.id);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder))),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: SpiceColors.primaryBg, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.inventory_2, color: SpiceColors.primaryLight, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary)),
              if (product.description != null && (product.description as String).isNotEmpty)
                Text(product.description as String, style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Expanded(
            flex: 2,
            child: Text(AppConstants.formatCurrency((product.price as num).toDouble()), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: lowStock ? SpiceColors.warningBg : SpiceColors.successBg, borderRadius: BorderRadius.circular(4)),
              child: Text('${product.stockQty}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: lowStock ? SpiceColors.warning : SpiceColors.success)),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: SpiceColors.textTertiary), onPressed: () => context.read<ProductProvider>().adjustStock(product.id as String, -1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: SpiceColors.primaryLight), onPressed: () => context.read<ProductProvider>().adjustStock(product.id as String, 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        ]),
      ),
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  final dynamic product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _desc = TextEditingController(), _price = TextEditingController(), _cost = TextEditingController(), _qty = TextEditingController(), _barcode = TextEditingController();
  String? _catId;
  int _threshold = 5;
  bool _saving = false;
  bool get _edit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_edit) {
      final p = widget.product!; _name.text = p.name ?? ''; _desc.text = p.description ?? '';
      _price.text = '${(p.price as num).toDouble()}'; _cost.text = '${(p.costPrice as num).toDouble()}';
      _qty.text = '${p.stockQty}'; _barcode.text = p.barcode ?? '';
      _catId = p.categoryId; _threshold = p.lowStockThreshold ?? 5;
    }
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); _price.dispose(); _cost.dispose(); _qty.dispose(); _barcode.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final bp = context.read<BusinessProvider>();
    final pp = context.read<ProductProvider>();
    if (bp.business == null) { setState(() => _saving = false); return; }
    final bizId = bp.business!.id;
    final name = _name.text.trim();
    final price = double.tryParse(_price.text) ?? 0;
    final cost = double.tryParse(_cost.text) ?? 0;
    final qty = int.tryParse(_qty.text) ?? 0;
    try {
      if (_edit) {
        await pp.updateProduct(widget.product!.copyWith(categoryId: _catId, name: name, description: _desc.text.trim(), price: price, costPrice: cost, stockQty: qty, lowStockThreshold: _threshold, barcode: _barcode.text.trim()));
      } else {
        await pp.createProduct(businessId: bizId, categoryId: _catId, name: name, description: _desc.text.trim(), price: price, costPrice: cost, stockQty: qty, lowStockThreshold: _threshold, barcode: _barcode.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edit ? 'Updated' : 'Created'), behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: SpiceColors.error, behavior: SnackBarBehavior.floating));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<ProductProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Product' : 'New Product'), actions: _edit ? [IconButton(icon: const Icon(Icons.delete_outline, color: SpiceColors.error), onPressed: () async { await context.read<ProductProvider>().deleteProduct(widget.product!.id); if (mounted) Navigator.pop(context); })] : null),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Product Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _catId, decoration: const InputDecoration(labelText: 'Category'), items: [const DropdownMenuItem(value: null, child: Text('None')), ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))], onChanged: (v) => setState(() => _catId = v)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (R)'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (R)'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Qty'))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode'))),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 20),
          Row(children: [
            Text('Low stock alert at:', style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.textSecondary)),
            const Spacer(),
            Text('$_threshold', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          Slider(value: _threshold.toDouble(), min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _threshold = v.toInt())),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_edit ? 'Save Changes' : 'Create Product')),
        ]),
      ),
    );
  }
}

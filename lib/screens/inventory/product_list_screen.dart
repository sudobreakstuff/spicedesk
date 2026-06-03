import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/glass_theme.dart';
import '../../core/constants.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _catFilter;
  bool _lowStock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final b = context.read<BusinessProvider>().business;
    if (b != null) context.read<ProductProvider>().loadProducts(b.id);
  }

  @override
  Widget build(BuildContext c) {
    final pp = context.watch<ProductProvider>();
    final isDark = context.isGlassDark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Inventory'),
        trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.add_circled), onPressed: () => _showForm()),
      ),
      child: SafeArea(
        child: Column(children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Container(
              decoration: GlassTheme.glassCard(isDark),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: CupertinoSearchTextField(
                  placeholder: 'Search products...',
                  onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v),
                )),
              ),
            ),
          ),
          // Filters
          SizedBox(
            height: 36,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
              _chip('All', _catFilter == null, () { setState(() { _catFilter = null; pp.setCategoryFilter(null); }); }),
              ...pp.categories.take(8).map((cat) => _chip(cat.name, _catFilter == cat.id, () { setState(() { _catFilter = cat.id; pp.setCategoryFilter(cat.id); }); })),
              const SizedBox(width: 8),
              _chip('⚠ Low', _lowStock, () { setState(() { _lowStock = !_lowStock; if (_lowStock) pp.toggleLowStockOnly(); else pp.clearFilters(); }); }),
            ]),
          ),
          const SizedBox(height: 4),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: isDark ? const Color(0x33000000) : const Color(0x33C7C7CC),
            child: Row(children: const [
              SizedBox(width: 32),
              Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2, letterSpacing: 0.5))),
              Expanded(flex: 2, child: Text('Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2, letterSpacing: 0.5), textAlign: TextAlign.right)),
              Expanded(flex: 1, child: Text('Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2, letterSpacing: 0.5), textAlign: TextAlign.center)),
              SizedBox(width: 52),
            ]),
          ),
          Expanded(
            child: pp.loading && pp.products.isEmpty
              ? const Center(child: CupertinoActivityIndicator())
              : pp.products.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(CupertinoIcons.cube, size: 40, color: context.glassText3),
                    const SizedBox(height: 10),
                    const Text('No products', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    CupertinoButton.filled(child: const Text('Add Product'), onPressed: () => _showForm()),
                  ]))
                : ListView.builder(
                    itemCount: pp.products.length,
                    itemBuilder: (_, i) => _Row(product: pp.products[i]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? GlassColors.primary : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? GlassColors.primary : context.glassBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? const Color(0xFFFFFFFF) : context.glassText2)),
        ),
      ),
    );
  }

  void _showForm({dynamic product}) {
    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => ProductForm(product: product))).then((_) => _load());
  }
}

class _Row extends StatelessWidget {
  final dynamic product;
  const _Row({required this.product});
  @override
  Widget build(BuildContext c) {
    final isDark = c.isGlassDark;
    final low = (product.stockQty as int) <= (product.lowStockThreshold as int);
    return CupertinoButton(
      padding: EdgeInsets.zero, alignment: Alignment.centerLeft,
      onPressed: () {
        Navigator.of(c).push(CupertinoPageRoute(builder: (_) => ProductForm(product: product))).then((_) {
          final b = c.read<BusinessProvider>().business;
          if (b != null) c.read<ProductProvider>().loadProducts(b.id);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.glassBorder.withValues(alpha: 0.3), width: 0.5))),
        child: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: GlassColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Icon(CupertinoIcons.cube, size: 14, color: GlassColors.primary)),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Text(product.name ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? GlassColors.darkText : GlassColors.lightText))),
          Expanded(flex: 2, child: Text(AppConstants.formatCurrency((product.price as num).toDouble()), textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: low ? GlassColors.warning.withValues(alpha: 0.15) : GlassColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text('${product.stockQty}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: low ? GlassColors.warning : GlassColors.success)),
          )),
          Row(mainAxisSize: MainAxisSize.min, children: [
            CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.minus_circle, size: 18, color: c.glassText3), onPressed: () => c.read<ProductProvider>().adjustStock(product.id, -1)),
            CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.add_circled, size: 18, color: GlassColors.primary), onPressed: () => c.read<ProductProvider>().adjustStock(product.id, 1)),
          ]),
        ]),
      ),
    );
  }
}

class ProductForm extends StatefulWidget {
  final dynamic product;
  const ProductForm({super.key, this.product});
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _desc = TextEditingController(), _price = TextEditingController(), _cost = TextEditingController(), _qty = TextEditingController(text: '0'), _barcode = TextEditingController();
  String? _catId;
  int _threshold = 5;
  bool _saving = false;
  String? _error;

  bool get _edit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_edit) { final p = widget.product!; _name.text = p.name ?? ''; _desc.text = p.description ?? ''; _price.text = '${(p.price as num).toDouble()}'; _cost.text = '${(p.costPrice as num).toDouble()}'; _qty.text = '${p.stockQty}'; _barcode.text = p.barcode ?? ''; _catId = p.categoryId; _threshold = p.lowStockThreshold ?? 5; }
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); _price.dispose(); _cost.dispose(); _qty.dispose(); _barcode.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final bp = context.read<BusinessProvider>();

    // Try to load business if not loaded
    if (bp.business == null) {
      await bp.loadBusiness();
      if (bp.business == null) {
        setState(() { _saving = false; _error = 'Could not load business. Please restart the app.'; });
        return;
      }
    }

    final bizId = bp.business!.id;
    final name = _name.text.trim();
    final price = double.tryParse(_price.text) ?? 0;
    final cost = double.tryParse(_cost.text) ?? 0;
    final qty = int.tryParse(_qty.text) ?? 0;
    try {
      if (_edit) {
        await context.read<ProductProvider>().updateProduct(widget.product!.copyWith(categoryId: _catId, name: name, description: _desc.text.trim(), price: price, costPrice: cost, stockQty: qty, lowStockThreshold: _threshold, barcode: _barcode.text.trim()));
      } else {
        await context.read<ProductProvider>().createProduct(businessId: bizId, categoryId: _catId, name: name, description: _desc.text.trim(), price: price, costPrice: cost, stockQty: qty, lowStockThreshold: _threshold, barcode: _barcode.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext c) {
    final cats = context.watch<ProductProvider>().categories;
    final isDark = c.isGlassDark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_edit ? 'Edit Product' : 'New Product'),
        trailing: _edit ? CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.delete, color: GlassColors.error), onPressed: () async { final ok = await showCupertinoDialog<bool>(context: c, builder: (_) => CupertinoAlertDialog(title: const Text('Delete?'), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(_, false)), CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.pop(_, true))])); if (ok == true) { await c.read<ProductProvider>().deleteProduct(widget.product!.id); if (mounted) Navigator.pop(c); } }) : null,
      ),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          if (_error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: GlassColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(_error!, style: const TextStyle(color: GlassColors.error, fontSize: 13))),
          _field('Product Name', _name, validator: (v) => (v??'').trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          Text('Category', style: TextStyle(fontSize: 12, color: c.glassText2)),
          const SizedBox(height: 6),
          Container(
            decoration: GlassTheme.glassCard(isDark),
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              alignment: Alignment.centerLeft,
              child: Text(_catId != null ? cats.firstWhere((x) => x.id == _catId, orElse: () => cats.first).name : 'None', style: TextStyle(fontSize: 15, color: _catId != null ? c.glassText : c.glassText2)),
              onPressed: () async {
                final selected = await showCupertinoModalPopup<String>(
                  context: c,
                  builder: (_) => CupertinoActionSheet(
                    title: const Text('Category'),
                    actions: cats.map((cat) => CupertinoActionSheetAction(child: Text(cat.name), onPressed: () => Navigator.pop(_, cat.id))).toList(),
                    cancelButton: CupertinoActionSheetAction(child: const Text('None'), onPressed: () => Navigator.pop(_, null)),
                  ),
                );
                if (selected != null || selected == null) setState(() => _catId = selected);
              },
            ))),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('Price', _price, prefix: 'R ', keyboard: TextInputType.number, validator: (v) => (v??'').isEmpty ? 'Required' : null)),
            const SizedBox(width: 10),
            Expanded(child: _field('Cost', _cost, prefix: 'R ', keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('Stock Qty', _qty, keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field('Barcode', _barcode)),
          ]),
          const SizedBox(height: 14),
          _field('Description', _desc, maxLines: 2),
          const SizedBox(height: 14),
          Row(children: [
            Text('Low stock alert:', style: TextStyle(fontSize: 13, color: c.glassText2)),
            const Spacer(),
            Text('$_threshold', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          CupertinoSlider(value: _threshold.toDouble(), min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _threshold = v.toInt())),
          const SizedBox(height: 18),
          CupertinoButton.filled(
            onPressed: _saving ? null : _save,
            child: _saving ? const CupertinoActivityIndicator() : Text(_edit ? 'Save Changes' : 'Create Product'),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? prefix, TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator, bool obs = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: context.glassText2)),
      const SizedBox(height: 4),
      CupertinoTextFormFieldRow(
        controller: ctrl, prefix: prefix != null ? Text(prefix) : null,
        maxLines: maxLines, obscureText: obs,
        keyboardType: keyboard,
        style: TextStyle(fontSize: 15, color: context.glassText),
        validator: validator,
      ),
    ]);
  }
}

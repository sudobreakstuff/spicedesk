import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/constants.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _s = TextEditingController();
  String _pmt = 'Cash';
  bool _co = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) context.read<ProductProvider>().loadProducts(b.id);
    });
  }

  @override
  void dispose() { _s.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    final pos = context.watch<PosProvider>();
    final pp = context.watch<ProductProvider>();
    final isLandscape = MediaQuery.of(c).orientation == Orientation.landscape;
    final isDark = Theme.of(c).brightness == Brightness.dark;

    return Stack(children: [
      if (isLandscape)
        Row(children: [
          Expanded(flex: 3, child: _productGrid(pos, pp, isDark)),
          const VerticalDivider(width: 1),
          Expanded(flex: 2, child: _cartPanel(pos, isDark)),
        ])
      else
        Column(children: [
          _searchBar(isDark),
          Expanded(child: _productGrid(pos, pp, isDark)),
          if (!pos.isEmpty) _cartPanel(pos, isDark),
          _barcodeBtn(),
        ]),
    ]);
  }

  Widget _searchBar(bool isDark) {
    final pp = context.read<ProductProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _s,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productGrid(PosProvider pos, ProductProvider pp, bool isDark) {
    return Column(children: [
      if (!pos.isEmpty) _cartSummary(pos, isDark),
      Expanded(
        child: pp.products.isEmpty
          ? const Center(child: Text('No products. Add products in Inventory tab.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120, childAspectRatio: 0.85, crossAxisSpacing: 6, mainAxisSpacing: 6,
              ),
              itemCount: pp.products.length,
              itemBuilder: (_, i) {
                final p = pp.products[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Material(
                      color: (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.8)),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => pos.addItem(p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(AppConstants.formatCurrency(p.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue)),
                            if (p.stockQty <= 5) Text('${p.stockQty}', style: const TextStyle(fontSize: 9, color: Colors.red)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  Widget _cartSummary(PosProvider pos, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.shade50),
        border: Border(bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.2))),
      ),
      child: Row(children: [
        Expanded(child: Text('${pos.totalQuantity} items', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text(AppConstants.formatCurrency(pos.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blue)),
      ]),
    );
  }

  Widget _cartPanel(PosProvider pos, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: pos.items.length,
            itemBuilder: (_, i) {
              final it = pos.items[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(it.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _qbtn(Icons.remove, () => pos.updateQuantity(i, it.quantity - 1)),
                        SizedBox(width: 18, child: Text('${it.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
                        _qbtn(Icons.add, () => pos.updateQuantity(i, it.quantity + 1)),
                      ]),
                      const SizedBox(width: 8),
                      Text(AppConstants.formatCurrency(it.lineTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      IconButton(icon: const Icon(Icons.close, size: 14, color: Colors.grey), onPressed: () => pos.removeItem(i), padding: EdgeInsets.zero, constraints: const BoxConstraints(), visualDensity: VisualDensity.compact),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        _checkoutBar(pos, isDark),
      ]),
    );
  }

  Widget _checkoutBar(PosProvider pos, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.blue.withValues(alpha: 0.1))),
      ),
      child: Row(children: [
        Expanded(
          child: Text('R ${pos.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.blue)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: ElevatedButton(
                  onPressed: _co ? null : _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                  child: _co ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Checkout'),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _qbtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(4),
        child: Container(width: 22, height: 22, alignment: Alignment.center, child: Icon(icon, size: 16, color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _barcodeBtn() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode scanner coming soon'))),
        icon: const Icon(Icons.qr_code_scanner, size: 16),
        label: const Text('Scan Barcode', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _checkout() async {
    final pos = context.read<PosProvider>();
    if (pos.isEmpty) return;
    setState(() => _co = true);
    final b = context.read<BusinessProvider>().business;
    if (b == null) { setState(() => _co = false); return; }
    final o = await context.read<OrderProvider>().createOrder(
      businessId: b.id, orderType: 'Walk-in', status: 'Completed',
      discount: pos.discount, paymentMethod: _pmt, items: pos.toOrderItemsData(),
    );
    setState(() => _co = false);
    if (!mounted) return;
    if (o == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout failed'), backgroundColor: Colors.red));
      return;
    }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sale Complete'),
      content: Text('Total: R ${pos.total.toStringAsFixed(2)}\nOrder #${o.id.substring(0, 8).toUpperCase()}'),
      actions: [TextButton(onPressed: () { pos.clear(); Navigator.pop(_); }, child: const Text('New Sale'))],
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _search = TextEditingController();
  String _type = 'Walk-in', _payment = 'Cash';
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) context.read<ProductProvider>().loadProducts(b.id);
    });
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    final pos = context.watch<PosProvider>();
    final pp = context.watch<ProductProvider>();
    final isDark = Theme.of(c).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale'), actions: [
        if (!pos.isEmpty) IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { pos.clear(); })
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6), child: Row(children: [
          Expanded(child: TextField(controller: _search, decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search, size: 18), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)), onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _type = _type == 'Walk-in' ? 'WhatsApp' : _type == 'WhatsApp' ? 'Phone Call' : 'Walk-in'),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: isDark ? T.dbd : T.bd)), child: Text(_type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          ),
        ])),

        if (pos.isEmpty)
          Expanded(child: GridView.builder(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: pp.products.length, itemBuilder: (_, i) {
            final p = pp.products[i];
            return GestureDetector(
              onTap: () => pos.addItem(p),
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: isDark ? T.dbd : T.bd)), padding: const EdgeInsets.all(6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(p.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? T.dt1 : T.t1)),
                  const SizedBox(height: 3),
                  Text(AppConstants.formatCurrency((p.price as num).toDouble()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.p)),
                  if ((p.stockQty as int) <= 5) Text('${p.stockQty} left', style: const TextStyle(fontSize: 9, color: Colors.red)),
                ])),
            );
          }))
        else ...[
          Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: pos.items.length, itemBuilder: (_, i) {
            final item = pos.items[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: isDark ? T.dbd : T.bd)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? T.dt1 : T.t1)),
                  Text('${AppConstants.formatCurrency(item.product.price)} × ${item.quantity} = ${AppConstants.formatCurrency(item.lineTotal)}', style: TextStyle(fontSize: 11, color: T.t2)),
                ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => pos.updateQuantity(i, item.quantity - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  SizedBox(width: 22, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: T.p), onPressed: () => pos.updateQuantity(i, item.quantity + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
                IconButton(icon: const Icon(Icons.close, size: 18, color: T.t3), onPressed: () => pos.removeItem(i), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            );
          })),
          Container(
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: isDark ? T.dbd : T.bd)),
            child: Column(children: [
              _tr('Subtotal', pos.subtotal), _tr('VAT (15%)', pos.taxAmount),
              if (pos.discount > 0) _tr('Discount', -pos.discount, color: Colors.red),
              const Divider(height: 12), _tr('Total', pos.total, bold: true, size: 16, color: T.p),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(value: _payment, decoration: const InputDecoration(labelText: 'Payment', isDense: true), items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) { if (v != null) { _payment = v; pos.setPaymentMethod(v); } })),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _checkingOut ? null : _checkout, style: ElevatedButton.styleFrom(backgroundColor: T.s), child: _checkingOut ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Checkout R ${pos.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)))),
              ]),
            ]),
          ),
        ],
        if (pos.isEmpty)
          TextButton.icon(onPressed: () => ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Barcode scanner coming soon'))), icon: const Icon(Icons.qr_code_scanner, size: 18), label: const Text('Scan Barcode')),
      ]),
    );
  }

  Widget _tr(String label, double value, {bool bold = false, double size = 13, Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: color)),
      Text(AppConstants.formatCurrency(value), style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: color)),
    ]));
  }

  Future<void> _checkout() async {
    final pos = context.read<PosProvider>();
    if (pos.isEmpty) return;
    setState(() => _checkingOut = true);
    final b = context.read<BusinessProvider>().business;
    if (b == null) { setState(() => _checkingOut = false); return; }
    final order = await context.read<OrderProvider>().createOrder(businessId: b.id, orderType: _type, status: 'Completed', subtotal: pos.subtotal, taxAmount: pos.taxAmount, discount: pos.discount, total: pos.total, paymentMethod: _payment, items: pos.toOrderItemsData());
    setState(() => _checkingOut = false);
    if (!mounted) return;
    if (order == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout failed'), backgroundColor: Colors.red)); return; }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sale Complete'), content: Text('Total: R ${pos.total.toStringAsFixed(2)}\nOrder #${order.id.substring(0, 8).toUpperCase()}'),
      actions: [TextButton(onPressed: () { pos.clear(); Navigator.pop(_); }, child: const Text('New Sale'))],
    ));
  }
}

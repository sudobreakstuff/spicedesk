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
  String _pmt = 'Cash', _typ = 'Walk-in';
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
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(children: [
            Expanded(child: TextField(controller: _s, decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _typ = _typ == 'Walk-in' ? 'WhatsApp' : _typ == 'WhatsApp' ? 'Phone Call' : 'Walk-in'),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.grey.shade300)), child: Text(_typ, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            ),
          ]),
        ),
        if (pos.isEmpty)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: pp.products.length,
              itemBuilder: (_, i) {
                final p = pp.products[i];
                return GestureDetector(
                  onTap: () => pos.addItem(p),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(6),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(AppConstants.formatCurrency(p.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue)),
                      if (p.stockQty <= 5) Text('${p.stockQty} left', style: const TextStyle(fontSize: 9, color: Colors.red)),
                    ]),
                  ),
                );
              },
            ),
          )
        else ...[
          // Cart items
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: pos.items.length,
              itemBuilder: (_, i) {
                final it = pos.items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${AppConstants.formatCurrency(it.product.price)} x ${it.quantity} = ${AppConstants.formatCurrency(it.lineTotal)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: () => pos.updateQuantity(i, it.quantity - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      SizedBox(width: 20, child: Text('${it.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue), onPressed: () => pos.updateQuantity(i, it.quantity + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ]),
                    IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.grey), onPressed: () => pos.removeItem(i), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ]),
                );
              },
            ),
          ),
          // Totals
          Container(
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.grey.shade300)),
            child: Column(children: [
              _tr('Subtotal', pos.subtotal),
              _tr('VAT (15%)', pos.taxAmount),
              if (pos.discount > 0) _tr('Discount', -pos.discount, color: Colors.red),
              const Divider(height: 10),
              _tr('Total', pos.total, bold: true, size: 15, color: Colors.blue),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pmt,
                    decoration: const InputDecoration(labelText: 'Payment', isDense: true),
                    items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) { if (v != null) _pmt = v; },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _co ? null : _checkout,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _co ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Checkout R ${pos.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ]),
            ]),
          ),
          // Keep product grid visible
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: pp.products.length,
              itemBuilder: (_, i) {
                final p = pp.products[i];
                return GestureDetector(
                  onTap: () => pos.addItem(p),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(6),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(AppConstants.formatCurrency(p.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue)),
                      if (p.stockQty <= 5) Text('${p.stockQty} left', style: const TextStyle(fontSize: 9, color: Colors.red)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }

  Widget _tr(String l, double v, {bool bold = false, double size = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: color)),
        Text(AppConstants.formatCurrency(v), style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: color)),
      ]),
    );
  }

  Future<void> _checkout() async {
    final pos = context.read<PosProvider>();
    if (pos.isEmpty) return;
    setState(() => _co = true);
    final b = context.read<BusinessProvider>().business;
    if (b == null) { setState(() => _co = false); return; }
    final o = await context.read<OrderProvider>().createOrder(
      businessId: b.id, orderType: _typ, status: 'Completed',
      discount: pos.discount, paymentMethod: _pmt, items: pos.toOrderItemsData(),
    );
    setState(() => _co = false);
    if (!mounted) return;
    if (o == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout failed'), backgroundColor: Colors.red));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sale Complete'),
        content: Text('Total: R ${pos.total.toStringAsFixed(2)}\nOrder #${o.id.substring(0, 8).toUpperCase()}'),
        actions: [TextButton(onPressed: () { pos.clear(); Navigator.pop(_); }, child: const Text('New Sale'))],
      ),
    );
  }
}

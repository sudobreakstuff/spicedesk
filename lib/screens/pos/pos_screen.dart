import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _search = TextEditingController();
  final _barcode = TextEditingController();
  String _payment = 'Cash';
  String _type = 'Walk-in';
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
  void dispose() { _search.dispose(); _barcode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final pp = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(controller: _search, style: TextStyle(fontSize: 13, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary), decoration: InputDecoration(hintText: 'Search or scan...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(vertical: 10), isDense: true, suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _search.clear(); pp.setSearchQuery(null); }) : null), onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v))),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: _chip(_type, () { setState(() => _type = _type == 'Walk-in' ? 'WhatsApp' : _type == 'WhatsApp' ? 'Phone Call' : 'Walk-in'); pos.setOrderType(_type); })),
          ]),
        ),
        if (pos.isEmpty)
          Expanded(child: pp.loading ? const Center(child: CircularProgressIndicator()) : GridView.builder(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.75, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: pp.products.length, itemBuilder: (_, i) {
            final p = pp.products[i]; return _ProductTile(p: p, onTap: () => pos.addItem(p));
          }))
        else ...[
          Expanded(
            child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: pos.items.length, itemBuilder: (_, i) {
              final item = pos.items[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(color: isDark ? SpiceColors.darkCard : SpiceColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)), Text('${AppConstants.formatCurrency(item.product.price)} × ${item.quantity} = ${AppConstants.formatCurrency(item.lineTotal)}', style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textSecondary))])),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _qbtn(Icons.remove, () => pos.updateQuantity(i, item.quantity - 1)),
                    Container(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                    _qbtn(Icons.add, () => pos.updateQuantity(i, item.quantity + 1)),
                  ]),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.close, size: 16, color: SpiceColors.textTertiary), onPressed: () => pos.removeItem(i), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
              );
            }),
          ),
          // Totals
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            decoration: BoxDecoration(color: isDark ? SpiceColors.darkCard : SpiceColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder)),
            child: Column(children: [
              _totalRow('Subtotal', pos.subtotal),
              _totalRow('VAT (15%)', pos.taxAmount),
              if (pos.discount > 0) _totalRow('Discount', -pos.discount),
              const Divider(),
              _totalRow('Total', pos.total, bold: true),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(value: _payment, decoration: const InputDecoration(labelText: 'Payment', isDense: true), items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) { if (v != null) { _payment = v; pos.setPaymentMethod(v); } })),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _checkingOut ? null : _checkout, style: ElevatedButton.styleFrom(backgroundColor: SpiceColors.success), child: _checkingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Checkout R ${pos.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)))),
              ]),
            ]),
          ),
        ],
        if (pos.isEmpty) SizedBox(width: double.infinity, child: TextButton(onPressed: () { _barcode.clear(); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Scan Barcode'), content: TextField(controller: _barcode, autofocus: true, decoration: const InputDecoration(hintText: 'Type barcode'), onSubmitted: (v) async { Navigator.pop(ctx); if (v.isNotEmpty) { final b = context.read<BusinessProvider>().business; if (b != null) { final p = await context.read<ProductProvider>().findByBarcode(b.id, v); if (p != null && mounted) context.read<PosProvider>().addItem(p); }}}), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))])); }, child: const Text('Scan Barcode', style: TextStyle(fontSize: 13))))
      ]),
    );
  }

  Widget _chip(String label, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: SpiceColors.cardBorder)), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center)));

  Widget _qbtn(IconData icon, VoidCallback onTap) => Material(color: Colors.transparent, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4), child: Container(width: 24, height: 24, alignment: Alignment.center, child: Icon(icon, size: 16, color: SpiceColors.textSecondary))));

  Widget _totalRow(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
      Text(AppConstants.formatCurrency(value), style: GoogleFonts.inter(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: bold ? SpiceColors.primary : null)),
    ]),
  );

  Future<void> _checkout() async {
    final pos = context.read<PosProvider>();
    if (pos.isEmpty) return;
    setState(() => _checkingOut = true);
    final b = context.read<BusinessProvider>().business;
    if (b == null) { setState(() => _checkingOut = false); return; }
    final order = await context.read<OrderProvider>().createOrder(
      businessId: b.id, orderType: pos.orderType, status: 'Completed',
      subtotal: pos.subtotal, taxAmount: pos.taxAmount, discount: pos.discount,
      total: pos.total, paymentMethod: pos.paymentMethod, items: pos.toOrderItemsData(),
    );
    setState(() => _checkingOut = false);
    if (order == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout failed'), backgroundColor: SpiceColors.error, behavior: SnackBarBehavior.floating)); return; }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Sale Complete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: Text('Total: ${AppConstants.formatCurrency(pos.total)}\nOrder #${order.id.substring(0, 8).toUpperCase()}', style: GoogleFonts.inter(fontSize: 14)),
      actions: [
        TextButton(onPressed: () {
          Navigator.pop(ctx);
          final msg = 'SpiceDesk Order\n${"=" * 20}\n${pos.items.map((i) => '${i.product.name} x${i.quantity} = ${AppConstants.formatCurrency(i.lineTotal)}').join('\n')}\n${"=" * 20}\nTotal: ${AppConstants.formatCurrency(pos.total)}\nPayment: ${pos.paymentMethod}';
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt ready'), behavior: SnackBarBehavior.floating));
        }, child: const Text('WhatsApp')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); pos.clear(); }, child: const Text('New Sale', style: TextStyle(fontSize: 13))),
      ],
    ));
  }
}

class _ProductTile extends StatelessWidget {
  final dynamic p;
  final VoidCallback onTap;
  const _ProductTile({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? SpiceColors.darkCard : SpiceColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: SpiceColors.cardBorder)),
          padding: const EdgeInsets.all(6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(p.name as String, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, height: 1.2)),
            const SizedBox(height: 2),
            Text(AppConstants.formatCurrency((p.price as num).toDouble()), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
            if ((p.stockQty as int) <= 5) Text('${p.stockQty} left', style: GoogleFonts.inter(fontSize: 9, color: SpiceColors.error)),
          ]),
        ),
      ),
    );
  }
}

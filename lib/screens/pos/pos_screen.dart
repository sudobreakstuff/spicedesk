import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/glass_theme.dart';
import '../../core/constants.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _barcode = TextEditingController();
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
  void dispose() { _barcode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    final pos = context.watch<PosProvider>();
    final pp = context.watch<ProductProvider>();
    final isDark = c.isGlassDark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('New Sale'), trailing: pos.isEmpty ? null : CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.delete, size: 20, color: GlassColors.error), onPressed: () { showCupertinoDialog(context: c, builder: (_) => CupertinoAlertDialog(title: const Text('Clear Cart?'), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(_)), CupertinoDialogAction(isDestructiveAction: true, child: const Text('Clear'), onPressed: () { pos.clear(); Navigator.pop(_); })])); })),
      child: SafeArea(
        child: Column(children: [
          // Search + order type
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(children: [
              Expanded(child: Container(decoration: GlassTheme.glassCard(isDark), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: CupertinoSearchTextField(placeholder: 'Search products...', onChanged: (v) => pp.setSearchQuery(v.isEmpty ? null : v)))))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _type = _type == 'Walk-in' ? 'WhatsApp' : _type == 'WhatsApp' ? 'Phone Call' : 'Walk-in'),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: GlassTheme.glassCard(isDark), child: Text(_type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
              ),
            ]),
          ),
          if (pos.isEmpty)
            Expanded(child: pp.loading ? const Center(child: CupertinoActivityIndicator()) : GridView.builder(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.82, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: pp.products.length, itemBuilder: (_, i) => _Tile(p: pp.products[i], onTap: () => pos.addItem(pp.products[i]))))
          else ...[
            Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: pos.items.length, itemBuilder: (_, i) {
              final item = pos.items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 4), decoration: GlassTheme.glassCard(isDark),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.glassText)), Text('R ${item.product.price.toStringAsFixed(2)} × ${item.quantity} = R ${item.lineTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: c.glassText2))])),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.minus_circle, size: 20, color: c.glassText3), onPressed: () => pos.updateQuantity(i, item.quantity - 1)),
                      SizedBox(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.add_circled, size: 20, color: GlassColors.primary), onPressed: () => pos.updateQuantity(i, item.quantity + 1)),
                    ]),
                  ]),
                ))),
              );
            })),
            // Totals
            Container(
              margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              decoration: GlassTheme.glassCard(isDark),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _tr('Subtotal', pos.subtotal, isDark),
                  _tr('VAT (15%)', pos.taxAmount, isDark),
                  if (pos.discount > 0) _tr('Discount', -pos.discount, isDark, color: GlassColors.error),
                  Container(height: 1, color: c.glassBorder.withValues(alpha: 0.5)),
                  const SizedBox(height: 6),
                  _tr('Total', pos.total, isDark, bold: true, color: GlassColors.primary, size: 18),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: CupertinoButton(padding: EdgeInsets.zero, child: Text('Pay: $_payment  ▾', style: const TextStyle(fontSize: 13)), onPressed: () {
                      showCupertinoModalPopup(context: c, builder: (_) => CupertinoActionSheet(
                        title: const Text('Payment Method'),
                        actions: AppConstants.paymentMethods.map((m) => CupertinoActionSheetAction(child: Text(m), onPressed: () { setState(() => _payment = m); Navigator.pop(_); })).toList(),
                        cancelButton: CupertinoActionSheetAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(_)),
                      ));
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: CupertinoButton.filled(
                      onPressed: _checkingOut ? null : _checkout,
                      child: _checkingOut ? const CupertinoActivityIndicator() : Text('Checkout R ${pos.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ]),
              ))),
            ),
          ],
          if (pos.isEmpty) CupertinoButton(child: Text('Enter Barcode', style: TextStyle(fontSize: 13, color: c.glassText2)), onPressed: () {
            showCupertinoDialog(context: c, builder: (ctx) => CupertinoAlertDialog(title: const Text('Barcode'), content: Padding(padding: const EdgeInsets.only(top: 8), child: CupertinoTextField(controller: _barcode, autofocus: true, placeholder: 'Type barcode', onSubmitted: (v) async {
              Navigator.pop(ctx); if (v.isNotEmpty) { final b = context.read<BusinessProvider>().business; if (b != null) { final p = await context.read<ProductProvider>().findByBarcode(b.id, v); if (p != null) pos.addItem(p); }}
            })), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx))]));
          }),
        ]),
      ),
    );
  }

  Widget _tr(String label, double value, bool isDark, {bool bold = false, Color? color, double size = 13}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: color ?? (isDark ? GlassColors.darkText : GlassColors.lightText))),
      Text(AppConstants.formatCurrency(value), style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: color ?? (isDark ? GlassColors.darkText : GlassColors.lightText))),
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
      total: pos.total, paymentMethod: _payment, items: pos.toOrderItemsData(),
    );
    setState(() => _checkingOut = false);
    if (!mounted) return;
    if (order == null) { showCupertinoDialog(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('Error'), content: const Text('Checkout failed'), actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(_))])); return; }
    showCupertinoDialog(context: context, builder: (_) => CupertinoAlertDialog(
      title: const Text('Sale Complete ✓'),
      content: Text('Total: R ${pos.total.toStringAsFixed(2)}\nOrder #${order.id.substring(0, 8).toUpperCase()}'),
      actions: [
        CupertinoDialogAction(child: const Text('New Sale'), onPressed: () { pos.clear(); Navigator.pop(_); }),
      ],
    ));
  }
}

class _Tile extends StatelessWidget {
  final dynamic p; final VoidCallback onTap;
  const _Tile({required this.p, required this.onTap});
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: GlassTheme.glassCard(c.isGlassDark),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(p.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c.glassText)),
          const SizedBox(height: 3),
          Text('R ${((p.price ?? 0.0) as num).toDouble().toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GlassColors.primary)),
          if ((p.stockQty ?? 0) <= 5) Text('${p.stockQty} left', style: const TextStyle(fontSize: 9, color: GlassColors.warning)),
        ]),
      ))),
    ),
  );
}

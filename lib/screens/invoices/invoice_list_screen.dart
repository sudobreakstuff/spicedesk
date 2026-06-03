import 'dart:ui' show Colors, ImageFilter;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';
import '../../core/glass_theme.dart';
import '../../core/constants.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  void _load() { final b = context.read<BusinessProvider>().business; if (b != null) context.read<InvoiceProvider>().loadInvoices(b.id); }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  Color _statusColor(String s) => s == 'Paid' ? GlassColors.success : s == 'Sent' ? GlassColors.primary : GlassColors.lightText3;

  @override
  Widget build(BuildContext c) {
    final ip = context.watch<InvoiceProvider>();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Invoices'), trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.add_circled), onPressed: _createFromOrder)),
      child: SafeArea(
        child: ip.loading ? const Center(child: CupertinoActivityIndicator()) :
          ip.invoices.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(CupertinoIcons.doc_richtext, size: 40, color: c.glassText3), const SizedBox(height: 10),
            const Text('No invoices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10), CupertinoButton.filled(child: const Text('Create from Order'), onPressed: _createFromOrder),
          ])) :
          ListView.builder(padding: const EdgeInsets.all(12), itemCount: ip.invoices.length, itemBuilder: (_, i) {
            final inv = ip.invoices[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: GlassTheme.glassCard(c.isGlassDark),
              child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _statusColor(inv.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(inv.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(inv.status)))),
                    const Spacer(),
                    Text(inv.invoiceNumber, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.glassText)),
                  ]),
                  const SizedBox(height: 6),
                  Text(DateFormat('dd MMM yyyy').format(inv.createdAt as DateTime), style: TextStyle(fontSize: 11, color: c.glassText2)),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (inv.pdfPath == null)
                      Expanded(child: CupertinoButton.filled(child: const Text('Generate PDF', style: TextStyle(fontSize: 12)), onPressed: () => _generate(inv), sizeStyle: CupertinoButtonSize.small))
                    else ...[
                      Expanded(child: CupertinoButton(child: const Text('Share', style: TextStyle(fontSize: 12)), onPressed: () { final path = inv.pdfPath as String; if (path.isNotEmpty) { final f = File(path); if (f.existsSync()) Share.shareXFiles([XFile(f.path)]); }}, sizeStyle: CupertinoButtonSize.small)),
                      Expanded(child: CupertinoButton(child: const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Color(0xFF25D366))), onPressed: () async { final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Invoice ${inv.invoiceNumber}')}'); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }, sizeStyle: CupertinoButtonSize.small)),
                    ],
                    if (inv.status == 'Sent') Expanded(child: CupertinoButton(child: const Text('Mark Paid', style: TextStyle(fontSize: 12, color: GlassColors.success)), onPressed: () { ip.updateStatus(inv.id, 'Paid'); }, sizeStyle: CupertinoButtonSize.small)),
                  ]),
                ]),
              ))),
            );
          }),
      ),
    );
  }

  Future<void> _generate(dynamic inv) async {
    final bp = context.read<BusinessProvider>().business; if (bp == null) return;
    final op = context.read<OrderProvider>();
    final order = op.orders.where((o) => o.id == inv.orderId).firstOrNull;
    if (order == null) { showCupertinoAlert(context, 'Order not found'); return; }
    final items = await op.getOrderItems(order.id);
    dynamic customer; if (order.customerId != null) customer = context.read<CustomerProvider>().findById(order.customerId!);
    final path = await context.read<InvoiceProvider>().generatePdf(invoice: inv, business: bp, order: order, items: items, customer: customer);
    if (path != null && mounted) showCupertinoAlert(context, 'PDF generated');
  }

  void _createFromOrder() {
    showCupertinoModalPopup(context: context, builder: (ctx) => CupertinoActionSheet(
      title: const Text('Create from Order'),
      message: const Text('Select a completed order'),
      actions: context.read<OrderProvider>().orders.where((o) => o.status == 'Completed').take(10).map((o) => CupertinoActionSheetAction(
        child: Text('Order #${(o.id).substring(0, 8).toUpperCase()} — R ${o.total.toStringAsFixed(2)}'),
        onPressed: () async {
          Navigator.pop(ctx);
          final b = context.read<BusinessProvider>().business; if (b == null) return;
          await context.read<InvoiceProvider>().createFromOrder(businessId: b.id, invoicePrefix: b.invoicePrefix ?? 'INV', orderId: o.id, customerId: o.customerId);
        },
      )).toList(),
      cancelButton: CupertinoActionSheetAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
    ));
  }

  void showCupertinoAlert(BuildContext c, String msg) {
    showCupertinoDialog(context: c, builder: (_) => CupertinoAlertDialog(content: Text(msg), actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(_))]));
  }
}

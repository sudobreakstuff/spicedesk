import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';
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

  @override
  Widget build(BuildContext c) {
    final ip = context.watch<InvoiceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _create)]),
      body: ip.invoices.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.description_outlined, size: 48, color: Colors.grey), const SizedBox(height: 12), const Text('No invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Create invoices from completed orders', style: TextStyle(color: Colors.grey, fontSize: 13)), const SizedBox(height: 12), ElevatedButton(onPressed: _create, child: const Text('Create Invoice'))]))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: ip.invoices.length, itemBuilder: (_, i) {
            final inv = ip.invoices[i];
            final sc = inv.status == 'Paid' ? Colors.green : inv.status == 'Sent' ? Colors.blue : Colors.grey;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(inv.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc))),
                const Spacer(),
                Text(inv.invoiceNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text(DateFormat('dd MMM yyyy').format(inv.createdAt as DateTime), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(children: [
                if (inv.pdfPath == null)
                  Expanded(child: ElevatedButton(onPressed: () => _gen(inv), style: ElevatedButton.styleFrom(minimumSize: const Size(0, 34)), child: const Text('Generate PDF', style: TextStyle(fontSize: 12))))
                else ...[
                  Expanded(child: OutlinedButton(onPressed: () { final path = inv.pdfPath as String; if (path.isNotEmpty && File(path).existsSync()) Share.shareXFiles([XFile(path)]); }, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34)), child: const Text('Share', style: TextStyle(fontSize: 12)))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () async { final u = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Invoice ${inv.invoiceNumber}')}'); if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication); }, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34)), child: const Text('WhatsApp', style: TextStyle(fontSize: 12)))),
                ],
                if (inv.status == 'Sent') ...[const SizedBox(width: 8), Expanded(child: TextButton(onPressed: () => ip.updateStatus(inv.id, 'Paid'), style: TextButton.styleFrom(foregroundColor: Colors.green, minimumSize: const Size(0, 34)), child: const Text('Mark Paid', style: TextStyle(fontSize: 12))))],
              ]),
            ])));
          }),
    );
  }

  Future<void> _gen(dynamic inv) async {
    final bp = context.read<BusinessProvider>().business; if (bp == null) return;
    final op = context.read<OrderProvider>(); final cp = context.read<CustomerProvider>();
    final order = op.orders.where((o) => o.id == inv.orderId).firstOrNull;
    if (order == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order not found'))); return; }
    final items = await op.getOrderItems(order.id);
    final cust = order.customerId != null ? cp.findById(order.customerId!) : null;
    final p = await context.read<InvoiceProvider>().generatePdf(invoice: inv, business: bp, order: order, items: items, customer: cust);
    if (p != null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated')));
  }

  void _create() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (ctx) {
      final orders = context.read<OrderProvider>().orders.where((o) => o.status == 'Completed').toList();
      return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Create from Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (orders.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No completed orders', style: TextStyle(color: Colors.grey)))),
        ...orders.take(10).map((o) => ListTile(title: Text('Order #${(o.id).substring(0, 8).toUpperCase()}'), subtitle: Text('${AppConstants.formatCurrency(o.total)} · ${o.orderType}'), onTap: () async {
          Navigator.pop(ctx); final b = context.read<BusinessProvider>().business; if (b == null) return;
          await context.read<InvoiceProvider>().createFromOrder(businessId: b.id, invoicePrefix: b.invoicePrefix ?? 'INV', orderId: o.id, customerId: o.customerId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created')));
        })),
        const SizedBox(height: 8),
      ])));
    });
  }
}

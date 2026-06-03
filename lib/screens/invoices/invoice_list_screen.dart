import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/invoice.dart';
import '../../models/order.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  static final _df = DateFormat('MMM d, HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final b = context.read<BusinessProvider>().business;
    if (b != null) {
      context.read<InvoiceProvider>().loadInvoices(b.id);
      final op = context.read<OrderProvider>(); op.clearFilters(); op.loadOrders(b.id);
    }
  }

  Future<void> _createFromOrder(OrderModel order) async {
    final ip = context.read<InvoiceProvider>(), bp = context.read<BusinessProvider>();
    if (bp.business == null) return;
    final inv = await ip.createFromOrder(businessId: bp.business!.id, invoicePrefix: bp.business!.invoicePrefix ?? 'INV', orderId: order.id, customerId: order.customerId);
    if (inv != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${inv.invoiceNumber} created')));
  }

  Future<void> _generatePdf(Invoice inv) async {
    final ip = context.read<InvoiceProvider>(), op = context.read<OrderProvider>(), bp = context.read<BusinessProvider>(), cp = context.read<CustomerProvider>();
    if (bp.business == null || inv.orderId == null) return;
    final order = op.allOrders.firstWhere((o) => o.id == inv.orderId, orElse: () => throw Exception('Order not found'));
    final items = await op.getOrderItems(inv.orderId!);
    final cust = inv.customerId != null ? cp.findById(inv.customerId!) : null;
    final path = await ip.generatePdf(invoice: inv, business: bp.business!, order: order, items: items, customer: cust);
    if (path != null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated')));
  }

  void _showOrderSheet() {
    final completed = context.read<OrderProvider>().allOrders.where((o) => o.status == 'Completed').toList();
    showCupertinoModalPopup(context: context, builder: (_) => CupertinoActionSheet(
      title: const Text('Create Invoice From Order'),
      actions: completed.isEmpty
        ? [CupertinoActionSheetAction(onPressed: () {}, child: const Text('No completed orders', style: TextStyle(color: CupertinoColors.systemGrey)))]
        : completed.map((o) => CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _createFromOrder(o); },
            child: Text('#${o.id.substring(0, 8)} — R ${o.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
          )).toList(),
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), isDefaultAction: true, child: const Text('Cancel')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showOrderSheet)]),
      body: ip.loading
        ? const Center(child: CircularProgressIndicator())
        : ip.invoices.isEmpty
          ? Center(child: Text('No invoices yet', style: Theme.of(context).textTheme.bodyMedium))
          : ListView(padding: const EdgeInsets.all(16), children: [
              ...ip.invoices.map((inv) => _InvoiceCard(
                invoice: inv,
                onGenerate: () => _generatePdf(inv),
                onShare: () => ip.shareInvoice(inv.pdfPath!),
                onWa: () => ip.shareViaWhatsApp(inv.pdfPath!),
                onMarkPaid: () => ip.updateStatus(inv.id, 'Paid'))),
            ]),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onGenerate, onShare, onWa, onMarkPaid;

  const _InvoiceCard({required this.invoice, required this.onGenerate, required this.onShare, required this.onWa, required this.onMarkPaid});

  Color _sc(String s) => switch (s) { 'Paid' => T.s, 'Sent' => T.p, _ => T.w };

  @override
  Widget build(BuildContext context) {
    final sc = _sc(invoice.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(invoice.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc))),
          const Spacer(),
          Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Text(_InvoiceListScreenState._df.format(invoice.createdAt), style: TextStyle(fontSize: 12, color: T.t2)),
        const SizedBox(height: 10),
        Row(children: [
          if (invoice.pdfPath == null)
            ElevatedButton.icon(onPressed: onGenerate, icon: const Icon(Icons.picture_as_pdf, size: 16), label: const Text('Generate PDF'), style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)))
          else ...[
            OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.share, size: 14), label: const Text('Share'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 10))),
            const SizedBox(width: 6),
            OutlinedButton.icon(onPressed: onWa, icon: const Icon(Icons.chat, size: 14, color: Color(0xFF25D366)), label: const Text('WhatsApp'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 10))),
          ],
          if (invoice.status == 'Sent') ...[const Spacer(), TextButton(onPressed: onMarkPaid, child: const Text('Mark Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: T.s)))],
        ]),
      ])),
    );
  }
}

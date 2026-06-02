import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) context.read<InvoiceProvider>().loadInvoices(b.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();
    final bp = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: ip.loading && ip.invoices.isEmpty ? const Center(child: CircularProgressIndicator()) :
        ip.invoices.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: SpiceColors.primaryBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description_outlined, color: SpiceColors.primaryLight, size: 28)),
          const SizedBox(height: 12), Text('No invoices', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4), Text('Generate invoices from completed orders', style: GoogleFonts.inter(fontSize: 12, color: SpiceColors.textSecondary)),
          const SizedBox(height: 12), ElevatedButton(onPressed: _createFromOrder, child: const Text('Create Invoice')),
        ])) :
        ListView.builder(padding: const EdgeInsets.all(12), itemCount: ip.invoices.length, itemBuilder: (_, i) {
          final inv = ip.invoices[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _statusColor(inv.status as String).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(inv.status as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(inv.status as String)))),
                  const Spacer(),
                  Text(inv.invoiceNumber as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Text(DateFormat('dd MMM yyyy').format(inv.createdAt as DateTime), style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textTertiary)),
                const SizedBox(height: 10),
                Row(children: [
                  if (inv.pdfPath == null) ...[
                    Expanded(child: ElevatedButton(onPressed: () => _generatePdf(inv), style: ElevatedButton.styleFrom(minimumSize: const Size(0, 34)), child: const Text('Generate PDF', style: TextStyle(fontSize: 12)))),
                  ] else ...[
                    Expanded(child: OutlinedButton(onPressed: () { if ((inv.pdfPath as String).isNotEmpty) { final f = File(inv.pdfPath as String); if (f.existsSync()) Share.shareXFiles([XFile(f.path)], text: 'Invoice ${inv.invoiceNumber}'); }}, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34)), child: const Text('Share', style: TextStyle(fontSize: 12)))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () async { final msg = 'Invoice ${inv.invoiceNumber}'; final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34)), child: const Text('WhatsApp', style: TextStyle(fontSize: 12)))),
                  ],
                  if (inv.status == 'Sent') ...[const SizedBox(width: 8), Expanded(child: TextButton(onPressed: () => context.read<InvoiceProvider>().updateStatus(inv.id as String, 'Paid'), style: TextButton.styleFrom(foregroundColor: SpiceColors.success, minimumSize: const Size(0, 34)), child: const Text('Mark Paid', style: TextStyle(fontSize: 12))))],
                ]),
              ]),
            ),
          );
        }),
    );
  }

  Color _statusColor(String s) => s == 'Paid' ? SpiceColors.success : s == 'Sent' ? SpiceColors.primaryLight : s == 'Draft' ? SpiceColors.textSecondary : SpiceColors.error;

  Future<void> _generatePdf(dynamic inv) async {
    final bp = context.read<BusinessProvider>().business;
    final op = context.read<OrderProvider>();
    final cp = context.read<CustomerProvider>();
    final ip = context.read<InvoiceProvider>();
    if (bp == null) return;
    final order = op.orders.where((o) => o.id == inv.orderId).firstOrNull;
    if (order == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order not found'), behavior: SnackBarBehavior.floating)); return; }
    final items = await op.getOrderItems(order.id);
    dynamic customer;
    if (order.customerId != null) customer = cp.findById(order.customerId!);
    final path = await ip.generatePdf(invoice: inv, business: bp, order: order, items: items, customer: customer);
    if (path != null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated'), behavior: SnackBarBehavior.floating));
  }

  void _createFromOrder() {
    final orders = context.read<OrderProvider>().orders;
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))), builder: (ctx) {
      return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create Invoice from Order', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...orders.where((o) => o.status == 'Completed').take(10).map((o) => ListTile(
          title: Text('Order #${(o.id).substring(0, 8).toUpperCase()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: Text('${AppConstants.formatCurrency(o.total)} · ${o.orderType}', style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textSecondary)),
          onTap: () async {
            Navigator.pop(ctx);
            final b = context.read<BusinessProvider>().business;
            if (b == null) return;
            await context.read<InvoiceProvider>().createFromOrder(businessId: b.id, invoicePrefix: b.invoicePrefix ?? 'INV', orderId: o.id, customerId: o.customerId);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created'), behavior: SnackBarBehavior.floating));
          },
        )).toList(),
        if (orders.where((o) => o.status == 'Completed').isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No completed orders', style: GoogleFonts.inter(color: SpiceColors.textSecondary)))),
        const SizedBox(height: 8),
      ])));
    });
  }
}

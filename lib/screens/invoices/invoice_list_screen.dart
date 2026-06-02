import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/invoice.dart';
import '../../models/order.dart';
import '../../models/customer.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final business = context.read<BusinessProvider>().business;
    if (business != null) {
      context.read<InvoiceProvider>().loadInvoices(business.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateInvoiceSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.invoices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No invoices yet', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 4),
                Text('Generate invoices from orders or create manually',
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.invoices.length,
          itemBuilder: (context, index) {
            final invoice = provider.invoices[index];
            return _InvoiceCard(invoice: invoice);
          },
        );
      },
    );
  }

  void _showCreateInvoiceSheet() {
    final orders = context.read<OrderProvider>().orders;
    final business = context.read<BusinessProvider>().business;
    if (business == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Invoice', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text('Select an order to invoice:',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No orders available. Complete a sale first.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[500])),
                  ),
                ),
              ...orders.take(10).map((order) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF27AE60).withOpacity(0.1),
                  child: Text('${AppConstants.formatCurrency(order.total)}',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF27AE60))),
                ),
                title: Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text('${order.orderType} · ${order.paymentMethod}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _createInvoiceForOrder(order);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvoiceForOrder(OrderModel order) async {
    final business = context.read<BusinessProvider>().business;
    if (business == null) return;

    final provider = context.read<InvoiceProvider>();
    final invoice = await provider.createFromOrder(
      businessId: business.id,
      invoicePrefix: business.invoicePrefix ?? 'INV',
      orderId: order.id,
      customerId: order.customerId,
    );

    if (invoice != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${invoice.invoiceNumber} created')),
      );
    }
  }
}

class _InvoiceCard extends StatefulWidget {
  final Invoice invoice;
  const _InvoiceCard({required this.invoice});

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _generating = false;

  Future<void> _generateAndShare() async {
    setState(() => _generating = true);

    final invoiceProvider = context.read<InvoiceProvider>();
    final businessProvider = context.read<BusinessProvider>();
    final orderProvider = context.read<OrderProvider>();
    final customerProvider = context.read<CustomerProvider>();

    final business = businessProvider.business;
    if (business == null) {
      setState(() => _generating = false);
      return;
    }

    final order = orderProvider.orders
        .where((o) => o.id == widget.invoice.orderId)
        .firstOrNull;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order not found')),
      );
      setState(() => _generating = false);
      return;
    }

    final items = await orderProvider.getOrderItems(order.id);
    Customer? customer;
    if (order.customerId != null) {
      customer = customerProvider.findById(order.customerId!);
    }

    final path = await invoiceProvider.generatePdf(
      invoice: widget.invoice,
      business: business,
      order: order,
      items: items,
      customer: customer,
    );

    setState(() => _generating = false);

    if (path != null && mounted) {
      _showShareOptions(path, customer);
    }
  }

  void _showShareOptions(String pdfPath, Customer? customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invoice Ready!', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${widget.invoice.invoiceNumber}',
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  child: Icon(Icons.whatshot, color: Colors.white),
                ),
                title: Text('Send via WhatsApp',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: customer != null
                    ? Text(customer.name, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<InvoiceProvider>().shareViaWhatsApp(pdfPath,
                      phoneNumber: customer?.whatsappNumber);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.orange,
                  child: Icon(Icons.share, color: Colors.white),
                ),
                title: Text('Share / Open', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Share via any app or open PDF',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<InvoiceProvider>().shareInvoice(pdfPath);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.brown,
                  child: Icon(Icons.print, color: Colors.white),
                ),
                title: Text('Print', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Print via system print dialog',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<InvoiceProvider>().shareInvoice(pdfPath);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid': return const Color(0xFF27AE60);
      case 'Sent': return Colors.blue;
      case 'Draft': return Colors.grey;
      case 'Cancelled': return AppColors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Paid': return Icons.check_circle;
      case 'Sent': return Icons.send;
      case 'Draft': return Icons.edit_note;
      case 'Cancelled': return Icons.cancel;
      default: return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(invoice.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(invoice.status), size: 14, color: _statusColor(invoice.status)),
                      const SizedBox(width: 4),
                      Text(invoice.status,
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(invoice.status))),
                    ],
                  ),
                ),
                const Spacer(),
                Text(invoice.invoiceNumber,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${invoice.createdAt.day.toString().padLeft(2, '0')}/${invoice.createdAt.month.toString().padLeft(2, '0')}/${invoice.createdAt.year}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (invoice.pdfPath != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<InvoiceProvider>().openPdf(invoice.pdfPath!),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<InvoiceProvider>().shareViaWhatsApp(invoice.pdfPath!),
                      icon: const Icon(Icons.whatshot, size: 16, color: Color(0xFF25D366)),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34)),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : _generateAndShare,
                      icon: _generating
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf, size: 16),
                      label: Text(_generating ? 'Generating...' : 'Generate PDF', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        backgroundColor: AppColors.orange,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                if (invoice.status == 'Sent')
                  Material(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => context.read<InvoiceProvider>().updateStatus(invoice.id, 'Paid'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Mark Paid', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF27AE60))),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

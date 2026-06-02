import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) context.read<OrderProvider>().loadOrders(b.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    return Scaffold(
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(children: [
            _chip('All', _statusFilter == null, () { setState(() { _statusFilter = null; op.setStatusFilter(null); }); }),
            ...AppConstants.orderStatuses.map((s) => _chip(s, _statusFilter == s, () {
              setState(() { _statusFilter = s; op.setStatusFilter(s); });
              final b = context.read<BusinessProvider>().business;
              if (b != null) op.loadOrders(b.id);
            })),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Theme.of(context).brightness == Brightness.dark ? SpiceColors.darkSurface : SpiceColors.surfaceAlt,
          child: Row(children: const [
            SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5))),
            Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5))),
            Expanded(flex: 1, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5), textAlign: TextAlign.right)),
            SizedBox(width: 44),
          ]),
        ),
        Expanded(
          child: op.loading && op.orders.isEmpty ? const Center(child: CircularProgressIndicator()) :
          op.orders.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: SpiceColors.primaryBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long, color: SpiceColors.primaryLight, size: 28)),
            const SizedBox(height: 12), Text('No orders', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ])) :
          ListView.builder(itemCount: op.orders.length, itemBuilder: (_, i) => _OrderRow(order: op.orders[i])),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: selected ? SpiceColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? SpiceColors.primary : SpiceColors.cardBorder)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? Colors.white : SpiceColors.textSecondary))),
    ),
  );
}

class _OrderRow extends StatefulWidget {
  final dynamic order;
  const _OrderRow({required this.order});
  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _expanded = false;
  List<dynamic>? _items;

  Color _statusColor(String s) => switch (s) { 'Completed' => SpiceColors.success, 'Cancelled' => SpiceColors.error, 'Pending' => SpiceColors.warning, 'Preparing' => SpiceColors.primaryLight, _ => SpiceColors.textSecondary };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final status = order.status as String;
    final date = DateFormat('dd/MM HH:mm').format(order.createdAt as DateTime);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder))),
      child: Column(children: [
        InkWell(
          onTap: () async {
            if (!_expanded) _items = await context.read<OrderProvider>().getOrderItems(order.id as String);
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: SpiceColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.orderType ?? '—', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                Text(date, style: GoogleFonts.inter(fontSize: 10, color: SpiceColors.textTertiary)),
              ])),
              Expanded(
                flex: 1,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status)), textAlign: TextAlign.center)),
              ),
              Expanded(
                flex: 1,
                child: Text(AppConstants.formatCurrency((order.total as num).toDouble()), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
        if (_expanded && _items != null) Container(
          padding: const EdgeInsets.fromLTRB(40, 0, 14, 10),
          child: Column(children: [
            ...?_items?.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text(item.productName as String, style: GoogleFonts.inter(fontSize: 12))),
                Text('×${item.qty}', style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textSecondary)),
                const SizedBox(width: 10),
                Text(AppConstants.formatCurrency((item.total as num).toDouble()), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            )),
            const SizedBox(height: 8),
            Row(children: [
              if (status != 'Completed' && status != 'Cancelled') ...[
                Expanded(child: OutlinedButton(onPressed: () => context.read<OrderProvider>().updateStatus(order.id as String, 'Completed'), style: OutlinedButton.styleFrom(foregroundColor: SpiceColors.success, minimumSize: const Size(0, 32)), child: const Text('Complete', style: TextStyle(fontSize: 11)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => context.read<OrderProvider>().updateStatus(order.id as String, 'Cancelled'), style: OutlinedButton.styleFrom(foregroundColor: SpiceColors.error, minimumSize: const Size(0, 32)), child: const Text('Cancel', style: TextStyle(fontSize: 11)))),
              ],
              if (status == 'Completed')
                Expanded(child: OutlinedButton.icon(onPressed: () async {
                  final msg = 'Order #${(order.id as String).substring(0, 8).toUpperCase()}\nDate: $date\nTotal: ${AppConstants.formatCurrency((order.total as num).toDouble())}\nPayment: ${order.paymentMethod}';
                  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                }, icon: const Icon(Icons.whatshot, size: 14, color: Color(0xFF25D366)), label: const Text('WhatsApp', style: TextStyle(fontSize: 11)), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/glass_theme.dart';
import '../../core/constants.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String? _statusFilter;

  void _load() { final b = context.read<BusinessProvider>().business; if (b != null) context.read<OrderProvider>().loadOrders(b.id); }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  @override
  Widget build(BuildContext c) {
    final op = context.watch<OrderProvider>();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Orders')),
      child: SafeArea(
        child: Column(children: [
          SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
            _chip('All', _statusFilter == null, () { setState(() { _statusFilter = null; op.setStatusFilter(null); _load(); }); }),
            ...AppConstants.orderStatuses.map((s) => _chip(s, _statusFilter == s, () { setState(() { _statusFilter = s; op.setStatusFilter(s); _load(); }); })),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: c.isGlassDark ? const Color(0x33000000) : const Color(0x33C7C7CC), child: Row(children: const [Expanded(flex: 2, child: Text('Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2))), Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2))), Expanded(flex: 1, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GlassColors.lightText2), textAlign: TextAlign.right)), SizedBox(width: 44)])),
          Expanded(
            child: op.loading && op.orders.isEmpty ? const Center(child: CupertinoActivityIndicator()) :
            op.orders.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.doc_text, size: 40, color: c.glassText3), const SizedBox(height: 8), const Text('No orders', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ])) :
            ListView.builder(itemCount: op.orders.length, itemBuilder: (_, i) => _OrderRow(order: op.orders[i])),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? GlassColors.primary : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? GlassColors.primary : context.glassBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? const Color(0xFFFFFFFF) : context.glassText2)),
        ),
      ),
    );
  }
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

  Color _sc(String s) => s == 'Completed' ? GlassColors.success : s == 'Cancelled' ? GlassColors.error : s == 'Pending' ? GlassColors.warning : GlassColors.primary;

  @override
  Widget build(BuildContext c) {
    final order = widget.order;
    final status = order.status as String;
    final date = DateFormat('dd/MM HH:mm').format(order.createdAt as DateTime);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.glassBorder.withValues(alpha: 0.3), width: 0.5))),
      child: Column(children: [
        CupertinoButton(
          padding: EdgeInsets.zero, alignment: Alignment.centerLeft,
          onPressed: () async {
            if (!_expanded) _items = await context.read<OrderProvider>().getOrderItems(order.id as String);
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(_expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 14, color: c.glassText3),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.orderType ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.glassText)), Text(date, style: TextStyle(fontSize: 10, color: c.glassText3))])),
              Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _sc(status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _sc(status)), textAlign: TextAlign.center))),
              Expanded(flex: 1, child: Text(AppConstants.formatCurrency((order.total as num).toDouble()), textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.glassText))),
            ]),
          ),
        ),
        if (_expanded && _items != null) Container(
          padding: const EdgeInsets.fromLTRB(30, 0, 14, 12),
          child: Column(children: [
            ...?_items?.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [Expanded(child: Text(item.productName ?? '', style: const TextStyle(fontSize: 12))), Text('×${item.qty}', style: TextStyle(fontSize: 11, color: c.glassText2)), const SizedBox(width: 10), Text(AppConstants.formatCurrency((item.total as num).toDouble()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]),
            )),
            const SizedBox(height: 8),
            Row(children: [
              if (status != 'Completed' && status != 'Cancelled') ...[
                Expanded(child: CupertinoButton(padding: EdgeInsets.zero, child: const Text('Complete', style: TextStyle(fontSize: 11, color: GlassColors.success)), onPressed: () { context.read<OrderProvider>().updateStatus(order.id, 'Completed'); setState(() => _expanded = false); })),
                Expanded(child: CupertinoButton(padding: EdgeInsets.zero, child: const Text('Cancel', style: TextStyle(fontSize: 11, color: GlassColors.error)), onPressed: () { context.read<OrderProvider>().updateStatus(order.id, 'Cancelled'); setState(() => _expanded = false); })),
              ],
              if (status == 'Completed') Expanded(child: CupertinoButton(padding: EdgeInsets.zero, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.share_up, size: 14, color: const Color(0xFF25D366)), const SizedBox(width: 4), const Text('WhatsApp', style: TextStyle(fontSize: 11, color: Color(0xFF25D366)))]), onPressed: () async {
                final msg = 'Order #${(order.id as String).substring(0, 8).toUpperCase()}\nDate: $date\nTotal: R ${(order.total as num).toDouble().toStringAsFixed(2)}';
                final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              })),
            ]),
          ]),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/order.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  static final _df = DateFormat('MMM d, HH:mm');
  final _expanded = <String>{};
  final _items = <String, List<OrderItem>>{};
  String? _statusFilter;
  static const _statuses = [null, 'Pending', 'Confirmed', 'Preparing', 'Ready', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) { final op = context.read<OrderProvider>(); op.clearFilters(); op.loadOrders(b.id); }
    });
  }

  void _onFilter(String? s) {
    setState(() => _statusFilter = s);
    final op = context.read<OrderProvider>(); op.setStatusFilter(s);
    final b = context.read<BusinessProvider>().business;
    if (b != null) op.loadOrders(b.id);
  }

  Future<void> _toggle(OrderModel o) async {
    if (_expanded.contains(o.id)) {
      setState(() => _expanded.remove(o.id));
    } else {
      if (!_items.containsKey(o.id)) _items[o.id] = await context.read<OrderProvider>().getOrderItems(o.id);
      setState(() => _expanded.add(o.id));
    }
  }

  Future<void> _shareWa(OrderModel o) async {
    final cp = context.read<CustomerProvider>();
    final c = o.customerId != null ? cp.findById(o.customerId!) : null;
    final its = _items[o.id];
    final sb = StringBuffer('*Order #${o.id.substring(0, 8)}*\n\n');
    if (its != null) {
      for (final i in its) { sb.writeln('${i.productName} ×${i.qty} — R ${i.total.toStringAsFixed(2)}'); }
    }
    sb.writeln('\n*Total: R ${o.total.toStringAsFixed(2)}*');
    final msg = Uri.encodeComponent(sb.toString());
    final phone = c?.whatsappNumber?.replaceAll('+', '') ?? '';
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color _sc(String s) => switch (s) { 'Pending' => T.w, 'Confirmed' => T.p, 'Preparing' => T.pL, 'Ready' => T.s, 'Completed' => T.s, _ => T.e };

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final op = context.watch<OrderProvider>();
    final t2 = d ? T.dt2 : T.t2;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(children: [
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final s in _statuses) _chip(s ?? 'All', _statusFilter == s, () => _onFilter(s)),
        ])),
        const Divider(height: 1),
        Expanded(child: op.loading
          ? const Center(child: CircularProgressIndicator())
          : op.orders.isEmpty
            ? Center(child: Text('No orders found', style: Theme.of(context).textTheme.bodyMedium))
            : ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
                  Expanded(flex: 3, child: Text('Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2))),
                  SizedBox(width: 80, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t2))),
                ])),
                ...op.orders.map((o) => _OrderTile(
                  order: o, t2: t2, expanded: _expanded.contains(o.id), items: _items[o.id],
                  onToggle: () => _toggle(o),
                  onComplete: () => op.updateStatus(o.id, 'Completed'),
                  onCancel: () => op.updateStatus(o.id, 'Cancelled'),
                  onWa: () => _shareWa(o),
                  sc: _sc(o.status),
                )),
              ])),
      ]),
    );
  }

  Widget _chip(String l, bool s, VoidCallback t) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
    label: Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: s ? Colors.white : null)),
    selected: s, onSelected: (_) => t(), selectedColor: T.p,
    backgroundColor: T.p.withValues(alpha: 0.08), side: BorderSide(color: s ? T.p : T.bd), visualDensity: VisualDensity.compact));
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final Color t2, sc;
  final bool expanded;
  final List<OrderItem>? items;
  final VoidCallback onToggle, onComplete, onCancel, onWa;

  const _OrderTile({required this.order, required this.t2, required this.sc, required this.expanded,
    this.items, required this.onToggle, required this.onComplete, required this.onCancel, required this.onWa});

  @override
  Widget build(BuildContext context) {
    final isFinal = order.status == 'Completed' || order.status == 'Cancelled';

    return Column(children: [
      InkWell(onTap: onToggle, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.orderType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(_OrderListScreenState._df.format(order.createdAt), style: TextStyle(fontSize: 11, color: T.t3)),
        ])),
        Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(order.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc)))),
        SizedBox(width: 80, child: Text('R ${order.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        SizedBox(width: 24, child: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: T.t3, size: 18)),
      ]))),
      if (expanded) ...[
        if (items != null && items!.isNotEmpty)
          ...items!.map((i) => Padding(padding: const EdgeInsets.only(left: 12, bottom: 6), child: Row(children: [
            Icon(Icons.circle, size: 5, color: T.t3), const SizedBox(width: 8),
            Text('${i.productName} × ${i.qty}', style: TextStyle(fontSize: 12, color: T.t2)),
            const Spacer(), Text('R ${i.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ]))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (isFinal && order.status == 'Completed')
            OutlinedButton.icon(onPressed: onWa, icon: const Icon(Icons.chat, size: 14, color: Color(0xFF25D366)), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)), label: const Text('WhatsApp', style: TextStyle(fontSize: 11))),
          if (!isFinal) ...[
            TextButton(onPressed: onCancel, child: const Text('Cancel', style: TextStyle(color: T.e, fontSize: 12))),
            const SizedBox(width: 4),
            ElevatedButton(onPressed: onComplete, style: ElevatedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 14)), child: const Text('Complete', style: TextStyle(fontSize: 12))),
          ],
        ]),
        const SizedBox(height: 4),
      ],
      const Divider(height: 1),
    ]);
  }
}

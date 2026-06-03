import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/constants.dart';

class OrderListScreen extends StatefulWidget { const OrderListScreen({super.key}); @override State<OrderListScreen> createState() => _OrderListScreenState(); }
class _OrderListScreenState extends State<OrderListScreen> {
  String? _sf;
  void _load() { final b = context.read<BusinessProvider>().business; if (b != null) context.read<OrderProvider>().loadOrders(b.id); }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }

  @override
  Widget build(BuildContext c) {
    final op = context.watch<OrderProvider>();
    return Scaffold(
      body: Column(children: [
        SizedBox(height: 30, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          _chip('All', _sf == null, () { setState(() { _sf = null; op.setStatusFilter(null); _load(); }); }),
          ...const ['Completed', 'Pending', 'Preparing', 'Cancelled'].map((s) => _chip(s, _sf == s, () { setState(() { _sf = s; op.setStatusFilter(s); _load(); }); })),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [Expanded(flex:2,child:Text('ORDER',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.grey))),Expanded(flex:1,child:Text('STATUS',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.grey))),Expanded(flex:1,child:Text('TOTAL',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.grey),textAlign:TextAlign.right)),SizedBox(width:24)])),
        Expanded(
          child: op.orders.isEmpty ? Center(child: Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.receipt_long,size:48,color:Colors.grey),const SizedBox(height:12),const Text('No orders',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600))])) :
          ListView.builder(itemCount: op.orders.length, itemBuilder: (_, i) {
            final o = op.orders[i]; final st = o.status; final dt = DateFormat('dd/MM HH:mm').format(o.createdAt);
            final sc = st == 'Completed' ? Colors.green : st == 'Cancelled' ? Colors.red : st == 'Pending' ? Colors.orange : Colors.blue;
            return _Row(o: o, st: st, dt: dt, sc: sc);
          }),
        ),
      ]),
    );
  }

  Widget _chip(String l, bool a, VoidCallback t) => Padding(padding: const EdgeInsets.only(right:6), child: GestureDetector(onTap:t, child: Container(padding: const EdgeInsets.symmetric(horizontal:12,vertical:6), decoration: BoxDecoration(color:a?Colors.blue:null,borderRadius:BorderRadius.circular(16),border:Border.all(color:a?Colors.blue:Colors.grey.shade300)), child: Text(l, style: TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:a?Colors.white:Colors.grey.shade700)))));
}

class _Row extends StatefulWidget { final dynamic o; final String st, dt; final Color sc; const _Row({required this.o,required this.st,required this.dt,required this.sc}); @override State<_Row> createState() => _RowState(); }
class _RowState extends State<_Row> { bool _x = false; List<dynamic>? _it;

  @override
  Widget build(BuildContext c) => Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))), child: Column(children: [
    InkWell(onTap: () async { if (!_x) _it = await context.read<OrderProvider>().getOrderItems(widget.o.id as String); setState(() => _x = !_x); },
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
        Icon(_x ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(flex:2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.o.orderType ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), Text(widget.dt, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
        Expanded(flex:1, child: Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration: BoxDecoration(color: widget.sc.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4)), child: Text(widget.st, style: TextStyle(fontSize:10,fontWeight:FontWeight.w600,color:widget.sc), textAlign: TextAlign.center))),
        Expanded(flex:1, child: Text(AppConstants.formatCurrency((widget.o.total as num).toDouble()), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ])),
    ),
    if (_x && _it != null) Container(padding: const EdgeInsets.fromLTRB(30, 0, 14, 12), child: Column(children: [
      ...?_it?.map((it) => Padding(padding: const EdgeInsets.symmetric(vertical:2), child: Row(children: [Expanded(child: Text(it.productName ?? '', style: const TextStyle(fontSize:12))), Text('×${it.qty}', style: const TextStyle(fontSize:11,color:Colors.grey)), const SizedBox(width:10), Text(AppConstants.formatCurrency((it.total as num).toDouble()), style: const TextStyle(fontSize:12,fontWeight:FontWeight.w500))]))),
      const SizedBox(height:8),
      Row(children: [
        if (widget.st != 'Completed' && widget.st != 'Cancelled') ...[
          Expanded(child: TextButton(onPressed: ()=>context.read<OrderProvider>().updateStatus(widget.o.id,'Completed'), style: TextButton.styleFrom(foregroundColor:Colors.green,minimumSize:const Size(0,32)), child: const Text('Complete',style:TextStyle(fontSize:11)))),
          const SizedBox(width:8),
          Expanded(child: TextButton(onPressed: ()=>context.read<OrderProvider>().updateStatus(widget.o.id,'Cancelled'), style: TextButton.styleFrom(foregroundColor:Colors.red,minimumSize:const Size(0,32)), child: const Text('Cancel',style:TextStyle(fontSize:11)))),
        ],
        if (widget.st == 'Completed') Expanded(child: TextButton.icon(onPressed: () async {
          final m = 'Order #${(widget.o.id as String).substring(0,8).toUpperCase()}\nDate: ${widget.dt}\nTotal: R ${(widget.o.total as num).toDouble().toStringAsFixed(2)}\nPayment: ${widget.o.paymentMethod ?? "N/A"}';
          final u = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(m)}');
          if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
        }, icon: const Icon(Icons.whatshot, size: 14, color: Color(0xFF25D366)), label: const Text('WhatsApp', style: TextStyle(fontSize:11)), style: TextButton.styleFrom(minimumSize: const Size(0,32)))),
      ]),
    ])),
  ]));
}

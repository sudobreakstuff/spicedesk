import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../workspace/domain/workspace_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _loading = true;
  String? _error;
  String? _expandedTxn;
  Map<String, List<Map<String, dynamic>>> _txnItems = {};

  final currency = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) {
      if (mounted) setState(() { _loading = false; _error = 'No workspace selected'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final results = await Future.wait([
        supabase.from('sales_transactions').select('id,transaction_number,grand_total,payment_method,created_at,customers(name),invoices(invoice_number)').eq('workspace_id',wsId).order('created_at',ascending:false).limit(500),
        supabase.from('expenses').select('id,description,category,amount,expense_date').eq('workspace_id',wsId).order('created_at',ascending:false).limit(200),
        supabase.from('sale_items').select('product_name,quantity').eq('workspace_id',wsId).limit(500),
      ]);
      if (mounted) {
        setState(() {
          _sales = results[0].cast<Map<String, dynamic>>();
          _expenses = results[1].cast<Map<String, dynamic>>();
          _topProducts = _aggregateProducts(results[2].cast<Map<String, dynamic>>());
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> _aggregateProducts(List<Map<String, dynamic>> items) {
    final Map<String, double> totals = {};
    for (final item in items) {
      final name = item['product_name'] as String? ?? 'Unknown';
      totals[name] = (totals[name] ?? 0) + ((item['quantity'] as num?)?.toDouble() ?? 0);
    }
    final list = totals.entries.map((e) => <String, dynamic>{'name': e.key, 'total': e.value}).toList();
    list.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return list;
  }

  double get _revenue => _sales.fold(0, (s, t) => s + ((t['grand_total'] as num?)?.toDouble() ?? 0));
  double get _costs => _expenses.fold(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

  Future<void> _toggleExpand(String txnId) async {
    if (_expandedTxn == txnId) { setState(() => _expandedTxn = null); return; }
    setState(() => _expandedTxn = txnId);
    if (!_txnItems.containsKey(txnId)) {
      final wsId = ref.read(workspaceStateProvider).selectedId;
      final items = await supabase.from('sale_items').select('product_name,quantity,unit_price,line_total').eq('transaction_id',txnId).eq('workspace_id',wsId??'');
      if (mounted) setState(() => _txnItems[txnId] = items.cast<Map<String,dynamic>>());
    }
  }

  @override
  Widget build(BuildContext context) {
    final wsId = ref.watch(workspaceStateProvider);
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: RefreshIndicator(
        onRefresh: () async { _load(); },
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
            const SizedBox(height: 6),
            Text(wsId.selectedName ?? 'No workspace', style: const TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
            const SizedBox(height: 28),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.danger)),
                child: Column(children: [
                  const Text('Error loading data', style: TextStyle(color: SpiceColors.danger, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]),
              )
            else ...[
              // Summary
              Wrap(spacing: 16, runSpacing: 16, children: [
                _card('Revenue', currency.format(_revenue), SpiceColors.accent, Icons.trending_up),
                _card('Expenses', currency.format(_costs), SpiceColors.danger, Icons.money_off),
                _card('Profit', currency.format(_revenue - _costs), (_revenue - _costs) >= 0 ? SpiceColors.accent : SpiceColors.danger, Icons.account_balance),
                _card('Transactions', '${_sales.length}', SpiceColors.primary, Icons.receipt_long),
              ]),
              const SizedBox(height: 36),
              // Top products
              if (_topProducts.isNotEmpty) ...[
                const Text('Products Sold', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Sold', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      ]),
                    ),
                    ..._topProducts.take(10).toList().asMap().entries.map((e) {
                      final p = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: e.key % 2 == 0 ? SpiceColors.surfaceAlt.withAlpha(60) : Colors.transparent, border: const Border(top: BorderSide(color: SpiceColors.border))),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                          Expanded(flex: 1, child: Text('${(p['total'] as double).toInt()}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.primary))),
                        ]),
                      );
                    }),
                  ]),
                ),
                const SizedBox(height: 36),
              ],
              // Transaction table
              const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              const SizedBox(height: 4),
              Text('${_sales.length} total', style: const TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              const SizedBox(height: 12),
              if (_sales.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: const Center(child: Text('No transactions yet. Make a sale in POS first.', style: TextStyle(color: SpiceColors.textSecondary))),
                )
              else
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Txn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Method', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      ]),
                    ),
                     ..._sales.asMap().entries.expand((e) {
                       final s = e.value;
                       final txnId = s['id'] as String? ?? '';
                       final cust = s['customers'] as Map<String, dynamic>?;
                       final dt = DateTime.tryParse(s['created_at'] ?? '') ?? DateTime.now();
                       final total = (s['grand_total'] as num?)?.toDouble() ?? 0;
                       final isExpanded = _expandedTxn == txnId;
                       final items = _txnItems[txnId] ?? [];
                       final invoices = s['invoices'] as List<dynamic>?;
                       final invoiceNum = invoices != null && invoices.isNotEmpty ? (invoices[0] as Map<String, dynamic>)['invoice_number'] as String? : null;
                       return [
                         GestureDetector(
                           onTap: () => _toggleExpand(txnId),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                             decoration: BoxDecoration(color: e.key % 2 == 0 ? SpiceColors.surfaceAlt.withAlpha(60) : Colors.transparent, border: const Border(top: BorderSide(color: SpiceColors.border))),
                             child: Row(children: [
                               Expanded(flex: 3, child: Text(DateFormat('dd/MM/yy HH:mm').format(dt), style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                               Expanded(flex: 2, child: Text(s['transaction_number'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SpiceColors.primary))),
                               Expanded(flex: 2, child: Text(cust?['name'] ?? 'Walk-in', style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                               Expanded(flex: 1, child: Text((s['payment_method']??'').toString().substring(0,4), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SpiceColors.accent))),
                               Expanded(flex: 1, child: Text(currency.format(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent))),
                               const SizedBox(width: 4),
                               Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: SpiceColors.textSecondary),
                             ]),
                           ),
                         ),
                         if (isExpanded)
                           Container(
                             padding: const EdgeInsets.fromLTRB(40, 4, 16, 10),
                             decoration: BoxDecoration(color: SpiceColors.surfaceAlt.withAlpha(40), border: const Border(top: BorderSide(color: SpiceColors.border))),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (invoiceNum != null && invoiceNum.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(children: [
                                      const Text('Invoice: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary)),
                                      Text(invoiceNum!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
                                    ]),
                                  ),
                                if (items.isEmpty)
                                 const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                               else
                                 ...items.map((item) => Padding(
                                   padding: const EdgeInsets.only(bottom: 4),
                                   child: Row(children: [
                                     Expanded(child: Text('${(item['quantity'] as num?)?.toInt() ?? 0}x ${item['product_name'] ?? ''}', style: const TextStyle(fontSize: 12, color: SpiceColors.textPrimary))),
                                     Text(currency.format((item['line_total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                                   ]),
                                 )),
                             ]),
                           ),
                       ];
                     }),
                  ]),
                ),
            ],
            const SizedBox(height: 48),
            const Center(child: Text('Made by Shahid Singh', style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _card(String label, String value, Color accent, IconData icon) {
    return SizedBox(
      width: 340,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: accent, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
          ])),
        ]),
      ),
    );
  }
}

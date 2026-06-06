import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../workspace/domain/workspace_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  ReportsScreen({super.key});
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
  String _mostActiveCustomer = '';
  double _averageSpendPerCustomer = 0;
  String _bestDay = '';

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
      final salesQuery = supabase.from('sales_transactions').select('id,transaction_number,grand_total,payment_method,created_at,customers(name),invoices(invoice_number,status)').eq('workspace_id',wsId).order('created_at',ascending:false).limit(500);
      final expensesQuery = supabase.from('expenses').select('id,description,category,amount,expense_date').eq('workspace_id',wsId).order('created_at',ascending:false).limit(200);
      final itemsQuery = supabase.from('sale_items').select('product_name,quantity').eq('workspace_id',wsId).limit(500);
      final analyticsSales = supabase.from('sales_transactions').select('id,customer_id,created_at,grand_total').eq('workspace_id',wsId).limit(2000);
      final customersQuery = supabase.from('customers').select('id,name').eq('workspace_id',wsId).limit(2000);

      final results = await Future.wait([salesQuery, expensesQuery, itemsQuery, analyticsSales, customersQuery]);
      if (mounted) {
        setState(() {
          _sales = results[0].cast<Map<String, dynamic>>();
          _expenses = results[1].cast<Map<String, dynamic>>();
          _topProducts = _aggregateProducts(results[2].cast<Map<String, dynamic>>());
          _computeAnalytics(results[3].cast<Map<String, dynamic>>(), results[4].cast<Map<String, dynamic>>());
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

  void _computeAnalytics(List<Map<String, dynamic>> allSales, List<Map<String, dynamic>> allCustomers) {
    final customerMap = <String, String>{};
    for (final c in allCustomers) {
      customerMap[c['id']] = c['name'] as String? ?? 'Unknown';
    }

    final customerCounts = <String, int>{};
    double totalRev = 0;
    final dayCounts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (final s in allSales) {
      final cid = s['customer_id'] as String?;
      if (cid != null && cid.isNotEmpty) {
        customerCounts[cid] = (customerCounts[cid] ?? 0) + 1;
      }
      totalRev += (s['grand_total'] as num?)?.toDouble() ?? 0;
      final dt = DateTime.tryParse(s['created_at'] ?? '');
      if (dt != null) {
        dayCounts[dt.weekday - 1] = (dayCounts[dt.weekday - 1] ?? 0) + 1;
      }
    }

    String topCustName = '';
    int topCustCount = 0;
    for (final entry in customerCounts.entries) {
      if (entry.value > topCustCount) {
        topCustCount = entry.value;
        topCustName = customerMap[entry.key] ?? 'Unknown';
      }
    }

    final uniqueCustomers = customerCounts.keys.length;
    final avgSpend = uniqueCustomers > 0 ? totalRev / uniqueCustomers : 0.0;

    String bestDayName = 'N/A';
    int bestDayCount = 0;
    for (final entry in dayCounts.entries) {
      if (entry.value > bestDayCount) {
        bestDayCount = entry.value;
        bestDayName = dayNames[entry.key];
      }
    }

    _mostActiveCustomer = topCustName.isNotEmpty ? '$topCustName ($topCustCount)' : 'N/A';
    _averageSpendPerCustomer = avgSpend;
    _bestDay = '$bestDayName ($bestDayCount)';
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
            Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
            SizedBox(height: 6),
            Text(wsId.selectedName ?? 'No workspace', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
            SizedBox(height: 28),
            if (_loading)
              Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.danger)),
                child: Column(children: [
                  Text('Error loading data', style: TextStyle(color: SpiceColors.danger, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(_error!, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: Text('Retry')),
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
              SizedBox(height: 24),
              Wrap(spacing: 16, runSpacing: 16, children: [
                _card('Most Active Customer', _mostActiveCustomer, SpiceColors.primary, Icons.person),
                _card('Avg Spend / Customer', currency.format(_averageSpendPerCustomer), SpiceColors.accent, Icons.shopping_cart),
                _card('Best Day', _bestDay, SpiceColors.primary, Icons.calendar_today),
              ]),
              SizedBox(height: 36),
              // Top products
              if (_topProducts.isNotEmpty) ...[
                Text('Products Sold', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Sold', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      ]),
                    ),
                    ..._topProducts.take(10).toList().asMap().entries.map((e) {
                      final p = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: e.key % 2 == 0 ? SpiceColors.surfaceAlt.withAlpha(60) : Colors.transparent, border: Border(top: BorderSide(color: SpiceColors.border))),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(p['name'] ?? '', style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                          Expanded(flex: 1, child: Text('${(p['total'] as double).toInt()}', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.primary))),
                        ]),
                      );
                    }),
                  ]),
                ),
                SizedBox(height: 36),
              ],
              // Transaction table
              Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              SizedBox(height: 4),
              Text('${_sales.length} total', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              SizedBox(height: 12),
              if (_sales.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: Center(child: Text('No transactions yet. Make a sale in POS first.', style: TextStyle(color: SpiceColors.textSecondary))),
                )
              else
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                      child: Row(children: [
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
                             decoration: BoxDecoration(color: e.key % 2 == 0 ? SpiceColors.surfaceAlt.withAlpha(60) : Colors.transparent, border: Border(top: BorderSide(color: SpiceColors.border))),
                             child: Row(children: [
                               Expanded(flex: 3, child: Text(DateFormat('dd/MM/yy HH:mm').format(dt), style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                               Expanded(flex: 2, child: Text(s['transaction_number'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SpiceColors.primary))),
                               Expanded(flex: 2, child: Text(cust?['name'] ?? 'Walk-in', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                               Expanded(flex: 1, child: Text((s['payment_method']??'').toString().substring(0,4), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SpiceColors.accent))),
                               Expanded(flex: 1, child: Text(currency.format(total), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent))),
                               SizedBox(width: 4),
                               Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: SpiceColors.textSecondary),
                             ]),
                           ),
                         ),
                         if (isExpanded)
                           Container(
                             padding: const EdgeInsets.fromLTRB(40, 4, 16, 10),
                             decoration: BoxDecoration(color: SpiceColors.surfaceAlt.withAlpha(40), border: Border(top: BorderSide(color: SpiceColors.border))),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (invoiceNum != null && invoiceNum.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(children: [
                                      Text('Invoice: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary)),
                                      Text(invoiceNum, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
                                      Spacer(),
                                      Material(
                                        color: SpiceColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                        child: InkWell(
                                          onTap: () => _viewInvoice(invoices![0] as Map<String, dynamic>, s, cust, dt, total),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.primary))),
                                        ),
                                      ),
                                    ]),
                                  ),
                                if (items.isEmpty)
                                 Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                               else
                                 ...items.map((item) => Padding(
                                   padding: const EdgeInsets.only(bottom: 4),
                                   child: Row(children: [
                                     Expanded(child: Text('${(item['quantity'] as num?)?.toInt() ?? 0}x ${item['product_name'] ?? ''}', style: TextStyle(fontSize: 12, color: SpiceColors.textPrimary))),
                                     Text(currency.format((item['line_total'] as num?)?.toDouble() ?? 0), style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                                   ]),
                                 )),
                             ]),
                           ),
                       ];
                     }),
                  ]),
                ),
            ],
            SizedBox(height: 48),
            Center(child: Text('Made by Shahid Singh', style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary))),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _viewInvoice(Map<String, dynamic> invoice, Map<String, dynamic> sale, Map<String, dynamic>? cust, DateTime dt, double total) async {
    // Load invoice items from sale_items
    final wsId = ref.read(workspaceStateProvider).selectedId;
    List<Map<String, dynamic>> items = _txnItems[sale['id']] ?? [];
    if (items.isEmpty && wsId != null) {
      final data = await supabase.from('sale_items').select('product_name,quantity,unit_price,line_total').eq('transaction_id', sale['id']).eq('workspace_id', wsId);
      items = data.cast<Map<String, dynamic>>();
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: SpiceColors.border)),
          title: Text('Invoice ${invoice['invoice_number'] ?? ''}', style: TextStyle(color: SpiceColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _invRow('Date', DateFormat('dd MMM yyyy HH:mm').format(dt)),
              _invRow('Customer', cust?['name'] ?? 'Walk-in'),
              _invRow('Payment', sale['payment_method'] ?? ''),
              _invRow('Status', invoice['status'] ?? 'paid'),
              SizedBox(height: 12),
              Divider(color: SpiceColors.border),
              ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Expanded(child: Text('${(i['quantity'] as num?)?.toInt() ?? 0}x ${i['product_name'] ?? ''}', style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                  Text(currency.format((i['line_total'] as num?)?.toDouble() ?? 0), style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
                ]),
              )),
              Divider(color: SpiceColors.border),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                Text(currency.format(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SpiceColors.accent)),
              ]),
            ]),
          ),
          actions: [
            TextButton.icon(
              icon: Icon(Icons.print, size: 16),
              onPressed: () => _printInvoice(invoice, sale, cust, dt, total, items),
              label: Text('Print'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
          ],
        ),
      );
    }
  }

  Future<void> _printInvoice(Map<String, dynamic> invoice, Map<String, dynamic> sale, Map<String, dynamic>? cust, DateTime dt, double total, List<Map<String, dynamic>> items) async {
    try {
      final wsId = ref.read(workspaceStateProvider).selectedId;
      Map<String, dynamic> settings = {};
      if (wsId != null) {
        final data = await supabase.from('workspaces').select('settings').eq('id', wsId).maybeSingle();
        settings = (data?['settings'] as Map<String, dynamic>?) ?? {};
      }

      final companyName = settings['company_name']?.toString() ?? 'SpiceDesk';
      final companyAddress = settings['company_address']?.toString();
      final companyPhone = settings['company_phone']?.toString();
      final companyEmail = settings['company_email']?.toString();
      final taxNumber = settings['tax_number']?.toString();
      final bankName = settings['bank_name']?.toString();
      final accountHolder = settings['account_holder']?.toString();
      final accountNumber = settings['account_number']?.toString();
      final invoicePrefix = settings['invoice_prefix']?.toString() ?? 'INV-';
      final invoiceTerms = settings['invoice_terms']?.toString() ?? 'Payment due within 30 days';

      final doc = pw.Document();
      final invNum = invoice['invoice_number'] ?? sale['transaction_number'] ?? '';
      
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(companyName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (companyAddress != null && companyAddress.isNotEmpty) pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 10)),
              if (companyPhone != null && companyPhone.isNotEmpty) pw.Text('Tel: $companyPhone', style: const pw.TextStyle(fontSize: 10)),
              if (companyEmail != null && companyEmail.isNotEmpty) pw.Text('Email: $companyEmail', style: const pw.TextStyle(fontSize: 10)),
              if (taxNumber != null && taxNumber.isNotEmpty) pw.Text('VAT: $taxNumber', style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('$invoicePrefix$invNum', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Date: ${DateFormat('dd MMM yyyy').format(dt)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Customer: ${cust?['name'] ?? 'Walk-in'}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Payment: ${sale['payment_method'] ?? ''}', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ]),
          pw.SizedBox(height: 24),
          pw.Row(children: [
            pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          ]),
          pw.Divider(),
          ...items.expand((i) => [
            pw.Row(children: [
              pw.Expanded(flex: 3, child: pw.Text(i['product_name'] ?? '', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(flex: 1, child: pw.Text('${(i['quantity'] as num?)?.toInt() ?? 0}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('R ${((i['unit_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('R ${((i['line_total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
            ]),
          ]),
          pw.SizedBox(height: 16),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('TOTAL: R ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 24),
          if (bankName != null && bankName.isNotEmpty) ...[
            pw.Text('Banking Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Bank: $bankName', style: const pw.TextStyle(fontSize: 10)),
            if (accountHolder != null && accountHolder.isNotEmpty) pw.Text('Account Holder: $accountHolder', style: const pw.TextStyle(fontSize: 10)),
            if (accountNumber != null && accountNumber.isNotEmpty) pw.Text('Account: $accountNumber', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
          ],
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(invoiceTerms, style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
        ],
      ));

      await Printing.layoutPdf(onLayout: (format) async => await doc.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e'), backgroundColor: SpiceColors.danger));
      }
      debugPrint('PDF error: $e');
    }
  }

  Widget _invRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
      ]),
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
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
          ])),
        ]),
      ),
    );
  }
}

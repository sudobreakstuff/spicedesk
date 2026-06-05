import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../workspace/domain/workspace_state.dart';

class TransactionLineItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const TransactionLineItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}

class TransactionDetail {
  final String transactionId;
  final List<TransactionLineItem> items;

  const TransactionDetail({
    required this.transactionId,
    required this.items,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _filteredSales = [];
  bool _loading = false;

  String? _expandedTransactionId;
  final Map<String, TransactionDetail> _detailsCache = {};
  bool _detailsLoading = false;

  double _statsTotalSales = 0;
  String _statsMostBought = '—';
  double _statsAvgOrder = 0;
  int _statsTotalItems = 0;
  bool _statsLoading = false;

  final currency = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return;

    setState(() => _loading = true);

    final start = '${_startDate.toIso8601String().split('T')[0]} 00:00:00';
    final end = '${_endDate.toIso8601String().split('T')[0]} 23:59:59';

    final data = await supabase
        .from('sales_transactions')
        .select(
            'id, transaction_number, invoice_number, grand_total, payment_method, created_at, status, customers(name)')
        .eq('workspace_id', wsId)
        .gte('created_at', start)
        .lte('created_at', end)
        .order('created_at', ascending: false)
        .limit(200);

    if (mounted) {
      setState(() {
        _filteredSales = data;
        _loading = false;
        _expandedTransactionId = null;
        _detailsCache.clear();
      });
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return;

    setState(() => _statsLoading = true);

    try {
      final start = '${_startDate.toIso8601String().split('T')[0]} 00:00:00';
      final end = '${_endDate.toIso8601String().split('T')[0]} 23:59:59';

      final items = await supabase
          .from('sale_items')
          .select('quantity, product_name')
          .eq('workspace_id', wsId)
          .gte('created_at', start)
          .lte('created_at', end);

      final Map<String, double> productQtys = {};
      int totalItemsSold = 0;
      for (final item in items) {
        final q = (item['quantity'] as num?)?.toInt() ?? 0;
        final name = item['product_name'] as String? ?? 'Unknown';
        productQtys[name] = (productQtys[name] ?? 0) + q;
        totalItemsSold += q;
      }

      String mostBought = '—';
      double mostBoughtQty = 0;
      for (final entry in productQtys.entries) {
        if (entry.value > mostBoughtQty) {
          mostBoughtQty = entry.value;
          mostBought = entry.key;
        }
      }

      final totalSales = _filteredSales.fold<double>(
        0,
        (s, t) => s + ((t['grand_total'] as num?)?.toDouble() ?? 0),
      );
      final avgOrder = _filteredSales.isNotEmpty
          ? totalSales / _filteredSales.length
          : 0.0;

      if (mounted) {
        setState(() {
          _statsTotalSales = totalSales;
          _statsMostBought = mostBought;
          _statsAvgOrder = avgOrder;
          _statsTotalItems = totalItemsSold;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadTransactionDetails(String transactionId) async {
    setState(() => _detailsLoading = true);

    try {
      final data = await supabase
          .from('sale_items')
          .select('quantity, unit_price, line_total, products!inner(name)')
          .eq('transaction_id', transactionId);

      final items = data.map<TransactionLineItem>((row) {
        final product = row['products'] as Map<String, dynamic>?;
        return TransactionLineItem(
          productName: product?['name'] as String? ?? 'Unknown',
          quantity: (row['quantity'] as num?)?.toInt() ?? 0,
          unitPrice: (row['unit_price'] as num?)?.toDouble() ?? 0,
          lineTotal: (row['line_total'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _detailsCache[transactionId] = TransactionDetail(
            transactionId: transactionId,
            items: items,
          );
          _detailsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _detailsLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_filteredSales.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    try {
      final buf = StringBuffer();
      buf.writeln(
          'Date,Transaction #,Invoice #,Payment Method,Customer,Total');
      for (final s in _filteredSales) {
        final date =
            DateTime.tryParse(s['created_at'] ?? '') ?? DateTime.now();
        final cust = s['customers'] as Map<String, dynamic>?;
        final total = (s['grand_total'] as num?)?.toDouble() ?? 0;
        buf.writeln(
          '${DateFormat('yyyy-MM-dd HH:mm:ss').format(date)},'
          '${s['transaction_number'] ?? ''},'
          '${s['invoice_number'] ?? ''},'
          '${s['payment_method'] ?? ''},'
          '${cust?['name'] ?? 'Walk-in'},'
          '$total',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/spicedesk_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );
      await file.writeAsString(buf.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showInvoiceDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (_) => _InvoiceDialog(
        transaction: transaction,
        detail: _detailsCache[transaction['id'] as String],
        currency: currency,
      ),
    );
  }

  void _toggleExpand(String transactionId) {
    setState(() {
      if (_expandedTransactionId == transactionId) {
        _expandedTransactionId = null;
      } else {
        _expandedTransactionId = transactionId;
        if (!_detailsCache.containsKey(transactionId)) {
          _loadTransactionDetails(transactionId);
        }
      }
    });
  }

  double get _totalRevenue => _filteredSales.fold(
        0,
        (s, t) => s + ((t['grand_total'] as num?)?.toDouble() ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Row(children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: SpiceColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('Sales transactions and analytics',
                      style: TextStyle(
                          fontSize: 14,
                          color: SpiceColors.textSecondary)),
                ],
              ),
            ),
            Material(
              color: SpiceColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _exportCsv,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: SpiceColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download,
                          size: 14, color: SpiceColors.accent),
                      SizedBox(width: 6),
                      Text('CSV',
                          style: TextStyle(
                              fontSize: 13,
                              color: SpiceColors.accent,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 28),

          if (_statsLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))
          else
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: 'Total Sales',
                      value: currency.format(_statsTotalSales),
                      accent: SpiceColors.accent,
                      icon: Icons.trending_up)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Most Sold',
                      value: _statsMostBought,
                      accent: const Color(0xFF8B5CF6),
                      icon: Icons.star,
                      maxLines: 2)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Avg Order',
                      value: currency.format(_statsAvgOrder),
                      accent: SpiceColors.primary,
                      icon: Icons.show_chart)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Items Sold',
                      value: '$_statsTotalItems',
                      accent: const Color(0xFFD29922),
                      icon: Icons.inventory_2)),
            ]),

          const SizedBox(height: 36),

          Row(children: [
            const Text('Transaction History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary)),
            const Spacer(),
            _dateButton(
                'From: ${DateFormat('dd/MM/yy').format(_startDate)}', () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now());
              if (d != null) {
                _startDate = d;
                _loadData();
              }
            }),
            const SizedBox(width: 8),
            _dateButton(
                'To: ${DateFormat('dd/MM/yy').format(_endDate)}', () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now());
              if (d != null) {
                _endDate = d;
                _loadData();
              }
            }),
          ]),

          const SizedBox(height: 8),

          Text(
            '${_filteredSales.length} transactions | Total: ${currency.format(_totalRevenue)}',
            style: const TextStyle(
                fontSize: 13, color: SpiceColors.textSecondary),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()))
          else if (_filteredSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                  color: SpiceColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpiceColors.border)),
              child: const Center(
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: SpiceColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No transactions in this period',
                      style: TextStyle(color: SpiceColors.textSecondary)),
                  SizedBox(height: 4),
                  Text(
                      'Select a different date range or create a sale',
                      style: TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textSecondary)),
                ]),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: SpiceColors.surfaceAlt,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12))),
                  child: const Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text('Date',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SpiceColors.textSecondary))),
                    Expanded(
                        flex: 2,
                        child: Text('Txn / Inv #',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SpiceColors.textSecondary))),
                    Expanded(
                        flex: 1,
                        child: Text('Type',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SpiceColors.textSecondary))),
                    SizedBox(width: 20),
                    Expanded(
                        flex: 2,
                        child: Text('Customer',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SpiceColors.textSecondary))),
                    Expanded(
                        flex: 2,
                        child: Text('Total',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SpiceColors.textSecondary),
                            textAlign: TextAlign.right)),
                    SizedBox(width: 24),
                  ]),
                ),
                ..._filteredSales.asMap().entries.map(
                    (e) => _buildTransactionRow(e.key, e.value)),
                const SizedBox(height: 8),
              ]),
            ),

          const SizedBox(height: 48),
          const Center(
              child: Text('Made by Shahid Singh',
                  style: TextStyle(
                      fontSize: 11, color: SpiceColors.textSecondary))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(int index, Map<String, dynamic> s) {
    final txnId = s['id'] as String;
    final cust = s['customers'] as Map<String, dynamic>?;
    final date = DateTime.tryParse(s['created_at'] ?? '') ?? DateTime.now();
    final total = (s['grand_total'] as num?)?.toDouble() ?? 0;
    final invoiceNum = s['invoice_number'] as String?;
    final isEven = index % 2 == 0;
    final isExpanded = _expandedTransactionId == txnId;
    final detail = _detailsCache[txnId];

    return Column(children: [
      InkWell(
        onTap: () => _toggleExpand(txnId),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isEven
                ? SpiceColors.surfaceAlt.withAlpha(60)
                : Colors.transparent,
            border:
                const Border(top: BorderSide(color: SpiceColors.border)),
          ),
          child: Row(children: [
            Expanded(
                flex: 3,
                child: Row(children: [
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: SpiceColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                      DateFormat('dd/MM/yy HH:mm').format(date),
                      style: const TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textSecondary)),
                ])),
            Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['transaction_number'] ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: SpiceColors.textPrimary)),
                    if (invoiceNum != null && invoiceNum.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showInvoiceDialog(s),
                        child: Text(invoiceNum,
                            style: const TextStyle(
                                fontSize: 10,
                                color: SpiceColors.primary,
                                decoration: TextDecoration.underline)),
                      ),
                  ],
                )),
            Expanded(
                flex: 1,
                child: Text(
                  (s['payment_method'] ?? '')
                      .toString()
                      .substring(0, 4),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: s['payment_method'] == 'cash'
                          ? SpiceColors.accent
                          : SpiceColors.primary),
                )),
            const SizedBox(width: 20),
            Expanded(
                flex: 2,
                child: Text(cust?['name'] ?? 'Walk-in',
                    style: const TextStyle(
                        fontSize: 12,
                        color: SpiceColors.textSecondary))),
            Expanded(
                flex: 2,
                child: Text(currency.format(total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.accent))),
          ]),
        ),
      ),
      if (isExpanded) _buildExpandedSection(s, detail),
    ]);
  }

  Widget _buildExpandedSection(
      Map<String, dynamic> s, TransactionDetail? detail) {
    final cust = s['customers'] as Map<String, dynamic>?;
    final total = (s['grand_total'] as num?)?.toDouble() ?? 0;
    final invoiceNum = s['invoice_number'] as String?;

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 8, 16, 16),
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt.withAlpha(30),
        border:
            const Border(top: BorderSide(color: SpiceColors.border)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (cust != null && cust['name'] != null)
                _infoChip('Customer', cust['name'] as String),
              if (cust != null && cust['name'] != null)
                const SizedBox(width: 16),
              _infoChip(
                  'Payment', (s['payment_method'] ?? '').toString()),
              const SizedBox(width: 16),
              _infoChip('Total', currency.format(total)),
              const Spacer(),
              if (invoiceNum != null && invoiceNum.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showInvoiceDialog(s),
                  icon: const Icon(Icons.description_outlined,
                      size: 14),
                  label: Text('Invoice $invoiceNum',
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: SpiceColors.primary,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8)),
                ),
            ]),
            const SizedBox(height: 12),
            if (_detailsLoading && detail == null)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))))
            else if (detail == null)
              const Text('No items found',
                  style: TextStyle(
                      fontSize: 12,
                      color: SpiceColors.textSecondary))
            else if (detail.items.isEmpty)
              const Text('No items in transaction',
                  style: TextStyle(
                      fontSize: 12,
                      color: SpiceColors.textSecondary))
            else
              _buildLineItemsTable(detail.items),
          ]),
    );
  }

  Widget _buildLineItemsTable(List<TransactionLineItem> items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SpiceColors.border),
      ),
      child: Column(children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: SpiceColors.surfaceAlt,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(children: [
            Expanded(
                flex: 4,
                child: Text('Product',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.textSecondary))),
            Expanded(
                flex: 1,
                child: Text('Qty',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.textSecondary),
                    textAlign: TextAlign.center)),
            Expanded(
                flex: 2,
                child: Text('Unit Price',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.textSecondary),
                    textAlign: TextAlign.right)),
            Expanded(
                flex: 2,
                child: Text('Line Total',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.textSecondary),
                    textAlign: TextAlign.right)),
          ]),
        ),
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final isEven = e.key % 2 == 0;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isEven
                  ? SpiceColors.surfaceAlt.withAlpha(40)
                  : Colors.transparent,
              border: const Border(
                  top: BorderSide(color: SpiceColors.border)),
            ),
            child: Row(children: [
              Expanded(
                  flex: 4,
                  child: Text(item.productName,
                      style: const TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textPrimary))),
              Expanded(
                  flex: 1,
                  child: Text('${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text(
                      currency.format(item.unitPrice),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text(
                      currency.format(item.lineTotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: SpiceColors.textPrimary))),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _infoChip(String label, String value) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
            text: '$label: ',
            style: const TextStyle(
                fontSize: 11, color: SpiceColors.textSecondary)),
        TextSpan(
            text: value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: SpiceColors.textPrimary)),
      ]),
    );
  }

  Widget _dateButton(String label, VoidCallback onTap) {
    return Material(
      color: SpiceColors.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: SpiceColors.border),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today,
                size: 14, color: SpiceColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: SpiceColors.primary,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final int maxLines;
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpiceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SpiceColors.textPrimary),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: SpiceColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InvoiceDialog extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final TransactionDetail? detail;
  final NumberFormat currency;

  const _InvoiceDialog({
    required this.transaction,
    required this.detail,
    required this.currency,
  });

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  bool _updating = false;
  String? _statusMessage;
  TransactionDetail? _detail;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.detail;
    if (_detail == null) _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final data = await supabase
          .from('sale_items')
          .select(
              'quantity, unit_price, line_total, products!inner(name)')
          .eq('transaction_id', widget.transaction['id']);

      final items = data.map<TransactionLineItem>((row) {
        final product = row['products'] as Map<String, dynamic>?;
        return TransactionLineItem(
          productName: product?['name'] as String? ?? 'Unknown',
          quantity: (row['quantity'] as num?)?.toInt() ?? 0,
          unitPrice: (row['unit_price'] as num?)?.toDouble() ?? 0,
          lineTotal: (row['line_total'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _detail = TransactionDetail(
            transactionId: widget.transaction['id'] as String,
            items: items,
          );
          _loadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      await supabase
          .from('sales_transactions')
          .update({'status': status})
          .eq('id', widget.transaction['id']);
      if (mounted) {
        setState(() {
          _statusMessage = 'Marked as $status';
          _updating = false;
        });
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to update status';
          _updating = false;
        });
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (mounted) setState(() => _statusMessage = null);
  }

  String get _invoiceNumber =>
      widget.transaction['invoice_number'] as String? ?? '—';
  String get _paymentMethod =>
      (widget.transaction['payment_method'] ?? '').toString();
  double get _total =>
      (widget.transaction['grand_total'] as num?)?.toDouble() ?? 0;

  Map<String, dynamic>? get _customer =>
      widget.transaction['customers'] as Map<String, dynamic>?;
  String get _customerName => _customer?['name'] as String? ?? 'Walk-in';

  DateTime get _date =>
      DateTime.tryParse(widget.transaction['created_at'] ?? '') ??
      DateTime.now();

  double get _subtotal => _detail?.subtotal ?? _total;
  double get _tax => _total - _subtotal > 0 ? _total - _subtotal : 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SpiceColors.surfaceAlt,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SpiceColors.border)),
      title: Row(children: [
        const Icon(Icons.receipt_long,
            color: SpiceColors.primary, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary)),
            Text(_invoiceNumber,
                style: const TextStyle(
                    fontSize: 13,
                    color: SpiceColors.textSecondary)),
          ],
        ),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close,
                size: 20, color: SpiceColors.textSecondary)),
      ]),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      content: SizedBox(
        width: 520,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _infoChip(
                    'Date', DateFormat('dd/MM/yyyy HH:mm').format(_date)),
                const SizedBox(width: 24),
                _infoChip('Customer', _customerName),
                const SizedBox(width: 24),
                _infoChip('Payment', _paymentMethod),
              ]),
              const SizedBox(height: 16),
              if (_loadingDetail)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()))
              else if (_detail != null &&
                  _detail!.items.isNotEmpty) ...[
                const Text('Items',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: SpiceColors.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: SpiceColors.surface,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                      child: const Row(children: [
                        Expanded(
                            flex: 4,
                            child: Text('Product',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: SpiceColors
                                        .textSecondary))),
                        Expanded(
                            flex: 1,
                            child: Text('Qty',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: SpiceColors
                                        .textSecondary),
                                textAlign:
                                    TextAlign.center)),
                        Expanded(
                            flex: 2,
                            child: Text('Price',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: SpiceColors
                                        .textSecondary),
                                textAlign:
                                    TextAlign.right)),
                        Expanded(
                            flex: 2,
                            child: Text('Total',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: SpiceColors
                                        .textSecondary),
                                textAlign:
                                    TextAlign.right)),
                      ]),
                    ),
                    ..._detail!.items.asMap().entries.map((e) {
                      final item = e.value;
                      final isEven = e.key % 2 == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isEven
                              ? SpiceColors.surfaceAlt
                                  .withAlpha(60)
                              : Colors.transparent,
                          border: const Border(
                              top: BorderSide(
                                  color: SpiceColors.border)),
                        ),
                        child: Row(children: [
                          Expanded(
                              flex: 4,
                              child: Text(item.productName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: SpiceColors
                                          .textPrimary))),
                          Expanded(
                              flex: 1,
                              child: Text('${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: SpiceColors
                                          .textSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  widget.currency.format(
                                      item.unitPrice),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: SpiceColors
                                          .textSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  widget.currency.format(
                                      item.lineTotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w500,
                                      color: SpiceColors
                                          .textPrimary))),
                        ]),
                      );
                    }),
                  ]),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _totalLine('Subtotal', _subtotal),
                        if (_tax > 0) _totalLine('Tax', _tax),
                        const SizedBox(height: 4),
                        Container(
                            height: 1,
                            width: 120,
                            color: SpiceColors.border),
                        const SizedBox(height: 4),
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: SpiceColors
                                          .textPrimary)),
                              const SizedBox(width: 24),
                              Text(
                                  widget.currency
                                      .format(_total),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          SpiceColors.accent)),
                            ]),
                      ]),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No items found',
                      style: const TextStyle(
                          color: SpiceColors.textSecondary)),
                ),
              const SizedBox(height: 20),
              Row(children: [
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(_statusMessage!,
                        style: TextStyle(
                            fontSize: 12,
                            color: _statusMessage!
                                    .contains('Failed')
                                ? SpiceColors.danger
                                : SpiceColors.accent)),
                  ),
                const Spacer(),
                if (_updating)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                else ...[
                  _actionButton('Mark as Sent',
                      SpiceColors.warning, () => _updateStatus('sent')),
                  const SizedBox(width: 8),
                  _actionButton('Mark as Paid',
                      SpiceColors.accent, () => _updateStatus('paid')),
                ],
              ]),
            ]),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
            text: '$label: ',
            style: const TextStyle(
                fontSize: 12, color: SpiceColors.textSecondary)),
        TextSpan(
            text: value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: SpiceColors.textPrimary)),
      ]),
    );
  }

  Widget _totalLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: SpiceColors.textSecondary)),
        const SizedBox(width: 24),
        Text(widget.currency.format(amount),
            style: const TextStyle(
                fontSize: 12, color: SpiceColors.textPrimary)),
      ]),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: color.withAlpha(80)),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ),
      ),
    );
  }
}

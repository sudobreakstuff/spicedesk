import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../sales/data/sales_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../workspace/domain/workspace_state.dart';

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
        .select('id, transaction_number, grand_total, payment_method, created_at, customers(name)')
        .eq('workspace_id', wsId)
        .gte('created_at', start)
        .lte('created_at', end)
        .order('created_at', ascending: false)
        .limit(200);

    if (mounted) {
      setState(() {
        _filteredSales = data;
        _loading = false;
      });
    }
  }

  double get _totalRevenue => _filteredSales.fold(0, (s, t) => s + ((t['grand_total'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final productsAsync = ref.watch(productsProvider);
    final allSales = salesAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];

    final totalAllRevenue = allSales.fold<double>(0, (s, t) => s + t.total);

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Sales transactions and analytics', style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
          const SizedBox(height: 28),

          // Summary cards
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Total Revenue', value: currency.format(totalAllRevenue), accent: SpiceColors.accent, icon: Icons.trending_up)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Transactions', value: '${allSales.length}', accent: SpiceColors.primary, icon: Icons.receipt_long)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Products', value: '${products.length}', accent: const Color(0xFF8B5CF6), icon: Icons.inventory_2)),
            ],
          ),

          const SizedBox(height: 36),

          // Date range filter
          Row(
            children: [
              const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              const Spacer(),
              _dateButton('From: ${DateFormat('dd/MM/yy').format(_startDate)}', () async {
                final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                if (d != null) { _startDate = d; _loadData(); }
              }),
              const SizedBox(width: 8),
              _dateButton('To: ${DateFormat('dd/MM/yy').format(_endDate)}', () async {
                final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                if (d != null) { _endDate = d; _loadData(); }
              }),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '${_filteredSales.length} transactions | Total: ${currency.format(_totalRevenue)}',
            style: const TextStyle(fontSize: 13, color: SpiceColors.textSecondary),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else if (_filteredSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
              child: const Center(
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: SpiceColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No transactions in this period', style: TextStyle(color: SpiceColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('Select a different date range or create a sale', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                ]),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                    child: const Row(children: [
                      Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      Expanded(flex: 2, child: Text('Txn #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      Expanded(flex: 1, child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      SizedBox(width: 40),
                      Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      Expanded(flex: 2, child: Text('Total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary), textAlign: TextAlign.right)),
                    ]),
                  ),
                  ..._filteredSales.asMap().entries.map((e) {
                    final s = e.value;
                    final cust = s['customers'] as Map<String, dynamic>?;
                    final date = DateTime.tryParse(s['created_at'] ?? '') ?? DateTime.now();
                    final total = (s['grand_total'] as num?)?.toDouble() ?? 0;
                    final isEven = e.key % 2 == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isEven ? SpiceColors.surfaceAlt.withAlpha(60) : Colors.transparent,
                        border: const Border(top: BorderSide(color: SpiceColors.border)),
                      ),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(DateFormat('dd/MM/yy HH:mm').format(date), style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                        Expanded(flex: 2, child: Text(s['transaction_number'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary))),
                        Expanded(flex: 1, child: Text((s['payment_method'] ?? '').toString().substring(0, 4), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: s['payment_method'] == 'cash' ? SpiceColors.accent : SpiceColors.primary))),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: Text(cust?['name'] ?? 'Walk-in', style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                        Expanded(flex: 2, child: Text(currency.format(total), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent))),
                      ]),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          const SizedBox(height: 48),
          const Center(child: Text('Made by Shahid Singh', style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary))),
          const SizedBox(height: 32),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: SpiceColors.border), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today, size: 14, color: SpiceColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: SpiceColors.primary, fontWeight: FontWeight.w500)),
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
  const _StatCard({required this.label, required this.value, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accent, size: 18)),
          const Spacer(),
          Icon(Icons.trending_up, size: 14, color: SpiceColors.accent.withAlpha(100)),
        ]),
        const SizedBox(height: 16),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
      ]),
    );
  }
}

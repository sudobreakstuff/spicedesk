import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workspace/domain/workspace_state.dart';

class PendingOrdersScreen extends ConsumerStatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  ConsumerState<PendingOrdersScreen> createState() =>
      _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends ConsumerState<PendingOrdersScreen> {
  List<Map<String, dynamic>> _quotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await supabase
          .from('quotes')
          .select('*, customers(name)')
          .eq('workspace_id', wsId)
          .or('status.eq.draft,status.eq.sent')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _quotes = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showQuoteActions(Map<String, dynamic> quote) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpiceColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: SpiceColors.border),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: SpiceColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(quote['quote_number'] ?? 'Quote', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              ),
              const SizedBox(height: 16),
              if (quote['status'] == 'accepted')
                ListTile(
                  leading: const Icon(Icons.shopping_cart, color: SpiceColors.accent),
                  title: const Text('Convert to Sale'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () { Navigator.pop(ctx); _convertQuoteToSale(quote); },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: SpiceColors.primary),
                title: const Text('Edit Status'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () { Navigator.pop(ctx); _editStatusDialog(quote); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: SpiceColors.danger),
                title: const Text('Delete'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () { Navigator.pop(ctx); _deleteQuote(quote); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _editStatusDialog(Map<String, dynamic> quote) {
    String selectedStatus = quote['status'] ?? 'draft';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: SpiceColors.border)),
        title: const Text('Change Status'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ...['draft', 'sent', 'accepted', 'rejected'].map((status) => RadioListTile<String>(
            title: Text(status[0].toUpperCase() + status.substring(1)),
            value: status,
            groupValue: selectedStatus,
            activeColor: status == 'accepted' ? SpiceColors.accent : status == 'rejected' ? SpiceColors.danger : SpiceColors.primary,
            onChanged: (v) {
              Navigator.pop(ctx);
              selectedStatus = v!;
              _updateQuoteStatus(quote, selectedStatus);
            },
          )),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  Future<void> _updateQuoteStatus(Map<String, dynamic> quote, String status) async {
    try {
      await supabase.from('quotes').update({'status': status}).eq('id', quote['id']);
      _loadQuotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status'), backgroundColor: SpiceColors.accent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent':
        return SpiceColors.primary;
      case 'accepted':
        return SpiceColors.accent;
      case 'rejected':
        return SpiceColors.danger;
      default:
        return SpiceColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: RefreshIndicator(
        onRefresh: _loadQuotes,
        color: SpiceColors.primary,
        backgroundColor: SpiceColors.surfaceAlt,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Orders',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: SpiceColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Draft and sent quotes',
                          style: TextStyle(
                              fontSize: 14,
                              color: SpiceColors.textSecondary)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/pos'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Quote'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator()))
            else if (_quotes.isEmpty)
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: SpiceColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpiceColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 48, color: SpiceColors.textSecondary),
                      SizedBox(height: 12),
                      Text('No pending orders',
                          style: TextStyle(
                              color: SpiceColors.textSecondary)),
                      SizedBox(height: 4),
                      Text('Create a quote from Point of Sale',
                          style: TextStyle(
                              fontSize: 12,
                              color: SpiceColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ..._quotes.map((quote) {
                final cust = quote['customers'] as Map<String, dynamic>?;
                final status = quote['status'] as String? ?? 'draft';
                final total =
                    (quote['total'] as num?)?.toDouble() ?? 0;
                final date =
                    DateTime.tryParse(quote['created_at'] ?? '') ??
                        DateTime.now();
                final statusColor = _statusColor(status);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onLongPress: () => _showQuoteActions(quote),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: SpiceColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: SpiceColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(30),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: statusColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote['quote_number'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          SpiceColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cust?['name'] ?? 'Walk-in',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: SpiceColors
                                          .textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'R ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: SpiceColors.accent),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            child: Text(
                              DateFormat('dd/MM/yy').format(date),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      SpiceColors.textSecondary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuote(Map<String, dynamic> quote) async {
    try {
      await supabase.from('quote_items').delete().eq('quote_id', quote['id']);
      await supabase.from('quotes').delete().eq('id', quote['id']);
      _loadQuotes();
    } catch (_) {}
  }

  Future<void> _convertQuoteToSale(Map<String, dynamic> quote) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return;

    try {
      // Get quote items
      final items = await supabase
          .from('quote_items')
          .select('product_id, product_name, quantity, unit_price')
          .eq('quote_id', quote['id'])
          .eq('workspace_id', wsId);

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote has no items')),
          );
        }
        return;
      }

      final saleItems = items.map((item) => {
        'product_id': item['product_id'] ?? '',
        'product_name': item['product_name'] ?? '',
        'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
        'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0,
      }).toList();

      await supabase.rpc('create_sale', params: {
        'p_workspace_id': wsId,
        'p_customer_id': quote['customer_id'],
        'p_payment_method': 'credit',
        'p_items': saleItems,
      });

      // Mark quote as accepted
      await supabase
          .from('quotes')
          .update({'status': 'accepted'})
          .eq('id', quote['id']);

      _loadQuotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote converted to sale successfully'),
            backgroundColor: SpiceColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

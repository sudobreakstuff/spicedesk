import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../customers/data/customers_provider.dart';
import '../../../workspace/domain/workspace_state.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final _expandedIds = <String>{};
  final _customerDetails = <String, _CustomerDetail>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleExpand(Customer customer) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return;

    if (_expandedIds.contains(customer.id)) {
      setState(() => _expandedIds.remove(customer.id));
      return;
    }

    setState(() {
      _expandedIds.add(customer.id);
      _customerDetails[customer.id] = const _CustomerDetail(isLoading: true);
    });

    try {
      final txnData = await supabase
          .from('sales_transactions')
          .select(
              'id, transaction_number, grand_total, payment_method, created_at')
          .eq('customer_id', customer.id)
          .eq('workspace_id', wsId)
          .order('created_at', ascending: false)
          .limit(10);

      double totalSpent = 0;
      DateTime? lastVisit;

      for (final txn in txnData) {
        totalSpent += (txn['grand_total'] as num?)?.toDouble() ?? 0;
        if (lastVisit == null) {
          final created = txn['created_at'];
          if (created != null) {
            lastVisit = DateTime.tryParse(created);
          }
        }
      }

      final recentPurchases = txnData
          .map<Map<String, dynamic>>((t) => {
                'id': t['id'],
                'transaction_number': t['transaction_number'] ?? '',
                'grand_total': (t['grand_total'] as num?)?.toDouble() ?? 0,
                'payment_method': t['payment_method'] ?? '',
                'created_at': t['created_at'] ?? '',
              })
          .toList();

      setState(() {
        _customerDetails[customer.id] = _CustomerDetail(
          totalSpent: totalSpent,
          lastVisit: lastVisit,
          recentPurchases: recentPurchases,
        );
      });
    } catch (e) {
      setState(() {
        _customerDetails[customer.id] =
            const _CustomerDetail(isLoading: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final customers = customersAsync.valueOrNull ?? [];

    final filtered = customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          (c.email?.toLowerCase().contains(query) ?? false) ||
          (c.phone?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customers',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: SpiceColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your customer database',
                        style: TextStyle(
                          fontSize: 14,
                          color: SpiceColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Customer'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: customersAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 48,
                              color: SpiceColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              customers.isEmpty
                                  ? 'No customers yet'
                                  : 'No matching customers',
                              style: const TextStyle(
                                color: SpiceColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Customers will appear here after sales are recorded',
                              style: TextStyle(
                                fontSize: 12,
                                color: SpiceColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          final isExpanded =
                              _expandedIds.contains(customer.id);
                          final detail =
                              _customerDetails[customer.id];
                          final subtitle =
                              customer.email ?? customer.phone ?? '';
                          final initials = customer.name.isNotEmpty
                              ? customer.name
                                  .split(' ')
                                  .map((e) => e.isNotEmpty
                                      ? e[0].toUpperCase()
                                      : '')
                                  .take(2)
                                  .join()
                              : '?';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: SpiceColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SpiceColors.border),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleExpand(customer),
                                  onLongPress: () =>
                                      _showCustomerActions(customer),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: SpiceColors.primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: SpiceColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: SpiceColors
                                                      .textPrimary,
                                                ),
                                              ),
                                              if (subtitle.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  subtitle,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: SpiceColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: SpiceColors.warning
                                                .withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.military_tech_rounded,
                                                size: 14,
                                                color: SpiceColors.warning,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Loyalty: ${customer.loyaltyPoints}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: SpiceColors.warning,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: SpiceColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  _buildExpandedPanel(customer, detail),
                              ],
                            ),
                          ).animate().fadeIn(delay: (index * 40).ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPanel(Customer customer, _CustomerDetail? detail) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: SpiceColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (detail == null || detail.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _detailChip(
                    Icons.attach_money,
                    'Total Spent: R ${detail.totalSpent.toStringAsFixed(2)}',
                    SpiceColors.accent),
                const SizedBox(width: 12),
                _detailChip(
                    Icons.access_time,
                    detail.lastVisit != null
                        ? 'Last Visit: ${_formatDate(detail.lastVisit!)}'
                        : 'No visits yet',
                    SpiceColors.primary),
              ],
            ),
            const SizedBox(height: 4),
            if (customer.email != null)
              _infoRow(Icons.email_outlined, customer.email!),
            if (customer.phone != null)
              _infoRow(Icons.phone_outlined, customer.phone!),
            if (customer.notes != null && customer.notes!.isNotEmpty)
              _infoRow(Icons.notes_rounded, customer.notes!),
            if (detail.recentPurchases.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Recent Purchases',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SpiceColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...detail.recentPurchases.map((p) => _purchaseRow(p)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: SpiceColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: SpiceColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _purchaseRow(Map<String, dynamic> purchase) {
    final date = purchase['created_at'] as String?;
    final parsedDate =
        date != null && date.isNotEmpty ? DateTime.tryParse(date) : null;
    final displayDate = parsedDate != null
        ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
        : '---';
    final total = (purchase['grand_total'] as num?)?.toDouble() ?? 0;
    final txnNum = purchase['transaction_number'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: SpiceColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.receipt,
                size: 14, color: SpiceColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              txnNum,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: SpiceColors.textPrimary,
              ),
            ),
          ),
          Text(
            displayDate,
            style: const TextStyle(
              fontSize: 11,
              color: SpiceColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'R ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SpiceColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCustomerActions(Customer customer) {
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SpiceColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: SpiceColors.primary),
                title: const Text('Edit Customer'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditCustomerDialog(customer);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: SpiceColors.danger),
                title: const Text('Delete Customer'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteCustomerDialog(customer);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email ?? '');
    final phoneCtrl = TextEditingController(text: customer.phone ?? '');
    final notesCtrl = TextEditingController(text: customer.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              final wsId = ref.read(workspaceStateProvider).selectedId;
              if (wsId == null) return;

              await supabase.from('customers').update({
                'name': name,
                'email':
                    emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                'phone':
                    phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                'notes':
                    notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              }).eq('id', customer.id);

              ref.invalidate(customersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? This cannot be undone.',
          style: const TextStyle(color: SpiceColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('customers').delete().eq('id', customer.id);
              ref.invalidate(customersProvider);
              setState(() {
                _expandedIds.remove(customer.id);
                _customerDetails.remove(customer.id);
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SpiceColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              final wsId = ref.read(workspaceStateProvider).selectedId;
              if (wsId == null) return;

              await supabase.from('customers').insert({
                'workspace_id': wsId,
                'name': name,
                'email':
                    emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                'phone':
                    phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                'notes':
                    notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              });

              ref.invalidate(customersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CustomerDetail {
  final double totalSpent;
  final DateTime? lastVisit;
  final List<Map<String, dynamic>> recentPurchases;
  final bool isLoading;

  const _CustomerDetail({
    this.totalSpent = 0,
    this.lastVisit,
    this.recentPurchases = const [],
    this.isLoading = false,
  });
}

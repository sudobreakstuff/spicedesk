import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final allSalesAsync = ref.watch(allCustomerSalesProvider);
    final customers = customersAsync.valueOrNull ?? [];
    final allSales = allSalesAsync.valueOrNull ?? {};

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                            Text(
                              customers.isEmpty
                                  ? 'Add your first customer to get started.'
                                  : 'Try a different search query.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: SpiceColors.textSecondary,
                              ),
                            ),
                            if (customers.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomerDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Customer'),
                              ),
                            ],
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
                          final salesData = allSales[customer.id];
                          final initials = customer.name.isNotEmpty
                              ? customer.name
                                  .split(' ')
                                  .where((e) => e.isNotEmpty)
                                  .map((e) => e[0].toUpperCase())
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
                                  onTap: () => _toggleExpand(customer.id),
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
                                                  color:
                                                      SpiceColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              if (customer.email != null ||
                                                  customer.phone != null)
                                                Text(
                                                  customer.email ??
                                                      customer.phone ??
                                                      '',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: SpiceColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (customer.loyaltyPoints > 0)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
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
                                                  '${customer.loyaltyPoints}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: SpiceColors.warning,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (salesData != null) ...[
                                          Text(
                                            'R ${NumberFormat.compact().format(salesData.totalSpent)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: SpiceColors.accent,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${salesData.purchaseCount} purchases',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  SpiceColors.textSecondary,
                                            ),
                                          ),
                                        ] else if (allSalesAsync.isLoading)
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
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
                                  _ExpandedPanel(
                                    customer: customer,
                                    onEdit: () =>
                                        _showEditCustomerDialog(customer),
                                    onDelete: () =>
                                        _showDeleteCustomerDialog(customer),
                                  ),
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
                leading: const Icon(Icons.delete_outline,
                    color: SpiceColors.danger),
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
    final addressCtrl = TextEditingController(text: customer.address ?? '');
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
        content: SingleChildScrollView(
          child: Column(
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
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
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
              try {
                final wsId = ref.read(workspaceStateProvider).selectedId;
                if (wsId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please select or create a workspace first'),
                      backgroundColor: SpiceColors.danger,
                    ),
                  );
                  return;
                }

                await supabase.from('customers').update({
                  'name': name,
                  'email': emailCtrl.text.trim().isEmpty
                      ? null
                      : emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim().isEmpty
                      ? null
                      : addressCtrl.text.trim(),
                  'notes': notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                }).eq('id', customer.id);

                ref.invalidate(customersProvider);
                ref.invalidate(allCustomerSalesProvider);
                ref.invalidate(customerSalesProvider(customer.id));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error updating customer: $e'),
                      backgroundColor: SpiceColors.danger,
                    ),
                  );
                }
              }
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
              try {
                await supabase
                    .from('customers')
                    .delete()
                    .eq('id', customer.id);
                ref.invalidate(customersProvider);
                ref.invalidate(allCustomerSalesProvider);
                ref.invalidate(customerSalesProvider(customer.id));
                setState(() {
                  _expandedIds.remove(customer.id);
                });
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting customer: $e'),
                      backgroundColor: SpiceColors.danger,
                    ),
                  );
                }
              }
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
    final addressCtrl = TextEditingController();
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
        content: SingleChildScrollView(
          child: Column(
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
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
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
              try {
                final wsId = ref.read(workspaceStateProvider).selectedId;
                if (wsId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please select or create a workspace first'),
                      backgroundColor: SpiceColors.danger,
                    ),
                  );
                  return;
                }

                await supabase.from('customers').insert({
                  'workspace_id': wsId,
                  'name': name,
                  'email': emailCtrl.text.trim().isEmpty
                      ? null
                      : emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim().isEmpty
                      ? null
                      : addressCtrl.text.trim(),
                  'notes': notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                });

                ref.invalidate(customersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error adding customer: $e'),
                      backgroundColor: SpiceColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ExpandedPanel extends ConsumerWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpandedPanel({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(customerSalesProvider(customer.id));
    final salesData = salesAsync.valueOrNull;
    final isLoading = salesAsync.isLoading;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: SpiceColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (customer.email != null)
            _InfoRow(Icons.email_outlined, customer.email!),
          if (customer.phone != null)
            _InfoRow(Icons.phone_outlined, customer.phone!),
          if (customer.address != null && customer.address!.isNotEmpty)
            _InfoRow(Icons.location_on_outlined, customer.address!),
          if (customer.notes != null && customer.notes!.isNotEmpty)
            _InfoRow(Icons.notes_rounded, customer.notes!),
          if (customer.email != null ||
              customer.phone != null ||
              customer.address != null)
            const SizedBox(height: 10),
          Row(
            children: [
              _DetailChip(
                icon: Icons.attach_money,
                label: isLoading
                    ? 'Loading...'
                    : 'Spent: R ${(salesData?.totalSpent ?? 0).toStringAsFixed(2)}',
                color: SpiceColors.accent,
              ),
              const SizedBox(width: 12),
              _DetailChip(
                icon: Icons.shopping_cart_outlined,
                label: isLoading
                    ? '...'
                    : '${salesData?.purchaseCount ?? 0} purchases',
                color: SpiceColors.primary,
              ),
              const SizedBox(width: 12),
              _DetailChip(
                icon: Icons.access_time,
                label: isLoading
                    ? '...'
                    : salesData?.lastVisit != null
                        ? 'Last: ${dateFormat.format(salesData!.lastVisit!)}'
                        : 'No visits yet',
                color: SpiceColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
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
          else if (salesData != null &&
              salesData.recentPurchases.isNotEmpty) ...[
            const Text(
              'Purchase History',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SpiceColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...salesData.recentPurchases.map((p) {
              final date = p['created_at'] as String?;
              final parsedDate = date != null && date.isNotEmpty
                  ? DateTime.tryParse(date)
                  : null;
              final displayDate = parsedDate != null
                  ? dateFormat.format(parsedDate)
                  : '---';
              final total =
                  (p['grand_total'] as num?)?.toDouble() ?? 0;
              final txnNum = p['transaction_number'] ?? '';

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
            }),
          ] else if (!isLoading && salesData != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No purchases yet',
                style: TextStyle(
                  fontSize: 12,
                  color: SpiceColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SpiceColors.primary,
                    side: const BorderSide(color: SpiceColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SpiceColors.danger,
                    side: const BorderSide(color: SpiceColors.border),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SpiceColors.textSecondary),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: SpiceColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

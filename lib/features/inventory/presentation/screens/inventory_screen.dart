import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../inventory/data/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final items = inventoryAsync.valueOrNull ?? [];

    final filtered = items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == 'all' ||
          (_filter == 'low' && item.quantityOnHand <= item.reorderPoint) ||
          (_filter == 'out' && item.quantityOnHand == 0);
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                const Text('Inventory',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                const Spacer(),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search inventory...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Stock'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                _filterChip('All', 'all'),
                _filterChip('Low Stock', 'low'),
                _filterChip('Out of Stock', 'out'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: inventoryAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: SpiceColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(items.isEmpty ? 'No inventory tracked' : 'No matching items',
                                style: const TextStyle(color: SpiceColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text('Add products and stock from the POS or settings',
                                style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isLow = item.quantityOnHand <= item.reorderPoint && item.quantityOnHand > 0;
                          final isOut = item.quantityOnHand == 0;
                          final statusColor = isOut ? SpiceColors.danger : isLow ? SpiceColors.warning : SpiceColors.accent;
                          final statusIcon = isOut ? Icons.error_outline : isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: SpiceColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SpiceColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(statusIcon, color: statusColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text('SKU: ${item.sku}',
                                          style: const TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('R ${item.unitPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item.quantityOnHand.toInt()} in stock',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                      ),
                                    ),
                                  ],
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

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: SpiceColors.primary.withAlpha(60),
        checkmarkColor: SpiceColors.primary,
        labelStyle: TextStyle(
          color: selected ? SpiceColors.primary : SpiceColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

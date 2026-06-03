import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_widgets.dart';

import '../../../../core/theme/app_theme.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  final _items = [
    {'name': 'Espresso Beans 1kg', 'sku': 'COF-001', 'stock': 45, 'reorder': 10, 'price': 120.00, 'category': 'Coffee'},
    {'name': 'Latte Cups (12pk)', 'sku': 'CUP-002', 'stock': 8, 'reorder': 12, 'price': 85.00, 'category': 'Supplies'},
    {'name': 'Muffin Mix 5kg', 'sku': 'BAK-001', 'stock': 3, 'reorder': 5, 'price': 65.00, 'category': 'Bakery'},
    {'name': 'Takeaway Lids 100pk', 'sku': 'SUP-001', 'stock': 120, 'reorder': 50, 'price': 45.00, 'category': 'Supplies'},
    {'name': 'Cheesecake Base', 'sku': 'BAK-002', 'stock': 12, 'reorder': 8, 'price': 95.00, 'category': 'Bakery'},
    {'name': 'Milk 2L', 'sku': 'DAI-001', 'stock': 0, 'reorder': 20, 'price': 28.00, 'category': 'Dairy'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((item) {
      final matchesSearch = _searchCtrl.text.isEmpty ||
          (item['name'] as String)
              .toLowerCase()
              .contains(_searchCtrl.text.toLowerCase());
      final matchesFilter = _filter == 'all' ||
          (_filter == 'low' && (item['stock'] as int) <= (item['reorder'] as int)) ||
          (_filter == 'out' && (item['stock'] as int) == 0) ||
          (_filter == item['category']);
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search inventory...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Add product
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _filterChip('All', 'all'),
              _filterChip('Low Stock', 'low'),
              _filterChip('Out of Stock', 'out'),
              _filterChip('Coffee', 'Coffee'),
              _filterChip('Supplies', 'Supplies'),
              _filterChip('Bakery', 'Bakery'),
              _filterChip('Dairy', 'Dairy'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: SpiceColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('No items found',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final stock = item['stock'] as int;
                    final reorder = item['reorder'] as int;
                    final isLow = stock <= reorder;
                    final isOut = stock == 0;

                    return GlassCard(
                      borderRadius: BorderRadius.circular(14),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isOut
                                    ? SpiceColors.danger
                                    : isLow
                                        ? SpiceColors.warning
                                        : SpiceColors.accent)
                                .withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isOut
                                ? Icons.error_outline
                                : isLow
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline,
                            color: isOut
                                ? SpiceColors.danger
                                : isLow
                                    ? SpiceColors.warning
                                    : SpiceColors.accent,
                          ),
                        ),
                        title: Text(item['name'] as String,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text(
                          'SKU: ${item['sku']} • ${item['category']}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R ${(item['price'] as double).toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$stock in stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOut
                                    ? SpiceColors.danger
                                    : isLow
                                        ? SpiceColors.warning
                                        : SpiceColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                ),
        ),
      ],
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

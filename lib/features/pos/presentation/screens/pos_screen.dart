import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_widgets.dart';

import '../../../../core/theme/app_theme.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _cart = [];

  final _products = const [
    {'name': 'Espresso', 'price': 25.00, 'category': 'Drinks'},
    {'name': 'Cappuccino', 'price': 30.00, 'category': 'Drinks'},
    {'name': 'Latte', 'price': 32.00, 'category': 'Drinks'},
    {'name': 'Muffin', 'price': 18.00, 'category': 'Food'},
    {'name': 'Croissant', 'price': 22.00, 'category': 'Food'},
    {'name': 'Cheesecake', 'price': 35.00, 'category': 'Food'},
  ];

  double get _total => _cart.fold(
      0.0, (sum, item) => sum + (item['price'] as double) * (item['qty'] as int));

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existing = _cart.indexWhere((c) => c['name'] == product['name']);
      if (existing >= 0) {
        _cart[existing] = {..._cart[existing], 'qty': (_cart[existing]['qty'] as int) + 1};
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['qty'] as int > 1) {
        _cart[index] = {..._cart[index], 'qty': (_cart[index]['qty'] as int) - 1};
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: R ${_total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...['Cash', 'Card', 'Mobile'].map((method) => ListTile(
                  leading: Icon(method == 'Cash'
                      ? Icons.money
                      : method == 'Card'
                          ? Icons.credit_card
                          : Icons.phone_android),
                  title: Text(method),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _cart.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sale complete! R ${_total.toStringAsFixed(2)}'),
                        backgroundColor: SpiceColors.accent,
                      ),
                    );
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Row(
      children: [
        // Product grid
        Expanded(
          flex: isWide ? 3 : 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return GestureDetector(
                      onTap: () => _addToCart(p),
                      child: GlassCard(
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              p['category'] == 'Drinks'
                                  ? Icons.coffee
                                  : Icons.bakery_dining,
                              size: 32,
                              color: SpiceColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(p['name'] as String,
                                style: Theme.of(context).textTheme.labelLarge,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('R ${(p['price'] as double).toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: SpiceColors.accent,
                                      fontWeight: FontWeight.w600,
                                    )),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).scaleXY(
                        begin: 0.9);
                  },
                ),
              ),
            ],
          ),
        ),

        // Cart sidebar
        Container(
          width: isWide ? 360 : 280,
          decoration: BoxDecoration(
            color: SpiceColors.glassSurface,
            border: Border(
              left: BorderSide(color: SpiceColors.glassBorder),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    const SizedBox(width: 8),
                    Text('Cart', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    if (_cart.isNotEmpty)
                      Text('${_cart.length} items',
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 48, color: SpiceColors.textSecondary),
                            const SizedBox(height: 8),
                            Text('Cart is empty',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return GlassCard(
                            borderRadius: BorderRadius.circular(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge),
                                      Text(
                                          'R ${((item['price'] as double) * (item['qty'] as int)).toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          size: 18),
                                      onPressed: () => _removeFromCart(index),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text('${item['qty']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => _addToCart(item),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          'R ${_total.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: SpiceColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _cart.isEmpty ? null : _checkout,
                        icon: const Icon(Icons.payment),
                        label: const Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

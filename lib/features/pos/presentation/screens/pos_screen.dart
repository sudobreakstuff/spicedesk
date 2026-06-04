import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    {'name': 'Americano', 'price': 22.00, 'category': 'Drinks'},
    {'name': 'Mocha', 'price': 35.00, 'category': 'Drinks'},
    {'name': 'Hot Chocolate', 'price': 28.00, 'category': 'Drinks'},
    {'name': 'Muffin', 'price': 18.00, 'category': 'Food'},
    {'name': 'Croissant', 'price': 22.00, 'category': 'Food'},
    {'name': 'Cheesecake', 'price': 35.00, 'category': 'Food'},
    {'name': 'Bagel', 'price': 16.00, 'category': 'Food'},
    {'name': 'Sandwich', 'price': 42.00, 'category': 'Food'},
    {'name': 'Salad', 'price': 38.00, 'category': 'Food'},
  ];

  double get _total => _cart.fold(
      0.0, (sum, i) => sum + (i['price'] as double) * (i['qty'] as int));

  void _addToCart(Map<String, dynamic> p) {
    setState(() {
      final idx = _cart.indexWhere((c) => c['name'] == p['name']);
      if (idx >= 0) {
        _cart[idx] = {..._cart[idx], 'qty': (_cart[idx]['qty'] as int) + 1};
      } else {
        _cart.add({...p, 'qty': 1});
      }
    });
  }

  void _removeFromCart(int idx) {
    setState(() {
      if (_cart[idx]['qty'] as int > 1) {
        _cart[idx] = {..._cart[idx], 'qty': (_cart[idx]['qty'] as int) - 1};
      } else {
        _cart.removeAt(idx);
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border)),
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: R ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.accent)),
            const SizedBox(height: 16),
            ...['Cash', 'Card', 'Mobile'].map((m) => ListTile(
                  leading: Icon(m == 'Cash'
                      ? Icons.money
                      : m == 'Card'
                          ? Icons.credit_card
                          : Icons.phone_android),
                  title: Text(m),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _cart.clear());
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Sale complete! R ${_total.toStringAsFixed(2)}'),
                      backgroundColor: SpiceColors.accent,
                    ));
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
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
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Row(
        children: [
          // Product grid
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  child: Row(
                    children: [
                      const Text('Point of Sale',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: SpiceColors.textPrimary)),
                      const Spacer(),
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final isDrink = p['category'] == 'Drinks';
                      return GestureDetector(
                        onTap: () => _addToCart(p),
                        child: Container(
                          decoration: BoxDecoration(
                            color: SpiceColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDrink
                                  ? SpiceColors.primary.withAlpha(50)
                                  : SpiceColors.warning.withAlpha(50),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDrink
                                    ? Icons.coffee_rounded
                                    : Icons.bakery_dining_rounded,
                                size: 36,
                                color: isDrink
                                    ? SpiceColors.primary
                                    : SpiceColors.warning,
                              ),
                              const SizedBox(height: 10),
                              Text(p['name'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: SpiceColors.textPrimary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SpiceColors.accent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'R ${(p['price'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: SpiceColors.accent),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (index * 40).ms),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Cart sidebar
          Container(
            width: 340,
            decoration: BoxDecoration(
              color: SpiceColors.surfaceAlt,
              border: Border(
                left: BorderSide(color: SpiceColors.border),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: SpiceColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: SpiceColors.textPrimary, size: 20),
                      const SizedBox(width: 10),
                      const Text('Cart',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: SpiceColors.textPrimary)),
                      const Spacer(),
                      if (_cart.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SpiceColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_cart.length}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SpiceColors.primary)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 40, color: SpiceColors.textSecondary),
                                SizedBox(height: 8),
                                Text('Cart is empty',
                                    style: TextStyle(
                                        color: SpiceColors.textSecondary)),
                              ],
                            ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: SpiceColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: SpiceColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'] as String,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: SpiceColors
                                                      .textPrimary)),
                                          const SizedBox(height: 4),
                                          Text(
                                              'R ${((item['price'] as double) * (item['qty'] as int)).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: SpiceColors.accent)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: SpiceColors.surfaceAlt,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: SpiceColors.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _qtyBtn(Icons.remove, () =>
                                              _removeFromCart(index)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text('${item['qty']}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                          _qtyBtn(Icons.add,
                                              () => _addToCart(item)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SpiceColors.surface,
                    border: Border(
                      top: BorderSide(color: SpiceColors.border),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: SpiceColors.textSecondary)),
                          Text('R ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: SpiceColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SpiceColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Checkout',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 14, color: SpiceColors.textSecondary),
        ),
      ),
    );
  }
}

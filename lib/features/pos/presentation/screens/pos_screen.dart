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
      0.0,
      (sum, item) =>
          sum + (item['price'] as double) * (item['qty'] as int));

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existing = _cart.indexWhere((c) => c['name'] == product['name']);
      if (existing >= 0) {
        _cart[existing] = {
          ..._cart[existing],
          'qty': (_cart[existing]['qty'] as int) + 1
        };
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['qty'] as int > 1) {
        _cart[index] = {
          ..._cart[index],
          'qty': (_cart[index]['qty'] as int) - 1
        };
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    final total = _total;
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SpiceColors.primary, Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'R ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...['Cash', 'Card', 'Mobile'].map((method) => ListTile(
                  leading: Icon(
                    method == 'Cash'
                        ? Icons.money
                        : method == 'Card'
                            ? Icons.credit_card
                            : Icons.phone_android,
                    color: SpiceColors.primary,
                  ),
                  title: Text(method),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 18, color: SpiceColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _cart.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Sale complete! R ${total.toStringAsFixed(2)}'),
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

    final filtered = _products.where((p) {
      final q = _searchCtrl.text.toLowerCase();
      return (p['name'] as String).toLowerCase().contains(q);
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: isWide ? 3 : 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon:
                          Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ).animate().fadeIn(),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: SpiceColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('No products found',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(14),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isDrink = p['category'] == 'Drinks';
                          return GestureDetector(
                            onTap: () => _addToCart(p),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (isDrink
                                            ? const Color(0xFF6366F1)
                                            : SpiceColors.warning)
                                        .withAlpha(18),
                                    (isDrink
                                            ? const Color(0xFF6366F1)
                                            : SpiceColors.warning)
                                        .withAlpha(4),
                                  ],
                                ),
                                border: Border.all(
                                  color: (isDrink
                                          ? const Color(0xFF6366F1)
                                          : SpiceColors.warning)
                                      .withAlpha(40),
                                  width: 0.5,
                                ),
                              ),
                              child: GlassCard(
                                borderRadius: BorderRadius.circular(22),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 14),
                                backgroundColor: Colors.transparent,
                                blur: 0,
                                shadows: const [],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: (isDrink
                                                ? const Color(0xFF6366F1)
                                                : SpiceColors.warning)
                                            .withAlpha(35),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        isDrink
                                            ? Icons.coffee_rounded
                                            : Icons.bakery_dining_rounded,
                                        size: 28,
                                        color: isDrink
                                            ? const Color(0xFFA78BFA)
                                            : SpiceColors.warning,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      p['name'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: SpiceColors.accent.withAlpha(25),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              SpiceColors.accent.withAlpha(50),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        'R ${(p['price'] as double).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: SpiceColors.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate()
                              .fadeIn(delay: (index * 60).ms)
                              .scaleXY(begin: 0.92);
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
            color: SpiceColors.surfaceAlt.withAlpha(120),
            border: Border(
              left: BorderSide(
                color: SpiceColors.primary.withAlpha(25),
                width: 0.5,
              ),
              top: const BorderSide(
                color: Color(0x1AFFFFFF),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Cart header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SpiceColors.primary.withAlpha(25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: SpiceColors.primary.withAlpha(20),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: SpiceColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_cart_rounded,
                          color: SpiceColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Cart',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (_cart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SpiceColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: SpiceColors.primary.withAlpha(60),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${_cart.length}',
                          style: const TextStyle(
                            color: SpiceColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: _cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: SpiceColors.textSecondary
                                    .withAlpha(15),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 36,
                                  color: SpiceColors.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            Text('Your cart is empty',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 15)),
                            const SizedBox(height: 6),
                            Text('Tap a product to add it',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium),
                          ],
                        ).animate().fadeIn(),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          final lineTotal =
                              (item['price'] as double) *
                                  (item['qty'] as int);
                          return GlassCard(
                            borderRadius: BorderRadius.circular(16),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'R ${lineTotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: SpiceColors.accent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: SpiceColors.textSecondary
                                        .withAlpha(15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _QtyButton(
                                        icon: Icons.remove_rounded,
                                        onTap: () =>
                                            _removeFromCart(index),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12),
                                        child: Text(
                                          '${item['qty']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w700),
                                        ),
                                      ),
                                      _QtyButton(
                                        icon: Icons.add_rounded,
                                        onTap: () => _addToCart(item),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.06);
                        },
                      ),
              ),

              // Cart footer
              if (_cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        SpiceColors.primary.withAlpha(15),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: SpiceColors.primary.withAlpha(25),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium),
                          Text(
                            'R ${_total.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: SpiceColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              _cart.isEmpty ? null : _checkout,
                          icon: const Icon(Icons.payment_rounded,
                              size: 20),
                          label: const Text('Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SpiceColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            disabledBackgroundColor:
                                SpiceColors.textSecondary
                                    .withAlpha(30),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.1),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SpiceColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: SpiceColors.primary),
        ),
      ),
    );
  }
}

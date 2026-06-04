import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/products_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../pos/data/pos_service.dart';
import '../../../workspace/domain/workspace_state.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  final List<_CartItem> _cart = [];
  String _searchQuery = '';

  double get _total => _cart.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));

  void _addToCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.product.id == product.id);
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + 1);
      } else {
        _cart.add(_CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(int idx) {
    setState(() {
      if (_cart[idx].quantity > 1) {
        _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity - 1);
      } else {
        _cart.removeAt(idx);
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final paymentMethod = await showDialog<String>(
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
            const SizedBox(height: 20),
            ...['Cash', 'Card', 'Mobile'].map((m) => ListTile(
                  leading: Icon(
                      m == 'Cash'
                          ? Icons.money
                          : m == 'Card'
                              ? Icons.credit_card
                              : Icons.phone_android,
                      color: SpiceColors.textSecondary),
                  title: Text(m),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () => Navigator.pop(ctx, m),
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

    if (paymentMethod == null) return;

    try {
      final createSale = ref.read(createSaleAction);
      final txnNumber = await createSale(
        items: _cart
            .map((c) => SaleItemInput(
                  productId: c.product.id,
                  productName: c.product.name,
                  quantity: c.quantity,
                  unitPrice: c.unitPrice,
                ))
            .toList(),
        paymentMethod: paymentMethod,
      );

      if (mounted) {
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Sale complete: $txnNumber | R ${_total.toStringAsFixed(2)}'),
          backgroundColor: SpiceColors.accent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: SpiceColors.danger,
        ));
      }
    }
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    String productType = 'finished';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Selling Price (R)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Cost Price (R)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Type:',
                        style: TextStyle(
                            color: SpiceColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Finished'),
                      selected: productType == 'finished',
                      onSelected: (_) =>
                          setDialogState(() => productType = 'finished'),
                      selectedColor: SpiceColors.primary.withAlpha(40),
                      labelStyle: TextStyle(
                        color: productType == 'finished'
                            ? SpiceColors.primary
                            : SpiceColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Raw Material'),
                      selected: productType == 'raw_material',
                      onSelected: (_) =>
                          setDialogState(() => productType = 'raw_material'),
                      selectedColor: SpiceColors.warning.withAlpha(40),
                      labelStyle: TextStyle(
                        color: productType == 'raw_material'
                            ? SpiceColors.warning
                            : SpiceColors.textSecondary,
                      ),
                    ),
                  ],
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
                    const SnackBar(
                        content: Text('Product name is required')),
                  );
                  return;
                }
                final price = double.tryParse(priceCtrl.text) ?? 0;
                final cost = double.tryParse(costCtrl.text) ?? 0;
                final category = categoryCtrl.text.trim();

                try {
                  final wsId = ref.read(workspaceStateProvider).selectedId;
                  if (wsId == null) return;

                  final result = await supabase
                      .from('products')
                      .insert({
                        'workspace_id': wsId,
                        'name': name,
                        'unit_price': price,
                        'cost_price': cost,
                        'sku': skuCtrl.text.trim().isEmpty
                            ? null
                            : skuCtrl.text.trim(),
                        'product_type': productType,
                        'unit_of_measure': 'unit',
                      })
                      .select()
                      .single();

                  final productId = result['id'];
                  await supabase.from('inventory').insert({
                    'workspace_id': wsId,
                    'product_id': productId,
                    'quantity_on_hand': 0,
                    'reorder_point': 10,
                  });

                  if (category.isNotEmpty) {
                    await supabase
                        .from('categories')
                        .upsert({
                          'workspace_id': wsId,
                          'name': category,
                        },
                            onConflict: 'workspace_id, name')
                        .select('id')
                        .single();

                    final catRes = await supabase
                        .from('categories')
                        .select('id')
                        .eq('workspace_id', wsId)
                        .eq('name', category)
                        .single();
                    await supabase
                        .from('products')
                        .update({
                          'category_id': catRes['id'],
                        })
                        .eq('id', productId);
                  }

                  ref.invalidate(productsProvider);
                  ref.invalidate(inventoryProvider);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
    final productsAsync = ref.watch(productsProvider);
    final products = productsAsync.valueOrNull ?? [];

    final filtered = _searchQuery.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Row(
        children: [
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
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: SpiceColors.primary, size: 32),
                        tooltip: 'Add Product',
                        onPressed: _showAddProductDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: productsAsync.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 48,
                                      color: SpiceColors.textSecondary),
                                  SizedBox(height: 12),
                                  Text('No products yet',
                                      style: TextStyle(
                                          color:
                                              SpiceColors.textSecondary)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  32, 0, 32, 32),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final p = filtered[index];
                                final hasCategory =
                                    p.category.isNotEmpty;
                                return GestureDetector(
                                  onTap: () => _addToCart(p),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: SpiceColors.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasCategory
                                            ? SpiceColors.primary
                                                .withAlpha(50)
                                            : SpiceColors.warning
                                                .withAlpha(50),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_rounded,
                                          size: 36,
                                          color: hasCategory
                                              ? SpiceColors.primary
                                              : SpiceColors.warning,
                                        ),
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                          child: Text(p.name,
                                              textAlign:
                                                  TextAlign.center,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: SpiceColors
                                                      .textPrimary)),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: SpiceColors.accent
                                                .withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'R ${p.unitPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color:
                                                    SpiceColors.accent),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(
                                    delay: (index * 40).ms);
                              },
                            ),
                ),
              ],
            ),
          ),
          Container(
            width: 340,
            decoration: BoxDecoration(
              color: SpiceColors.surfaceAlt,
              border: Border(left: BorderSide(color: SpiceColors.border)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: SpiceColors.border)),
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
                                  size: 40,
                                  color: SpiceColors.textSecondary),
                              SizedBox(height: 8),
                              Text('Cart is empty',
                                  style: TextStyle(
                                      color:
                                          SpiceColors.textSecondary)),
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
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: SpiceColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.product.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: SpiceColors
                                                      .textPrimary)),
                                          const SizedBox(height: 4),
                                          Text(
                                              'R ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: SpiceColors
                                                      .accent)),
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
                                          _qtyBtn(Icons.remove,
                                              () => _removeFromCart(index)),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12),
                                            child: Text('${item.quantity}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                          _qtyBtn(Icons.add,
                                              () => _addToCart(item.product)),
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
                        top: BorderSide(color: SpiceColors.border)),
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

class _CartItem {
  final Product product;
  final int quantity;

  const _CartItem({required this.product, required this.quantity});

  double get unitPrice => product.unitPrice;

  _CartItem copyWith({int? quantity}) =>
      _CartItem(product: product, quantity: quantity ?? this.quantity);
}

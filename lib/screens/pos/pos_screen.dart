import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final business = context.read<BusinessProvider>().business;
      if (business != null) {
        context.read<ProductProvider>().loadProducts(business.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posProvider = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          if (!posProvider.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (posProvider.isEmpty) Expanded(child: _buildProductGrid()),
          if (!posProvider.isEmpty) ...[
            Expanded(child: _buildCart()),
            _buildCartSummary(),
            _buildCheckoutButton(),
          ],
          if (posProvider.isEmpty) _buildBarcodeScanBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductProvider>().setSearchQuery(null);
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<ProductProvider>().setSearchQuery(
                value.isEmpty ? null : value,
              );
        },
      ),
    );
  }

  Widget _buildBarcodeScanBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: _barcodeController,
        decoration: InputDecoration(
          hintText: 'Scan or type barcode...',
          prefixIcon: const Icon(Icons.qr_code_scanner),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onSubmitted: _onBarcodeSubmitted,
      ),
    );
  }

  void _onBarcodeSubmitted(String barcode) async {
    if (barcode.isEmpty) return;
    final business = context.read<BusinessProvider>().business;
    if (business == null) return;

    final product = await context.read<ProductProvider>().findByBarcode(business.id, barcode);
    if (mounted && product != null) {
      context.read<PosProvider>().addItem(product);
      _barcodeController.clear();
    }
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Add products in Inventory first',
                    style: GoogleFonts.poppins(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: provider.products.length,
          itemBuilder: (context, index) {
            final product = provider.products[index];
            return _ProductGridTile(
              product: product,
              onTap: () => context.read<PosProvider>().addItem(product),
            );
          },
        );
      },
    );
  }

  Widget _buildCart() {
    return Consumer<PosProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            '${AppConstants.formatCurrency(item.product.price)} x ${item.quantity}',
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _qtyButton(Icons.remove, () => provider.updateQuantity(index, item.quantity - 1)),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text('${item.quantity}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                        _qtyButton(Icons.add, () => provider.updateQuantity(index, item.quantity + 1)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConstants.formatCurrency(item.lineTotal),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.spiceOrange),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () => provider.removeItem(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(width: 28, height: 28, alignment: Alignment.center, child: Icon(icon, size: 16)),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Consumer<PosProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _summaryRow('Subtotal', AppConstants.formatCurrency(provider.subtotal)),
              _summaryRow('VAT (15%)', AppConstants.formatCurrency(provider.taxAmount)),
              if (provider.discount > 0)
                _summaryRow('Discount', '-${AppConstants.formatCurrency(provider.discount)}'),
              const Divider(height: 16),
              _summaryRow('Total', AppConstants.formatCurrency(provider.total), bold: true, color: AppTheme.spiceOrange),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      items: AppConstants.paymentMethods
                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) provider.setPaymentMethod(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.orderType,
                      decoration: const InputDecoration(
                        labelText: 'Order Type',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      items: AppConstants.orderTypes
                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) provider.setOrderType(v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: ElevatedButton.icon(
        onPressed: _handleCheckout,
        icon: const Icon(Icons.check_circle_outline),
        label: Consumer<PosProvider>(
          builder: (_, provider, __) => Text('Checkout — ${AppConstants.formatCurrency(provider.total)}'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successGreen,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final provider = context.read<PosProvider>();
    if (provider.isEmpty) return;

    final business = context.read<BusinessProvider>().business;
    if (business == null) return;

    final orderItems = provider.toOrderItemsData();

    final createdOrder = await context.read<OrderProvider>().createOrder(
      businessId: business.id,
      customerId: provider.customerId,
      orderType: provider.orderType,
      status: 'Completed',
      subtotal: provider.subtotal,
      taxAmount: provider.taxAmount,
      discount: provider.discount,
      total: provider.total,
      paymentMethod: provider.paymentMethod,
      notes: provider.notes,
      items: orderItems,
    );

    if (!mounted) return;

    if (createdOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save order'), backgroundColor: AppTheme.dangerRed),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final p = ctx.watch<PosProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 56, color: AppTheme.successGreen),
                const SizedBox(height: 12),
                Text('Sale Complete!', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${p.totalQuantity} items sold', style: GoogleFonts.poppins(color: Colors.grey[600])),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.spiceOrange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Total: ${AppConstants.formatCurrency(p.total)}',
                          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.spiceOrange)),
                      const SizedBox(height: 4),
                      Text('Paid via ${p.paymentMethod}', style: GoogleFonts.poppins(color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text('Order #${createdOrder.id.substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _printReceipt();
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shareWhatsApp();
                        },
                        icon: const Icon(Icons.whatshot),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      provider.clear();
                    },
                    child: const Text('New Sale'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _printReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connect Niimbot B21 printer to print receipt')),
    );
  }

  void _shareWhatsApp() {
    final provider = context.read<PosProvider>();
    final message = 'SpiceDesk Sale\n'
        '${'─' * 20}\n'
        '${provider.items.map((i) => '${i.product.name} x${i.quantity} - ${AppConstants.formatCurrency(i.lineTotal)}').join('\n')}\n'
        '${'─' * 20}\n'
        'Total: ${AppConstants.formatCurrency(provider.total)}\n'
        'Payment: ${provider.paymentMethod}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Receipt ready to share:\n$message')),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from the cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<PosProvider>().clear();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ProductGridTile extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _ProductGridTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.spiceOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.spa_rounded, size: 20, color: AppTheme.spiceOrange),
              ),
              const SizedBox(height: 6),
              Text(
                product.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.formatCurrency(product.price is double ? product.price as double : 0),
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.spiceOrange),
              ),
              if (product.stockQty is int && (product.stockQty as int) <= 5)
                Text('${product.stockQty} left', style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.dangerRed)),
            ],
          ),
        ),
      ),
    );
  }
}

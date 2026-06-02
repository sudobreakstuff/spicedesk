import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/product.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final business = context.read<BusinessProvider>().business;
    if (business != null) {
      context.read<ProductProvider>().loadProducts(business.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductProvider>().setSearchQuery(null);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                context.read<ProductProvider>().setSearchQuery(
                      value.isEmpty ? null : value,
                    );
              },
            ),
          ),
          _buildStatsRow(),
          Expanded(child: _buildProductList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _statChip('All', '${provider.totalProducts}', AppColors.orange),
              const SizedBox(width: 8),
              _statChip('Low', '${provider.lowStockCount}', AppColors.yellow),
              const SizedBox(width: 8),
              _statChip('Out', '${provider.outOfStockCount}', AppColors.red),
              if (provider.showLowStockOnly)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => provider.toggleLowStockOnly(),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildProductList() {
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
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No products found', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 8),
                Text('Tap + to add your first product', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: provider.products.length,
          itemBuilder: (context, index) {
            final product = provider.products[index];
            return _ProductCard(
              product: product,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
                );
                _loadData();
              },
              onStockAdjust: (qty) {
                provider.adjustStock(product.id, qty);
              },
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    final provider = context.read<ProductProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Products', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Low Stock Only', style: GoogleFonts.poppins()),
                  value: provider.showLowStockOnly,
                  activeColor: AppColors.orange,
                  onChanged: (_) => provider.toggleLowStockOnly(),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: provider.categoryFilter == null,
                      onSelected: (_) => provider.setCategoryFilter(null),
                      selectedColor: AppColors.orange.withOpacity(0.2),
                    ),
                    ...provider.categories.map(
                      (cat) => ChoiceChip(
                        label: Text(cat.name),
                        selected: provider.categoryFilter == cat.id,
                        onSelected: (_) => provider.setCategoryFilter(cat.id),
                        selectedColor: AppColors.orange.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scanBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode scanner - connect camera to enable')),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final Function(int) onStockAdjust;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onStockAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.isOutOfStock
                      ? AppColors.red.withOpacity(0.1)
                      : product.isLowStock
                          ? AppColors.yellow.withOpacity(0.1)
                          : AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                    child: Icon(
                      product.isOutOfStock
                          ? Icons.inventory_2_outlined
                          : Icons.inventory_2,
                  color: product.isOutOfStock
                      ? AppColors.red
                      : AppColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          AppConstants.formatCurrency(product.price),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                            fontSize: 14,
                          ),
                        ),
                        if (product.costPrice > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Cost: ${AppConstants.formatCurrency(product.costPrice)}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isOutOfStock
                          ? AppColors.red.withOpacity(0.1)
                          : product.isLowStock
                              ? AppColors.yellow.withOpacity(0.1)
                              : const Color(0xFF27AE60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stock: ${product.stockQty}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: product.isOutOfStock
                            ? AppColors.red
                            : product.isLowStock
                                ? AppColors.brown
                                : const Color(0xFF27AE60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stockButton(Icons.remove, () => onStockAdjust(-1)),
                      const SizedBox(width: 4),
                      _stockButton(Icons.add, () => onStockAdjust(1)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.brown),
        ),
      ),
    );
  }
}

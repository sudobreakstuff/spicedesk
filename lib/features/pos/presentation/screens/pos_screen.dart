import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/products_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../pos/data/pos_service.dart';
import '../../../printing/data/printing_service.dart';
import '../../../workspace/domain/workspace_state.dart';
import '../../../customers/data/customers_provider.dart';

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
    final customersAsync = ref.read(customersProvider);
    final customers = customersAsync.valueOrNull ?? [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CheckoutDialog(
        total: _total,
        customers: customers,
      ),
    );

    if (result == null) return;

    final paymentMethod = result['paymentMethod'] as String;
    final orderType = result['orderType'] as String?;
    final customerId = result['customerId'] as String?;

    try {
      final createSale = ref.read(createSaleAction);
      final saleResult = await createSale(
        items: _cart
            .map((c) => SaleItemInput(
                  productId: c.product.id,
                  productName: c.product.name,
                  quantity: c.quantity,
                  unitPrice: c.unitPrice,
                ))
            .toList(),
        paymentMethod: paymentMethod,
        customerId: customerId,
        orderType: orderType,
      );

      if (mounted) {
        final cartSnapshot = List<_CartItem>.from(_cart);
        setState(() => _cart.clear());
        _showReceiptDialog(saleResult, cartSnapshot, paymentMethod);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: SpiceColors.danger,
        ));
      }
    }
  }

  void _showReceiptDialog(SaleResult result, List<_CartItem> items, String paymentMethod) {
    final workspace = ref.read(workspaceStateProvider);
    final storeName = workspace.selectedName ?? 'SpiceDesk';
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final validUntil = DateTime(now.year, now.month, now.day + 7);
    final validStr = '${validUntil.day}/${validUntil.month}/${validUntil.year}';

    final invoiceText = _buildInvoiceText(storeName, result, items, dateStr, paymentMethod);
    final quoteText = _buildQuoteText(storeName, items, dateStr, validStr, result.total);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: SpiceColors.accent, size: 24),
            const SizedBox(width: 10),
            const Text('Sale Complete',
                style: TextStyle(color: SpiceColors.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SpiceColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _receiptRow('Txn', result.transactionNumber),
                    const SizedBox(height: 4),
                    _receiptRow('Invoice', result.invoiceNumber),
                    const SizedBox(height: 4),
                    _receiptRow('Paid', paymentMethod),
                    _receiptRow('Date', dateStr),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.product.name,
                        style: const TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                    Text('x${item.quantity}',
                        style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                    const SizedBox(width: 12),
                    Text('R ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Divider(color: SpiceColors.border),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                  Text('R ${result.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.accent)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final encoded = Uri.encodeComponent(invoiceText);
              final uri = Uri.parse('https://wa.me/?text=$encoded');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('WhatsApp'),
          ),
          TextButton.icon(
            onPressed: () async {
              final encoded = Uri.encodeComponent(quoteText);
              final uri = Uri.parse('https://wa.me/?text=$encoded');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.description, size: 18),
            label: const Text('Quote'),
          ),
          TextButton.icon(
            onPressed: () async {
              await _generatePdfInvoice(storeName, result, items, dateStr, paymentMethod);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                final printing = PrintingService();
                if (printing.isConnected) {
                  await printing.printReceipt(
                    storeName: storeName,
                    transactionNumber: result.transactionNumber,
                    date: DateTime.now(),
                    items: items.map((i) => ReceiptLineItem(
                      name: i.product.name,
                      quantity: i.quantity,
                      unitPrice: i.unitPrice,
                      lineTotal: i.unitPrice * i.quantity,
                    )).toList(),
                    total: result.total,
                    paymentMethod: paymentMethod,
                  );
                }
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _buildInvoiceText(String storeName, SaleResult result, List<_CartItem> items, String dateStr, String paymentMethod) {
    final buf = StringBuffer();
    buf.writeln('*$storeName*');
    buf.writeln('Date: $dateStr');
    buf.writeln('Invoice: ${result.invoiceNumber}');
    buf.writeln('Payment: $paymentMethod');
    buf.writeln('');
    buf.writeln('--- Items ---');
    for (final item in items) {
      final lineTotal = item.unitPrice * item.quantity;
      buf.writeln('${item.product.name} x${item.quantity} @ R ${item.unitPrice.toStringAsFixed(2)} = R ${lineTotal.toStringAsFixed(2)}');
    }
    buf.writeln('');
    buf.writeln('*Total: R ${result.total.toStringAsFixed(2)}*');
    buf.writeln('');
    buf.writeln('Thank you!');
    buf.writeln('Txn: ${result.transactionNumber}');
    return buf.toString();
  }

  String _buildQuoteText(String storeName, List<_CartItem> items, String dateStr, String validStr, double total) {
    final buf = StringBuffer();
    buf.writeln('*QUOTE*');
    buf.writeln(storeName);
    buf.writeln('Date: $dateStr');
    buf.writeln('Valid until: $validStr');
    buf.writeln('');
    buf.writeln('--- Items ---');
    for (final item in items) {
      final lineTotal = item.unitPrice * item.quantity;
      buf.writeln('${item.product.name} x${item.quantity} @ R ${item.unitPrice.toStringAsFixed(2)} = R ${lineTotal.toStringAsFixed(2)}');
    }
    buf.writeln('');
    buf.writeln('*Total: R ${total.toStringAsFixed(2)}*');
    buf.writeln('');
    buf.writeln('Prices valid until $validStr');
    buf.writeln('Thank you for your inquiry!');
    return buf.toString();
  }

  Future<void> _generatePdfInvoice(
      String storeName, SaleResult result, List<_CartItem> items, String dateStr, String paymentMethod) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        final headers = ['Item', 'Qty', 'Price', 'Total'];
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(storeName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Invoice: ${result.invoiceNumber}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Payment: $paymentMethod', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Txn: ${result.transactionNumber}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: items.map((i) => [
                    i.product.name,
                    '${i.quantity}',
                    'R ${i.unitPrice.toStringAsFixed(2)}',
                    'R ${(i.unitPrice * i.quantity).toStringAsFixed(2)}',
                  ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('TOTAL: R ${result.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 32),
            pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 12)),
          ],
        );
      },
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'invoice_${result.invoiceNumber}.pdf',
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary)),
        ),
      ],
    );
  }

  void _showProductActions(Product product) {
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
                  product.name,
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
                title: const Text('Edit Product'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditProductDialog(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: SpiceColors.danger),
                title: const Text('Delete Product'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteProductDialog(product);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl =
        TextEditingController(text: product.unitPrice.toString());
    final costCtrl =
        TextEditingController(text: product.costPrice.toString());
    final skuCtrl = TextEditingController(text: product.sku ?? '');
    final categoryCtrl = TextEditingController(text: product.category);
    String productType = product.productType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: const Text('Edit Product'),
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
                  if (wsId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select or create a workspace first'),
                        backgroundColor: SpiceColors.danger,
                      ),
                    );
                    return;
                  }

                  await supabase
                      .from('products')
                      .update({
                        'name': name,
                        'unit_price': price,
                        'cost_price': cost,
                        'sku': skuCtrl.text.trim().isEmpty
                            ? null
                            : skuCtrl.text.trim(),
                        'product_type': productType,
                      })
                      .eq('id', product.id);

                  if (category.isNotEmpty) {
                    final catResult = await supabase
                        .from('categories')
                        .insert({
                          'workspace_id': wsId,
                          'name': category,
                        })
                        .select('id')
                        .single();
                    await supabase
                        .from('products')
                        .update({
                          'category_id': catResult['id'],
                        })
                        .eq('id', product.id);
                  }

                  ref.invalidate(productsProvider);
                  ref.invalidate(inventoryProvider);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error updating product: $e'),
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
      ),
    );
  }

  void _showDeleteProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This will also remove its inventory tracking.',
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
                final wsId = ref.read(workspaceStateProvider).selectedId;
                if (wsId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select or create a workspace first'),
                      backgroundColor: SpiceColors.danger,
                    ),
                  );
                  return;
                }

                await supabase
                    .from('inventory')
                    .delete()
                    .eq('product_id', product.id)
                    .eq('workspace_id', wsId);
                await supabase
                    .from('products')
                    .delete()
                    .eq('id', product.id);

                ref.invalidate(productsProvider);
                ref.invalidate(inventoryProvider);

                setState(() {
                  _cart.removeWhere((c) => c.product.id == product.id);
                });

                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('"${product.name}" deleted'),
                    backgroundColor: SpiceColors.accent,
                  ));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Error deleting product: $e'),
                    backgroundColor: SpiceColors.danger,
                  ));
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
                  if (wsId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select or create a workspace first'),
                        backgroundColor: SpiceColors.danger,
                      ),
                    );
                    return;
                  }

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
                    final catResult = await supabase
                        .from('categories')
                        .insert({
                          'workspace_id': wsId,
                          'name': category,
                        })
                        .select('id')
                        .single();
                    await supabase
                        .from('products')
                        .update({
                          'category_id': catResult['id'],
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
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error adding product: $e'),
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
    final products = (productsAsync.valueOrNull ?? [])
        .where((p) => p.productType != 'raw_material')
        .toList();

    final inventoryAsync = ref.watch(inventoryProvider);
    final inventoryItems = inventoryAsync.valueOrNull ?? [];
    final inventoryMap = <String, double>{};
    for (final inv in inventoryItems) {
      inventoryMap[inv.productId] = inv.quantityOnHand;
    }

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
                                final stockQty = inventoryMap[p.id] ?? 0;
                                final isOutOfStock = stockQty <= 0;
                                return Opacity(
                                  opacity: isOutOfStock ? 0.4 : 1.0,
                                  child: GestureDetector(
                                  onTap: isOutOfStock ? null : () => _addToCart(p),
                                  onLongPress: () =>
                                      _showProductActions(p),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          isOutOfStock
                                              ? 'Out of stock'
                                              : 'In stock: ${stockQty.toInt()}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isOutOfStock
                                                ? SpiceColors.danger
                                                : SpiceColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
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

class _CheckoutDialog extends StatefulWidget {
  final double total;
  final List<Customer> customers;

  const _CheckoutDialog({
    required this.total,
    required this.customers,
  });

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  String? _selectedCustomerId;
  String _selectedCustomerName = 'Walk-in';
  String _serviceType = 'Dine-in';
  final _serviceTypes = ['Dine-in', 'Pickup', 'Delivery'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SpiceColors.surfaceAlt,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border)),
      title: const Text('Checkout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: R ${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.accent)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SpiceColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: null,
                  hint: Text(
                    _selectedCustomerName,
                    style: const TextStyle(
                        color: SpiceColors.textPrimary, fontSize: 14),
                  ),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: SpiceColors.textSecondary),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'walkin',
                      child: Text('Walk-in',
                          style: TextStyle(color: SpiceColors.textSecondary)),
                    ),
                    ...widget.customers.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name,
                              style: const TextStyle(
                                  color: SpiceColors.textPrimary)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == null || value == 'walkin') {
                        _selectedCustomerId = null;
                        _selectedCustomerName = 'Walk-in';
                      } else {
                        _selectedCustomerId = value;
                        _selectedCustomerName =
                            widget.customers.firstWhere((c) => c.id == value).name;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Service Type',
                style: TextStyle(
                    fontSize: 13,
                    color: SpiceColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: _serviceTypes.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t),
                  selected: _serviceType == t,
                  onSelected: (_) =>
                      setState(() => _serviceType = t),
                  selectedColor:
                      SpiceColors.primary.withAlpha(40),
                  labelStyle: TextStyle(
                    color: _serviceType == t
                        ? SpiceColors.primary
                        : SpiceColors.textSecondary,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Payment Method',
                style: TextStyle(
                    fontSize: 13,
                    color: SpiceColors.textSecondary)),
            const SizedBox(height: 8),
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
                  onTap: () => Navigator.pop(context, {
                    'paymentMethod': m.toLowerCase(),
                    'orderType': _serviceType,
                    'customerId': _selectedCustomerId,
                  }),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ],
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

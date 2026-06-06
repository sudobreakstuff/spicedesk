import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/products_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../pos/data/pos_service.dart';
import '../../../pos/data/quote_service.dart';
import '../../../workspace/domain/workspace_state.dart';
import '../../../customers/data/customers_provider.dart';
import '../../../settings/data/settings_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  final List<_CartItem> _cart = [];
  String _searchQuery = '';

  Future<double> get _getDeliveryCharge async {
    try {
      final settings = await ref.read(workspaceSettingsProvider.future);
      final val = settings['delivery_charge'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 20.0;
      return 20.0;
    } catch (_) {
      return 20.0;
    }
  }

  double get _total => _cart.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));

  Map<String, double> _getInventoryMap() {
    final inventoryItems = ref.read(inventoryProvider).valueOrNull ?? [];
    final map = <String, double>{};
    for (final inv in inventoryItems) {
      map[inv.productId] = inv.quantityOnHand;
    }
    return map;
  }

  void _addToCart(Product product) {
    final inventoryMap = _getInventoryMap();
    final stock = inventoryMap[product.id] ?? 0;
    final currentInCart = _cart.fold<int>(0, (sum, i) {
      if (i.product.id == product.id) return sum + i.quantity;
      return sum;
    });

    if (currentInCart + 1 > stock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Insufficient stock: only $stock available for ${product.name}'),
        backgroundColor: SpiceColors.warning,
        duration: Duration(seconds: 2),
      ));
      return;
    }

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

    final deliveryCharge = await _getDeliveryCharge;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CheckoutDialog(
        total: _total,
        customers: customers,
        deliveryCharge: deliveryCharge,
      ),
    );

    if (result == null) return;

    final paymentMethod = result['paymentMethod'] as String;
    final orderType = result['orderType'] as String?;
    final customerId = result['customerId'] as String?;

    try {
      final createSale = ref.read(createSaleAction);
      final saleItems = _cart
          .map((c) => SaleItemInput(
                productId: c.product.id,
                productName: c.product.name,
                quantity: c.quantity,
                unitPrice: c.unitPrice,
              ))
          .toList();

      // Add delivery fee if applicable, read from settings
      if (orderType == 'Delivery') {
        final settings = await ref.read(workspaceSettingsProvider.future);
        final val = settings['delivery_charge'];
        final deliveryCharge = val is num ? val.toDouble() : (val is String ? double.tryParse(val) ?? 20.0 : 20.0);
        saleItems.add(SaleItemInput(
          productName: 'Delivery Fee',
          quantity: 1,
          unitPrice: deliveryCharge,
        ));
      }

      final saleResult = await createSale(
        items: saleItems,
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

  Future<void> _createQuote() async {
    if (_cart.isEmpty) return;
    final customersAsync = ref.read(customersProvider);
    final customers = customersAsync.valueOrNull ?? [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CheckoutDialog(
        total: _total,
        customers: customers,
        isQuote: true,
      ),
    );

    if (result == null) return;

    final customerId = result['customerId'] as String?;

    try {
      final createQuote = ref.read(createQuoteAction);
      final quoteResult = await createQuote(
        items: _cart
            .map((c) => SaleItemInput(
                  productId: c.product.id,
                  productName: c.product.name,
                  quantity: c.quantity,
                  unitPrice: c.unitPrice,
                ))
            .toList(),
        customerId: customerId,
      );

      if (mounted) {
        final cartSnapshot = List<_CartItem>.from(_cart);
        setState(() => _cart.clear());
        _showQuoteReceiptDialog(quoteResult, cartSnapshot);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Quote failed: $e'),
          backgroundColor: SpiceColors.danger,
        ));
      }
    }
  }

  void _showQuoteReceiptDialog(QuoteResult result, List<_CartItem> items) {
    final workspace = ref.read(workspaceStateProvider);
    final storeName = workspace.selectedName ?? 'SpiceDesk';
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final validStr = '${result.validUntil.day}/${result.validUntil.month}/${result.validUntil.year}';


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
            Icon(Icons.description, color: SpiceColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Quote Created',
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
                    _receiptRow('Quote', result.quoteNumber),
                    SizedBox(height: 4),
                    _receiptRow('Valid until', validStr),
                    _receiptRow('Date', dateStr),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.product.name,
                        style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                    Text('x${item.quantity}',
                        style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                    SizedBox(width: 12),
                    Text('R ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                  ],
                ),
              )),
              SizedBox(height: 12),
              Divider(color: SpiceColors.border),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                  Text('R ${result.total.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.accent)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _generateQuotePdf(storeName, result, items, dateStr);
            },
            icon: Icon(Icons.share, size: 18),
            label: Text('Share PDF'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(SaleResult result, List<_CartItem> items, String paymentMethod) {
    final workspace = ref.read(workspaceStateProvider);
    final storeName = workspace.selectedName ?? 'SpiceDesk';
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final validUntil = DateTime(now.year, now.month, now.day + 7);
    final validStr = '${validUntil.day}/${validUntil.month}/${validUntil.year}';


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
            SizedBox(width: 10),
            Text('Sale Complete',
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
                    SizedBox(height: 4),
                    _receiptRow('Invoice', result.invoiceNumber),
                    SizedBox(height: 4),
                    _receiptRow('Paid', paymentMethod),
                    _receiptRow('Date', dateStr),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.product.name,
                        style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                    Text('x${item.quantity}',
                        style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                    SizedBox(width: 12),
                    Text('R ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                  ],
                ),
              )),
              SizedBox(height: 12),
              Divider(color: SpiceColors.border),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                  Text('R ${result.total.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.accent)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _generatePdfInvoice(storeName, result, items, dateStr, paymentMethod);
            },
            icon: Icon(Icons.share, size: 18),
            label: Text('Share PDF'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done'),
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
    try {
      final wsId = ref.read(workspaceStateProvider).selectedId;
      Map<String, dynamic> s = {};
      if (wsId != null) {
        final data = await supabase.from('workspaces').select('settings').eq('id', wsId).maybeSingle();
        s = (data?['settings'] as Map<String, dynamic>?) ?? {};
      }
      final company = s['company_name']?.toString() ?? storeName;
      final address = s['company_address']?.toString();
      final phone = s['company_phone']?.toString();
      final email = s['company_email']?.toString();
      final taxNum = s['tax_number']?.toString();
      final bank = s['bank_name']?.toString();
      final holder = s['account_holder']?.toString();
      final accNum = s['account_number']?.toString();
      final terms = s['invoice_terms']?.toString() ?? 'Thank you for your business';

      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(company, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (address != null && address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                if (phone != null && phone.isNotEmpty) pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 10)),
                if (email != null && email.isNotEmpty) pw.Text('Email: $email', style: const pw.TextStyle(fontSize: 10)),
                if (taxNum != null && taxNum.isNotEmpty) pw.Text('VAT: $taxNum', style: const pw.TextStyle(fontSize: 10)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('${s['invoice_prefix']?.toString() ?? 'INV-'}${result.invoiceNumber}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Payment: $paymentMethod', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Txn: ${result.transactionNumber}', style: const pw.TextStyle(fontSize: 10)),
              ]),
            ]),
            pw.SizedBox(height: 24),
            pw.Row(children: [
              pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            ]),
            pw.Divider(),
            ...items.map((i) => pw.Row(children: [
              pw.Expanded(flex: 3, child: pw.Text(i.product.name, style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(flex: 1, child: pw.Text('${i.quantity}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('R ${i.unitPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(flex: 2, child: pw.Text('R ${(i.unitPrice * i.quantity).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
            ])),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('TOTAL: R ${result.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 24),
            if (bank != null && bank.isNotEmpty) ...[
              pw.Text('Banking Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Bank: $bank', style: const pw.TextStyle(fontSize: 10)),
              if (holder != null && holder.isNotEmpty) pw.Text('Account Holder: $holder', style: const pw.TextStyle(fontSize: 10)),
              if (accNum != null && accNum.isNotEmpty) pw.Text('Account: $accNum', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),
            ],
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(terms, style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
          ],
        ),
      ));

      await Printing.sharePdf(bytes: await doc.save(), filename: 'invoice_${result.invoiceNumber}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e'), backgroundColor: SpiceColors.danger));
      }
      debugPrint('PDF error: $e');
    }
  }

  Future<void> _generateQuotePdf(
      String storeName, QuoteResult result, List<_CartItem> items, String dateStr) async {
    final doc = pw.Document();
    final validStr = '${result.validUntil.day}/${result.validUntil.month}/${result.validUntil.year}';
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        final headers = ['Item', 'Qty', 'Price', 'Total'];
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('QUOTE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.SizedBox(height: 4),
            pw.Text(storeName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Quote: ${result.quoteNumber}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Valid until: $validStr', style: const pw.TextStyle(fontSize: 12)),
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
            pw.Text('Prices valid until $validStr', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Text('Thank you for your inquiry!', style: const pw.TextStyle(fontSize: 12)),
          ],
        );
      },
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'quote_${result.quoteNumber}.pdf',
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary)),
        ),
      ],
    );
  }

  void _showProductActions(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpiceColors.surfaceAlt,
      shape: RoundedRectangleBorder(
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
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.edit, color: SpiceColors.primary),
                title: Text('Edit Product'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditProductDialog(product);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: SpiceColors.danger),
                title: Text('Delete Product'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteProductDialog(product);
                },
              ),
              SizedBox(height: 8),
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
          title: Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: 'Selling Price (R)'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: 'Cost Price (R)'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: skuCtrl,
                  decoration: InputDecoration(labelText: 'SKU'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Type:',
                        style: TextStyle(
                            color: SpiceColors.textSecondary, fontSize: 13)),
                    SizedBox(width: 12),
                    ChoiceChip(
                      label: Text('Finished'),
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
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Raw Material'),
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
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
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
                      SnackBar(
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
              child: Text('Save'),
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
        title: Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This will also remove its inventory tracking.',
          style: TextStyle(color: SpiceColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final wsId = ref.read(workspaceStateProvider).selectedId;
                if (wsId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
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
            child: Text('Delete'),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: 'Selling Price (R)'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: 'Cost Price (R)'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: skuCtrl,
                  decoration: InputDecoration(labelText: 'SKU'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
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
                      SnackBar(
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
                        'product_type': 'finished',
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
              child: Text('Save'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildHeaderRow(),
                  SizedBox(height: 8),
                  TabBar(
                    tabs: [
                      Tab(text: 'Products'),
                      Tab(text: 'Cart'),
                    ],
                    labelColor: SpiceColors.primary,
                    unselectedLabelColor: SpiceColors.textSecondary,
                    indicatorColor: SpiceColors.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 12),
                            Expanded(child: _buildProductGrid(filtered, inventoryMap, productsAsync.isLoading)),
                          ],
                        ),
                        _buildCartPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderRow(),
                    SizedBox(height: 20),
                    Expanded(child: _buildProductGrid(filtered, inventoryMap, productsAsync.isLoading)),
                  ],
                ),
              ),
              Container(
                width: 340,
                decoration: BoxDecoration(
                  color: SpiceColors.surfaceAlt,
                  border: Border(left: BorderSide(color: SpiceColors.border)),
                ),
                child: _buildCartPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          return isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Point of Sale',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: SpiceColors.primary, size: 28),
                        tooltip: 'Add Product',
                        onPressed: _showAddProductDialog,
                      ),
                    ]),
                    SizedBox(height: 8),
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text('Point of Sale',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                    Spacer(),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: SpiceColors.primary, size: 32),
                      tooltip: 'Add Product',
                      onPressed: _showAddProductDialog,
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> filtered, Map<String, double> inventoryMap, bool isLoading) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: SpiceColors.textSecondary),
            SizedBox(height: 12),
            Text('No products yet', style: TextStyle(color: SpiceColors.textSecondary)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        final hasCategory = p.category.isNotEmpty;
        final stockQty = inventoryMap[p.id] ?? 0;
        final isOutOfStock = stockQty <= 0;
        return Opacity(
          opacity: isOutOfStock ? 0.4 : 1.0,
          child: GestureDetector(
            onTap: isOutOfStock ? null : () => _addToCart(p),
            onLongPress: () => _showProductActions(p),
            child: Container(
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCategory
                      ? SpiceColors.primary.withAlpha(50)
                      : SpiceColors.warning.withAlpha(50),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_rounded, size: 36,
                      color: hasCategory ? SpiceColors.primary : SpiceColors.warning),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(p.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary)),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: SpiceColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('R ${p.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isOutOfStock ? 'Out of stock' : 'In stock: ${stockQty.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isOutOfStock ? SpiceColors.danger : SpiceColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 40).ms),
        );
      },
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: SpiceColors.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: SpiceColors.textPrimary, size: 20),
              SizedBox(width: 10),
              Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              Spacer(),
              if (_cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SpiceColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_cart.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
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
                      Icon(Icons.shopping_cart_outlined, size: 40, color: SpiceColors.textSecondary),
                      SizedBox(height: 8),
                      Text('Cart is empty', style: TextStyle(color: SpiceColors.textSecondary)),
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
                          border: Border.all(color: SpiceColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary)),
                                  SizedBox(height: 4),
                                  Text('R ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent)),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: SpiceColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SpiceColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _qtyBtn(Icons.remove, () => _removeFromCart(index)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  _qtyBtn(Icons.add, () => _addToCart(item.product)),
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
            border: Border(top: BorderSide(color: SpiceColors.border)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 16, color: SpiceColors.textSecondary)),
                  Text('R ${_total.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: SpiceColors.accent)),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _cart.isEmpty ? null : _createQuote,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Quote', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _cart.isEmpty ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SpiceColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
  final bool isQuote;
  final double deliveryCharge;

  _CheckoutDialog({
    required this.total,
    required this.customers,
    this.isQuote = false,
    this.deliveryCharge = 20.0,
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
    final isQuote = widget.isQuote;
    return AlertDialog(
      backgroundColor: SpiceColors.surfaceAlt,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: SpiceColors.border)),
      title: Text(isQuote ? 'Create Quote' : 'Checkout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: R ${widget.total.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.accent)),
            if (_serviceType == 'Delivery') ...[
              SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: SpiceColors.warning.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Text('+ R${widget.deliveryCharge.toStringAsFixed(2)} delivery fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.warning)),
              ),
              SizedBox(height: 2),
              Text('Grand Total: R ${(widget.total + widget.deliveryCharge).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SpiceColors.accent)),
            ],
            SizedBox(height: 20),
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
                    style: TextStyle(
                        color: SpiceColors.textPrimary, fontSize: 14),
                  ),
                  icon: Icon(Icons.arrow_drop_down,
                      color: SpiceColors.textSecondary),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'walkin',
                      child: Text('Walk-in',
                          style: TextStyle(color: SpiceColors.textSecondary)),
                    ),
                    ...widget.customers.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name,
                              style: TextStyle(
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
            if (!isQuote) ...[
              SizedBox(height: 20),
              Text('Service Type',
                  style: TextStyle(
                      fontSize: 13,
                      color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
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
              SizedBox(height: 20),
              Text('Payment Method',
                  style: TextStyle(
                      fontSize: 13,
                      color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
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
            ] else ...[
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'customerId': _selectedCustomerId,
                    'isQuote': true,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpiceColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Create Quote',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel')),
      ],
    );
  }
}

class _CartItem {
  final Product product;
  final int quantity;

  _CartItem({required this.product, required this.quantity});

  double get unitPrice => product.unitPrice;

  _CartItem copyWith({int? quantity}) =>
      _CartItem(product: product, quantity: quantity ?? this.quantity);
}

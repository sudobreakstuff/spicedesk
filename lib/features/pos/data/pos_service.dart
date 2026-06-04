import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';
import '../../products/data/products_provider.dart';
import '../../inventory/data/inventory_provider.dart';
import '../../sales/data/sales_provider.dart';
import '../../customers/data/customers_provider.dart';

/// Create a sale via the `create_sale` RPC function.
/// Includes automatic inventory deduction and stock movement records.
final createSaleAction = Provider<Future<SaleResult> Function({
  required List<SaleItemInput> items,
  required String paymentMethod,
  String? customerId,
})>((ref) {
  return ({
    required List<SaleItemInput> items,
    required String paymentMethod,
    String? customerId,
  }) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) throw Exception('No workspace selected');

    final itemsJson = items.map((item) => {
      'product_id': item.productId,
      'product_name': item.productName,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
    }).toList();

    final result = await supabase.rpc('create_sale', params: {
      'p_workspace_id': wsId,
      'p_customer_id': customerId,
      'p_payment_method': paymentMethod,
      'p_items': itemsJson,
    });

    if (customerId != null) {
      await supabase.rpc('increment_loyalty', params: {'p_customer_id': customerId});
    }

    ref.invalidate(inventoryProvider);
    ref.invalidate(salesProvider);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(productsProvider);

    return SaleResult.fromJson(result);
  };
});

class SaleResult {
  final String transactionNumber;
  final String invoiceNumber;
  final double total;

  const SaleResult({
    required this.transactionNumber,
    required this.invoiceNumber,
    required this.total,
  });

  factory SaleResult.fromJson(Map<String, dynamic> json) {
    return SaleResult(
      transactionNumber: json['transaction_number'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SaleItemInput {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const SaleItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

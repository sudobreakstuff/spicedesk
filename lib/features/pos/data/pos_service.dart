import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';
import '../../inventory/data/inventory_provider.dart';
import '../../sales/data/sales_provider.dart';
import '../../customers/data/customers_provider.dart';

/// Create a sale via the `create_sale` RPC function.
/// Includes automatic inventory deduction and stock movement records.
final createSaleAction = Provider<Future<String> Function({
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

    // Invalidate providers to refresh data
    ref.invalidate(inventoryProvider);
    ref.invalidate(salesProvider);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(customersProvider);

    return result['transaction_number'] as String;
  };
});

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

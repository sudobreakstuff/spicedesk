import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';
import '../../products/data/products_provider.dart';

final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('inventory')
      .select('id, product_id, quantity_on_hand, reorder_point, unit_of_measure, products(name, sku, unit_price, cost_price, product_type)')
      .eq('workspace_id', wsId)
      .order('quantity_on_hand');

  return data.map<InventoryItem>((row) {
    final product = row['products'] as Map<String, dynamic>? ?? {};
    return InventoryItem(
      id: row['id'],
      productId: row['product_id'],
      productName: product['name'] ?? 'Unknown',
      sku: product['sku'] ?? '',
      quantityOnHand: (row['quantity_on_hand'] as num?)?.toDouble() ?? 0,
      reorderPoint: (row['reorder_point'] as num?)?.toDouble() ?? 0,
      unitPrice: (product['unit_price'] as num?)?.toDouble() ?? 0,
      costPrice: (product['cost_price'] as num?)?.toDouble() ?? 0,
      productType: product['product_type'] ?? 'finished',
      unitOfMeasure: row['unit_of_measure'] ?? 'unit',
    );
  }).toList();
});

final productsNeedingInventoryProvider = FutureProvider<List<Product>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final products = await ref.watch(productsProvider.future);
  final inventory = await ref.watch(inventoryProvider.future);
  final trackedIds = inventory.map((i) => i.productId).toSet();

  return products.where((p) => !trackedIds.contains(p.id)).toList();
});

class InventoryItem {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final double quantityOnHand;
  final double reorderPoint;
  final double unitPrice;
  final double costPrice;
  final String productType;
  final String unitOfMeasure;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantityOnHand,
    required this.reorderPoint,
    required this.unitPrice,
    this.costPrice = 0,
    this.productType = 'finished',
    this.unitOfMeasure = 'unit',
  });

  InventoryItem copyWith({double? quantityOnHand}) {
    return InventoryItem(
      id: id,
      productId: productId,
      productName: productName,
      sku: sku,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      reorderPoint: reorderPoint,
      unitPrice: unitPrice,
      costPrice: costPrice,
      productType: productType,
      unitOfMeasure: unitOfMeasure,
    );
  }
}

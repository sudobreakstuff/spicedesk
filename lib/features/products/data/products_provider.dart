import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('products')
      .select('id, name, sku, barcode, description, unit_price, tax_rate, image_url, is_active, category_id, categories(name)')
      .eq('workspace_id', wsId)
      .order('name');

  return data.map<Product>((row) {
    return Product(
      id: row['id'],
      name: row['name'] ?? '',
      sku: row['sku'],
      barcode: row['barcode'],
      unitPrice: (row['unit_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (row['tax_rate'] as num?)?.toDouble() ?? 0.0,
      imageUrl: row['image_url'],
      isActive: row['is_active'] ?? true,
      category: row['categories'] != null ? (row['categories']['name'] ?? '') : '',
    );
  }).toList();
});

class Product {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double unitPrice;
  final double taxRate;
  final String? imageUrl;
  final bool isActive;
  final String category;

  const Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.unitPrice,
    this.taxRate = 0.0,
    this.imageUrl,
    this.isActive = true,
    this.category = '',
  });
}

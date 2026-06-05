import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';
import 'pos_service.dart';

final createQuoteAction = Provider<Future<QuoteResult> Function({
  required List<SaleItemInput> items,
  String? customerId,
})>((ref) {
  return ({
    required List<SaleItemInput> items,
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

    final total = items.fold<double>(0, (sum, i) => sum + (i.unitPrice * i.quantity));

    final result = await supabase.from('quotes').insert({
      'workspace_id': wsId,
      'customer_id': customerId,
      'items': itemsJson,
      'total': total,
      'status': 'draft',
      'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    }).select().single();

    final quoteId = result['id'] as String;
    final quoteNumber = 'QTE-${quoteId.substring(0, 8).toUpperCase()}';

    await supabase.from('quotes').update({
      'quote_number': quoteNumber,
    }).eq('id', quoteId);

    return QuoteResult(
      quoteNumber: quoteNumber,
      total: total,
      validUntil: DateTime.now().add(const Duration(days: 30)),
    );
  };
});

class QuoteResult {
  final String quoteNumber;
  final double total;
  final DateTime validUntil;

  const QuoteResult({
    required this.quoteNumber,
    required this.total,
    required this.validUntil,
  });
}

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

    final user = supabase.auth.currentUser;
    final subtotal = items.fold<double>(0, (sum, i) => sum + (i.unitPrice * i.quantity));
    final taxTotal = 0.0;

    final existing = await supabase
        .from('quotes')
        .select('quote_number')
        .eq('workspace_id', wsId)
        .order('created_at', ascending: false)
        .limit(1);

    int nextNum = 1;
    if (existing.isNotEmpty) {
      final lastNum = existing.first['quote_number'] as String?;
      if (lastNum != null && lastNum.startsWith('QTE-')) {
        final numPart = int.tryParse(lastNum.substring(4));
        if (numPart != null) nextNum = numPart + 1;
      }
    }
    final quoteNumber = 'QTE-${nextNum.toString().padLeft(4, '0')}';

    final result = await supabase.from('quotes').insert({
      'workspace_id': wsId,
      'quote_number': quoteNumber,
      'customer_id': customerId,
      'subtotal': subtotal,
      'tax_total': taxTotal,
      'total': subtotal + taxTotal,
      'status': 'draft',
      'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'notes': null,
      'created_by': user?.id,
    }).select().single();

    final quoteId = result['id'] as String;

    for (final item in items) {
      final lineTotal = item.unitPrice * item.quantity;
      await supabase.from('quote_items').insert({
        'workspace_id': wsId,
        'quote_id': quoteId,
        'product_id': item.productId.isNotEmpty ? item.productId : null,
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'line_total': lineTotal,
      });
    }

    return QuoteResult(
      quoteNumber: quoteNumber,
      total: subtotal + taxTotal,
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
